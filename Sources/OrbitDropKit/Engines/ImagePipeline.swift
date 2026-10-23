import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

public enum ImagePipelineError: LocalizedError, Sendable {
    case sourceNotFound(URL)
    case invalidSourceImage(URL)
    case unsupportedTargetFormat(String)
    case destinationCreationFailed
    case finalizationFailed

    public var errorDescription: String? {
        switch self {
        case .sourceNotFound(let url):
            return "Arquivo de origem não encontrado: \(url.path)"
        case .invalidSourceImage(let url):
            return "O arquivo não pôde ser decodificado como imagem válida: \(url.lastPathComponent)"
        case .unsupportedTargetFormat(let ext):
            return "Formato de destino não suportado: .\(ext)"
        case .destinationCreationFailed:
            return "Não foi possível criar o destino de escrita da imagem."
        case .finalizationFailed:
            return "Falha ao gravar os bytes finais da imagem convertida."
        }
    }
}

public enum ImagePipeline: Sendable {
    /// Converte um arquivo de imagem para outro formato utilizando ImageIO nativo.
    @discardableResult
    public static func convert(
        sourceURL: URL,
        targetExtension: String,
        directory: URL? = nil,
        compressionQuality: CGFloat = 0.85
    ) throws -> URL {
        let fm = FileManager.default
        guard fm.fileExists(atPath: sourceURL.path) else {
            throw ImagePipelineError.sourceNotFound(sourceURL)
        }

        guard let sourceRef = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              CGImageSourceGetCount(sourceRef) > 0,
              let cgImage = CGImageSourceCreateImageAtIndex(sourceRef, 0, nil) else {
            throw ImagePipelineError.invalidSourceImage(sourceURL)
        }

        let cleanExt = targetExtension.trimmingCharacters(in: CharacterSet(charactersIn: ".")).lowercased()
        let targetType: UTType
        switch cleanExt {
        case "jpg", "jpeg":
            targetType = .jpeg
        case "png":
            targetType = .png
        case "tiff", "tif":
            targetType = .tiff
        case "bmp":
            targetType = .bmp
        case "heic":
            targetType = .heic
        default:
            if let resolved = UTType(filenameExtension: cleanExt) {
                targetType = resolved
            } else {
                throw ImagePipelineError.unsupportedTargetFormat(cleanExt)
            }
        }

        let destinationURL = OutputWriter.destinationURL(
            for: sourceURL,
            targetExtension: cleanExt,
            directory: directory
        )

        return try OutputWriter.withStagingFile(targetURL: destinationURL) { stagingURL in
            guard let destination = CGImageDestinationCreateWithURL(
                stagingURL as CFURL,
                targetType.identifier as CFString,
                1,
                nil
            ) else {
                throw ImagePipelineError.destinationCreationFailed
            }

            var options: [CFString: Any] = [:]
            if targetType == .jpeg || targetType == .heic {
                options[kCGImageDestinationLossyCompressionQuality] = compressionQuality
            }

            // Preservar orientação se presente no original
            if let metadata = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, nil) as? [CFString: Any],
               let orientation = metadata[kCGImagePropertyOrientation] {
                options[kCGImagePropertyOrientation] = orientation
            }

            CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)

            guard CGImageDestinationFinalize(destination) else {
                throw ImagePipelineError.finalizationFailed
            }
        }
    }
}
