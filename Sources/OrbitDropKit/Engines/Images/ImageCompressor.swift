import Foundation
import CoreGraphics
import ImageIO

public enum ImageCompressorError: LocalizedError, Sendable {
    case invalidSource(URL)
    case compressionFailed

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível carregar a imagem para compressão: \(url.lastPathComponent)"
        case .compressionFailed:
            return "Falha ao gerar o arquivo comprimido."
        }
    }
}

public enum ImageCompressor: Sendable {
    /// Comprime uma imagem buscando iterativamente aproximar o tamanho do arquivo a targetBytes.
    @discardableResult
    public static func compress(
        sourceURL: URL,
        targetBytes: Int64,
        directory: URL? = nil,
        maxSteps: Int = 5
    ) throws -> URL {
        guard let sourceRef = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              CGImageSourceGetCount(sourceRef) > 0,
              let cgImage = CGImageSourceCreateImageAtIndex(sourceRef, 0, nil) else {
            throw ImageCompressorError.invalidSource(sourceURL)
        }

        let destinationURL = destinationCompressedURL(for: sourceURL, directory: directory)

        return try OutputWriter.withStagingFile(targetURL: destinationURL) { stagingURL in
            var lowQuality: CGFloat = 0.10
            var highQuality: CGFloat = 0.90
            var bestUnderTargetData: Data?
            var smallestData: Data?

            for _ in 0..<maxSteps {
                let mid = (lowQuality + highQuality) / 2.0
                if let data = renderJPEG(image: cgImage, quality: mid) {
                    let size = Int64(data.count)
                    if smallestData == nil || size < Int64(smallestData!.count) {
                        smallestData = data
                    }

                    if size <= targetBytes {
                        bestUnderTargetData = data
                        lowQuality = mid // Tenta refinar mantendo-se sob o teto
                    } else {
                        highQuality = mid // Tamanho excedeu, reduz qualidade
                    }
                }
            }

            var finalCandidate = bestUnderTargetData ?? smallestData

            // Se nenhum candidato ficou abaixo de targetBytes, reduz resolução (downsampling)
            if let data = finalCandidate, Int64(data.count) > targetBytes {
                let scaledWidth = max(16, cgImage.width / 2)
                let scaledHeight = max(16, cgImage.height / 2)
                if let resized = resize(image: cgImage, targetWidth: scaledWidth, targetHeight: scaledHeight),
                   let smallerData = renderJPEG(image: resized, quality: 0.40) {
                    finalCandidate = smallerData
                }
            }

            guard let finalData = finalCandidate else {
                throw ImageCompressorError.compressionFailed
            }

            try finalData.write(to: stagingURL, options: .atomic)
        }
    }

    private static func destinationCompressedURL(for sourceURL: URL, directory: URL?) -> URL {
        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let candidateName = "\(rawBaseName)-compressed.jpg"
        var candidateURL = baseDir.appendingPathComponent(candidateName)

        let fm = FileManager.default
        if !fm.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        var counter = 2
        while true {
            let nextName = "\(rawBaseName)-compressed-\(counter).jpg"
            candidateURL = baseDir.appendingPathComponent(nextName)
            if !fm.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }

    private static func renderJPEG(image: CGImage, quality: CGFloat) -> Data? {
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutableData, "public.jpeg" as CFString, 1, nil) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return mutableData as Data
    }

    private static func resize(image: CGImage, targetWidth: Int, targetHeight: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(
            data: nil,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: 8,
            bytesPerRow: targetWidth * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
        return context.makeImage()
    }
}
