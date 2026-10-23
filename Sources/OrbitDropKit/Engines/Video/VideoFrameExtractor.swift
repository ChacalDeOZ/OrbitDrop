import Foundation
import AVFoundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

public enum VideoFrameError: LocalizedError, Sendable {
    case invalidSource(URL)
    case extractionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível carregar vídeo para extrair frames: \(url.lastPathComponent)"
        case .extractionFailed(let reason):
            return "Falha ao extrair frame: \(reason)"
        }
    }
}

public enum VideoFrameExtractor: Sendable {
    /// Extrai um frame em um timestamp específico e grava como imagem PNG lossless.
    @discardableResult
    public static func extractFrame(
        sourceURL: URL,
        atSeconds: Double,
        directory: URL? = nil
    ) async throws -> URL {
        let asset = AVURLAsset(url: sourceURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let cmTime = CMTime(seconds: atSeconds, preferredTimescale: 600)
        let cgImage: CGImage
        do {
            let (image, _) = try await generator.image(at: cmTime)
            cgImage = image
        } catch {
            throw VideoFrameError.extractionFailed(error.localizedDescription)
        }

        let timeFormatted = String(format: "%06.2f", atSeconds).replacingOccurrences(of: ".", with: "-")
        let destinationURL = destinationFrameURL(for: sourceURL, timeTag: timeFormatted, directory: directory)

        return try OutputWriter.withStagingFile(targetURL: destinationURL) { stagingURL in
            guard let destination = CGImageDestinationCreateWithURL(
                stagingURL as CFURL,
                UTType.png.identifier as CFString,
                1,
                nil
            ) else {
                throw VideoFrameError.extractionFailed("Não foi possível criar destino PNG")
            }

            CGImageDestinationAddImage(destination, cgImage, nil)
            guard CGImageDestinationFinalize(destination) else {
                throw VideoFrameError.extractionFailed("Falha ao finalizar arquivo PNG")
            }
        }
    }

    private static func destinationFrameURL(for sourceURL: URL, timeTag: String, directory: URL?) -> URL {
        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let candidateName = "\(rawBaseName)-frame-\(timeTag).png"
        var candidateURL = baseDir.appendingPathComponent(candidateName)

        let fm = FileManager.default
        if !fm.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        var counter = 2
        while true {
            let nextName = "\(rawBaseName)-frame-\(timeTag)-\(counter).png"
            candidateURL = baseDir.appendingPathComponent(nextName)
            if !fm.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }
}
