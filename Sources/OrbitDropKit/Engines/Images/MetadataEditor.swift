import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

public enum MetadataEditorError: LocalizedError, Sendable {
    case invalidSource(URL)
    case writeFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível ler imagem para manipulação de metadados: \(url.lastPathComponent)"
        case .writeFailed(let reason):
            return "Falha ao gravar arquivo limpo de metadados: \(reason)"
        }
    }
}

public enum MetadataEditor: Sendable {
    /// Inspeciona e retorna as propriedades e metadados de uma imagem.
    public static func readMetadata(sourceURL: URL) -> [String: Any] {
        guard let sourceRef = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              CGImageSourceGetCount(sourceRef) > 0,
              let properties = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, nil) as? [String: Any] else {
            return [:]
        }
        return properties
    }

    /// Cria uma cópia limpa da imagem removendo 100% dos dados GPS, EXIF e IPTC (preservando multi-frames).
    @discardableResult
    public static func stripAllMetadata(
        sourceURL: URL,
        directory: URL? = nil
    ) throws -> URL {
        guard let sourceRef = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) else {
            throw MetadataEditorError.invalidSource(sourceURL)
        }

        let frameCount = CGImageSourceGetCount(sourceRef)
        guard frameCount > 0 else {
            throw MetadataEditorError.invalidSource(sourceURL)
        }

        let cleanExt = sourceURL.pathExtension.isEmpty ? "jpg" : sourceURL.pathExtension.lowercased()
        let targetType = UTType(filenameExtension: cleanExt) ?? .jpeg
        let destinationURL = destinationCleanURL(for: sourceURL, directory: directory)

        return try OutputWriter.withStagingFile(targetURL: destinationURL) { stagingURL in
            guard let destination = CGImageDestinationCreateWithURL(
                stagingURL as CFURL,
                targetType.identifier as CFString,
                frameCount,
                nil
            ) else {
                throw MetadataEditorError.writeFailed("Não foi possível criar o destino de gravação.")
            }

            // Grava todos os frames sem metadados privados
            let emptyProperties: [CFString: Any] = [:]
            for index in 0..<frameCount {
                if let cgImage = CGImageSourceCreateImageAtIndex(sourceRef, index, nil) {
                    CGImageDestinationAddImage(destination, cgImage, emptyProperties as CFDictionary)
                }
            }

            guard CGImageDestinationFinalize(destination) else {
                throw MetadataEditorError.writeFailed("Falha ao finalizar o arquivo limpo.")
            }
        }
    }

    private static func destinationCleanURL(for sourceURL: URL, directory: URL?) -> URL {
        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension
        let candidateName = ext.isEmpty ? "\(rawBaseName)-clean" : "\(rawBaseName)-clean.\(ext)"
        var candidateURL = baseDir.appendingPathComponent(candidateName)

        let fm = FileManager.default
        if !fm.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        var counter = 2
        while true {
            let nextName = ext.isEmpty ? "\(rawBaseName)-clean-\(counter)" : "\(rawBaseName)-clean-\(counter).\(ext)"
            candidateURL = baseDir.appendingPathComponent(nextName)
            if !fm.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }
}
