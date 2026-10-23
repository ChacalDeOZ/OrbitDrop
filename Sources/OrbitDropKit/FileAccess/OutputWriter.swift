import Foundation

public enum OutputWriterError: LocalizedError, Sendable {
    case stagingFileMissing
    case failedToMove(String)

    public var errorDescription: String? {
        switch self {
        case .stagingFileMissing:
            return "O arquivo temporário de trabalho não foi gerado."
        case .failedToMove(let reason):
            return "Falha ao promover arquivo para o destino final: \(reason)"
        }
    }
}

public enum OutputWriter: Sendable {
    /// Determina a URL de destino com convenção `-converted`, resolvendo colisões com `-2`, `-3`, etc.
    public static func destinationURL(
        for sourceURL: URL,
        targetExtension: String,
        directory: URL? = nil
    ) -> URL {
        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = targetExtension.trimmingCharacters(in: CharacterSet(charactersIn: "."))

        let fm = FileManager.default
        let firstCandidateName = "\(rawBaseName)-converted.\(ext)"
        var candidateURL = baseDir.appendingPathComponent(firstCandidateName)

        if !fm.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        var counter = 2
        while true {
            let nextName = "\(rawBaseName)-converted-\(counter).\(ext)"
            candidateURL = baseDir.appendingPathComponent(nextName)
            if !fm.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }

    /// Executa o trabalho de escrita em arquivo temporário seguro e promove atomicamente para o destino final.
    @discardableResult
    public static func withStagingFile(
        targetURL: URL,
        block: (URL) throws -> Void
    ) throws -> URL {
        let parentDir = targetURL.deletingLastPathComponent()
        let fm = FileManager.default

        // Garante que o diretório pai existe
        if !fm.fileExists(atPath: parentDir.path) {
            try fm.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        let stagingName = ".orbitdrop_staging_\(UUID().uuidString).\(targetURL.pathExtension)"
        let stagingURL = parentDir.appendingPathComponent(stagingName)

        defer {
            if fm.fileExists(atPath: stagingURL.path) {
                try? fm.removeItem(at: stagingURL)
            }
        }

        try block(stagingURL)

        guard fm.fileExists(atPath: stagingURL.path) else {
            throw OutputWriterError.stagingFileMissing
        }

        do {
            try fm.moveItem(at: stagingURL, to: targetURL)
        } catch {
            throw OutputWriterError.failedToMove(error.localizedDescription)
        }

        return targetURL
    }

    /// Versão assíncrona para operações de renderização e exportação de mídia (AVAssetExportSession).
    @discardableResult
    public static func withStagingFileAsync(
        targetURL: URL,
        block: (URL) async throws -> Void
    ) async throws -> URL {
        let parentDir = targetURL.deletingLastPathComponent()
        let fm = FileManager.default

        if !fm.fileExists(atPath: parentDir.path) {
            try fm.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        let stagingName = ".orbitdrop_staging_\(UUID().uuidString).\(targetURL.pathExtension)"
        let stagingURL = parentDir.appendingPathComponent(stagingName)

        defer {
            if fm.fileExists(atPath: stagingURL.path) {
                try? fm.removeItem(at: stagingURL)
            }
        }

        try await block(stagingURL)

        guard fm.fileExists(atPath: stagingURL.path) else {
            throw OutputWriterError.stagingFileMissing
        }

        do {
            try fm.moveItem(at: stagingURL, to: targetURL)
        } catch {
            throw OutputWriterError.failedToMove(error.localizedDescription)
        }

        return targetURL
    }
}
