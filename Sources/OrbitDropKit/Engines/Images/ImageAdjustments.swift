import Foundation
import CoreGraphics
import CoreImage
import ImageIO
import UniformTypeIdentifiers

public enum ImageAdjustmentsError: LocalizedError, Sendable {
    case invalidSource(URL)
    case renderingFailed

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível carregar a imagem para ajustes: \(url.lastPathComponent)"
        case .renderingFailed:
            return "Falha ao processar os filtros de ajuste de imagem."
        }
    }
}

public enum ImageAdjustments: Sendable {
    /// Aplica ajustes de contraste, brilho, saturação e exposição via CoreImage.
    @discardableResult
    public static func apply(
        sourceURL: URL,
        contrast: Float = 1.0,
        brightness: Float = 0.0,
        saturation: Float = 1.0,
        directory: URL? = nil
    ) throws -> URL {
        guard let ciImage = CIImage(contentsOf: sourceURL, options: [.applyOrientationProperty: true]) else {
            throw ImageAdjustmentsError.invalidSource(sourceURL)
        }

        let context = CIContext(options: nil)

        // Filtro ColorControls
        let parameters: [String: Any] = [
            kCIInputImageKey: ciImage,
            kCIInputContrastKey: contrast,
            kCIInputBrightnessKey: brightness,
            kCIInputSaturationKey: saturation
        ]

        guard let filter = CIFilter(name: "CIColorControls", parameters: parameters),
              let outputCIImage = filter.outputImage,
              let cgImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {
            throw ImageAdjustmentsError.renderingFailed
        }

        let destinationURL = destinationAdjustedURL(for: sourceURL, directory: directory)

        return try OutputWriter.withStagingFile(targetURL: destinationURL) { stagingURL in
            let cleanExt = sourceURL.pathExtension.isEmpty ? "jpg" : sourceURL.pathExtension.lowercased()
            let targetType = UTType(filenameExtension: cleanExt) ?? .png

            guard let destination = CGImageDestinationCreateWithURL(
                stagingURL as CFURL,
                targetType.identifier as CFString,
                1,
                nil
            ) else {
                throw ImageAdjustmentsError.renderingFailed
            }

            CGImageDestinationAddImage(destination, cgImage, nil)
            guard CGImageDestinationFinalize(destination) else {
                throw ImageAdjustmentsError.renderingFailed
            }
        }
    }

    private static func destinationAdjustedURL(for sourceURL: URL, directory: URL?) -> URL {
        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension
        let candidateName = ext.isEmpty ? "\(rawBaseName)-adjusted" : "\(rawBaseName)-adjusted.\(ext)"
        var candidateURL = baseDir.appendingPathComponent(candidateName)

        let fm = FileManager.default
        if !fm.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        var counter = 2
        while true {
            let nextName = ext.isEmpty ? "\(rawBaseName)-adjusted-\(counter)" : "\(rawBaseName)-adjusted-\(counter).\(ext)"
            candidateURL = baseDir.appendingPathComponent(nextName)
            if !fm.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }
}
