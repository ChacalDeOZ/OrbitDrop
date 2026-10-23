import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

public enum CollageError: LocalizedError, Sendable {
    case emptySources
    case invalidSource(URL)
    case contextCreationFailed
    case exportFailed

    public var errorDescription: String? {
        switch self {
        case .emptySources:
            return "Nenhuma imagem informada para criar colagem."
        case .invalidSource(let url):
            return "Não foi possível carregar imagem para colagem: \(url.lastPathComponent)"
        case .contextCreationFailed:
            return "Falha ao criar o canvas para colagem."
        case .exportFailed:
            return "Falha ao gravar a imagem da colagem."
        }
    }
}

public enum ImageCollageBuilder: Sendable {
    /// Combina múltiplas imagens em um único mosaico / colagem.
    @discardableResult
    public static func createCollage(
        sources: [URL],
        directory: URL? = nil
    ) throws -> URL {
        guard !sources.isEmpty else { throw CollageError.emptySources }

        var images: [CGImage] = []
        for url in sources {
            guard let sourceRef = CGImageSourceCreateWithURL(url as CFURL, nil),
                  CGImageSourceGetCount(sourceRef) > 0,
                  let img = CGImageSourceCreateImageAtIndex(sourceRef, 0, nil) else {
                throw CollageError.invalidSource(url)
            }
            images.append(img)
        }

        // Layout horizontal lado a lado simples
        let totalWidth = images.reduce(0) { $0 + $1.width }
        let maxHeight = images.reduce(0) { max($0, $1.height) }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: totalWidth,
            height: maxHeight,
            bitsPerComponent: 8,
            bytesPerRow: totalWidth * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw CollageError.contextCreationFailed
        }

        // Fundo neutro
        context.setFillColor(CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: totalWidth, height: maxHeight))

        var currentX = 0
        for img in images {
            let yOffset = (maxHeight - img.height) / 2
            let rect = CGRect(x: currentX, y: yOffset, width: img.width, height: img.height)
            context.draw(img, in: rect)
            currentX += img.width
        }

        guard let finalImage = context.makeImage() else {
            throw CollageError.exportFailed
        }

        let firstURL = sources[0]
        let destinationURL = destinationCollageURL(for: firstURL, directory: directory)

        return try OutputWriter.withStagingFile(targetURL: destinationURL) { stagingURL in
            guard let destination = CGImageDestinationCreateWithURL(
                stagingURL as CFURL,
                UTType.png.identifier as CFString,
                1,
                nil
            ) else {
                throw CollageError.exportFailed
            }

            CGImageDestinationAddImage(destination, finalImage, nil)
            guard CGImageDestinationFinalize(destination) else {
                throw CollageError.exportFailed
            }
        }
    }

    private static func destinationCollageURL(for sourceURL: URL, directory: URL?) -> URL {
        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let candidateName = "\(rawBaseName)-collage.png"
        var candidateURL = baseDir.appendingPathComponent(candidateName)

        let fm = FileManager.default
        if !fm.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        var counter = 2
        while true {
            let nextName = "\(rawBaseName)-collage-\(counter).png"
            candidateURL = baseDir.appendingPathComponent(nextName)
            if !fm.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }
}
