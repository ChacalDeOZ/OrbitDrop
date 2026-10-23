import Foundation

public enum MoveActionError: LocalizedError, Sendable {
    case sourceNotFound(URL)
    case destinationNotDirectory(URL)
    case moveFailed(String)

    public var errorDescription: String? {
        switch self {
        case .sourceNotFound(let url):
            return "Arquivo de origem para mover não existe: \(url.path)"
        case .destinationNotDirectory(let url):
            return "Destino não é um diretório válido: \(url.path)"
        case .moveFailed(let reason):
            return "Falha ao mover arquivo: \(reason)"
        }
    }
}

public enum MoveAction: Sendable {
    /// Move arquivos de forma segura para uma pasta de destino, resolvendo colisões com -2, -3.
    @discardableResult
    public static func move(files: [URL], to destinationDirectory: URL) throws -> [URL] {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: destinationDirectory.path, isDirectory: &isDir), isDir.boolValue else {
            throw MoveActionError.destinationNotDirectory(destinationDirectory)
        }

        var movedURLs: [URL] = []

        for file in files {
            guard fm.fileExists(atPath: file.path) else {
                throw MoveActionError.sourceNotFound(file)
            }

            let resolvedDest = resolveUniqueDestination(for: file, in: destinationDirectory)
            do {
                try fm.moveItem(at: file, to: resolvedDest)
                movedURLs.append(resolvedDest)
            } catch {
                throw MoveActionError.moveFailed(error.localizedDescription)
            }
        }

        return movedURLs
    }

    private static func resolveUniqueDestination(for sourceURL: URL, in destinationDirectory: URL) -> URL {
        let fm = FileManager.default
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension

        let directCandidate = destinationDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        if !fm.fileExists(atPath: directCandidate.path) {
            return directCandidate
        }

        var counter = 2
        while true {
            let nextName: String
            if ext.isEmpty {
                nextName = "\(baseName)-\(counter)"
            } else {
                nextName = "\(baseName)-\(counter).\(ext)"
            }
            let candidate = destinationDirectory.appendingPathComponent(nextName)
            if !fm.fileExists(atPath: candidate.path) {
                return candidate
            }
            counter += 1
        }
    }
}
