import Foundation

public enum ArchiveError: LocalizedError, Sendable {
    case emptySources
    case invalidSource(URL)
    case unsafePathDetected(String)
    case quotaExceeded(String)
    case compressionFailed(String)
    case extractionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .emptySources:
            return "Nenhum arquivo ou pasta fornecido para compactação."
        case .invalidSource(let url):
            return "Origem inválida para arquivo compactado: \(url.lastPathComponent)"
        case .unsafePathDetected(let path):
            return "Bloqueio de segurança: caminho potencialmente malicioso detectado (\(path))."
        case .quotaExceeded(let reason):
            return "Bloqueio de segurança: cota de descompressão excedida (\(reason))."
        case .compressionFailed(let reason):
            return "Falha na compactação: \(reason)"
        case .extractionFailed(let reason):
            return "Falha na descompactação: \(reason)"
        }
    }
}

public enum ArchiveProcessor: Sendable {
    public static let maxUncompressedBytes: Int64 = 1_073_741_824 // 1 GB quota
    public static let maxFileCount = 50_000

    /// Validação estrita de segurança contra Path Traversal (../, caminhos absolutos, symlinks perigosos).
    public static func isPathSafe(relativePath: String) -> Bool {
        if relativePath.hasPrefix("/") { return false }
        let components = relativePath.components(separatedBy: "/")
        if components.contains("..") { return false }
        if relativePath.contains("\\") { return false }
        return true
    }

    /// Cria um arquivo ZIP de arquivos ou pastas usando /usr/bin/ditto seguro nativo do macOS.
    @discardableResult
    public static func createZIP(
        sources: [URL],
        directory: URL? = nil
    ) throws -> URL {
        guard !sources.isEmpty else { throw ArchiveError.emptySources }

        let firstURL = sources[0]
        let baseDir = directory ?? firstURL.deletingLastPathComponent()
        let rawBaseName = firstURL.deletingPathExtension().lastPathComponent
        let destinationURL = destinationArchiveURL(in: baseDir, baseName: rawBaseName, ext: "zip")

        return try OutputWriter.withStagingFile(targetURL: destinationURL) { stagingURL in
            let stagingDir = FileManager.default.temporaryDirectory.appendingPathComponent("orbitdrop_staging_zip_\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: stagingDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: stagingDir) }

            // Copia todos os sources para a pasta temporária de montagem
            for source in sources {
                let dst = stagingDir.appendingPathComponent(source.lastPathComponent)
                try FileManager.default.copyItem(at: source, to: dst)
            }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            process.arguments = ["-c", "-k", "--sequesterRsrc", "--keepParent", stagingDir.path, stagingURL.path]

            let errorPipe = Pipe()
            process.standardError = errorPipe

            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errMsg = String(data: errData, encoding: .utf8) ?? "Erro ditto desconhecido"
                throw ArchiveError.compressionFailed(errMsg)
            }
        }
    }

    /// Extrai um arquivo ZIP validando quotas de descompressão e bloqueando path traversal e symlinks escapados.
    public static func extract(
        archiveURL: URL,
        destinationDirectory: URL
    ) throws {
        let fm = FileManager.default
        guard fm.fileExists(atPath: archiveURL.path) else {
            throw ArchiveError.invalidSource(archiveURL)
        }

        if !fm.fileExists(atPath: destinationDirectory.path) {
            try fm.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        }

        let tempExtractionDir = fm.temporaryDirectory.appendingPathComponent("orbitdrop_unzip_\(UUID().uuidString)")
        try fm.createDirectory(at: tempExtractionDir, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: tempExtractionDir) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-x", "-k", archiveURL.path, tempExtractionDir.path]

        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errMsg = String(data: errData, encoding: .utf8) ?? "Erro de descompressão ditto"
            throw ArchiveError.extractionFailed(errMsg)
        }

        // Auditoria recursiva de segurança e quota antes de copiar para o destino
        guard let enumerator = fm.enumerator(at: tempExtractionDir, includingPropertiesForKeys: [.fileSizeKey, .isSymbolicLinkKey, .isDirectoryKey]) else {
            throw ArchiveError.extractionFailed("Falha ao inspecionar arquivos descompactados")
        }

        var totalExtractedBytes: Int64 = 0
        var totalExtractedFiles = 0

        for case let fileURL as URL in enumerator {
            totalExtractedFiles += 1
            if totalExtractedFiles > maxFileCount {
                throw ArchiveError.quotaExceeded("Arquivo contém mais de \(maxFileCount) itens (possível zip bomb)")
            }

            let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isSymbolicLinkKey, .isDirectoryKey])
            if let size = resourceValues.fileSize {
                totalExtractedBytes += Int64(size)
                if totalExtractedBytes > maxUncompressedBytes {
                    throw ArchiveError.quotaExceeded("Tamanho descompactado excede limite de 1 GB")
                }
            }

            let baseResolved = tempExtractionDir.resolvingSymlinksInPath().path
            let fileResolved = fileURL.resolvingSymlinksInPath().path
            let relativePath: String
            if fileResolved.hasPrefix(baseResolved) {
                relativePath = String(fileResolved.dropFirst(baseResolved.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            } else {
                relativePath = fileURL.lastPathComponent
            }

            guard isPathSafe(relativePath: relativePath) else {
                throw ArchiveError.unsafePathDetected(relativePath)
            }

            // Validar que o symlink não aponta para fora do destino
            if resourceValues.isSymbolicLink == true {
                let resolvedTarget = fileURL.resolvingSymlinksInPath()
                if !resolvedTarget.path.hasPrefix(baseResolved) {
                    throw ArchiveError.unsafePathDetected("Symlink escapa da raiz: \(relativePath)")
                }
            }
        }

        // Copia itens validados para o destino final
        let items = try fm.contentsOfDirectory(atPath: tempExtractionDir.path)
        for item in items {
            let src = tempExtractionDir.appendingPathComponent(item)
            let dst = destinationDirectory.appendingPathComponent(item)
            if fm.fileExists(atPath: dst.path) {
                try? fm.removeItem(at: dst)
            }
            try fm.moveItem(at: src, to: dst)
        }
    }

    private static func destinationArchiveURL(in directory: URL, baseName: String, ext: String) -> URL {
        let fm = FileManager.default
        var candidate = directory.appendingPathComponent("\(baseName).\(ext)")
        if !fm.fileExists(atPath: candidate.path) { return candidate }

        var counter = 2
        while true {
            candidate = directory.appendingPathComponent("\(baseName)-\(counter).\(ext)")
            if !fm.fileExists(atPath: candidate.path) { return candidate }
            counter += 1
        }
    }
}
