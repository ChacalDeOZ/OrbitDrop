import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

public enum ImageCropperError: LocalizedError, Sendable {
    case invalidSource(URL)
    case cropFailed

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível carregar a imagem para corte: \(url.lastPathComponent)"
        case .cropFailed:
            return "Falha ao aplicar corte na imagem."
        }
    }
}

public enum ImageCropper: Sendable {
    /// Corta a imagem nas coordenadas de retângulo especificadas.
    @discardableResult
    public static func crop(
        sourceURL: URL,
        cropRect: CGRect,
        directory: URL? = nil
    ) throws -> URL {
        guard let sourceRef = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              CGImageSourceGetCount(sourceRef) > 0,
              let cgImage = CGImageSourceCreateImageAtIndex(sourceRef, 0, nil) else {
            throw ImageCropperError.invalidSource(sourceURL)
        }

        // Garante que o rect esteja dentro dos limites da imagem
        let imageRect = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        let safeRect = cropRect.intersection(imageRect)

        guard !safeRect.isNull, safeRect.width > 0, safeRect.height > 0,
              let croppedImage = cgImage.cropping(to: safeRect) else {
            throw ImageCropperError.cropFailed
        }

        let destinationURL = destinationCroppedURL(for: sourceURL, directory: directory)

        return try OutputWriter.withStagingFile(targetURL: destinationURL) { stagingURL in
            let cleanExt = sourceURL.pathExtension.isEmpty ? "png" : sourceURL.pathExtension.lowercased()
            let targetType = UTType(filenameExtension: cleanExt) ?? .png

            guard let destination = CGImageDestinationCreateWithURL(
                stagingURL as CFURL,
                targetType.identifier as CFString,
                1,
                nil
            ) else {
                throw ImageCropperError.cropFailed
            }

            CGImageDestinationAddImage(destination, croppedImage, nil)
            guard CGImageDestinationFinalize(destination) else {
                throw ImageCropperError.cropFailed
            }
        }
    }

    private static func destinationCroppedURL(for sourceURL: URL, directory: URL?) -> URL {
        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension
        let candidateName = ext.isEmpty ? "\(rawBaseName)-cropped" : "\(rawBaseName)-cropped.\(ext)"
        var candidateURL = baseDir.appendingPathComponent(candidateName)

        let fm = FileManager.default
        if !fm.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        var counter = 2
        while true {
            let nextName = ext.isEmpty ? "\(rawBaseName)-cropped-\(counter)" : "\(rawBaseName)-cropped-\(counter).\(ext)"
            candidateURL = baseDir.appendingPathComponent(nextName)
            if !fm.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }
}
