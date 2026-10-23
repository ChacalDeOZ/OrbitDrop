import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Vision

public enum ImageRedactorError: LocalizedError, Sendable {
    case invalidSource(URL)
    case contextCreationFailed
    case exportFailed

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível carregar imagem para redação: \(url.lastPathComponent)"
        case .contextCreationFailed:
            return "Falha ao criar contexto seguro de redação."
        case .exportFailed:
            return "Falha ao gravar imagem redigida."
        }
    }
}

public enum ImageRedactor: Sendable {
    /// Detecta faces localmente via Vision e retorna regiões em coordenadas de pixel.
    public static func detectFaceRegions(sourceURL: URL) throws -> [CGRect] {
        guard let sourceRef = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(sourceRef, 0, nil) else {
            throw ImageRedactorError.invalidSource(sourceURL)
        }

        let orientationVal = (CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, nil) as? [CFString: Any])?[kCGImagePropertyOrientation] as? UInt32
        let cgOrientation = CGImagePropertyOrientation(rawValue: orientationVal ?? 1) ?? .up

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: image, orientation: cgOrientation, options: [:])
        try handler.perform([request])

        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        return (request.results ?? []).map { observation in
            let normalized = observation.boundingBox
            return CGRect(
                x: normalized.minX * width,
                y: normalized.minY * height,
                width: normalized.width * width,
                height: normalized.height * height
            )
        }
    }

    /// Queima tarjas pretas opacas diretamente sobre pixels da imagem.
    @discardableResult
    public static func redact(
        sourceURL: URL,
        regions: [CGRect],
        directory: URL? = nil
    ) throws -> URL {
        guard let sourceRef = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              CGImageSourceGetCount(sourceRef) > 0,
              let cgImage = CGImageSourceCreateImageAtIndex(sourceRef, 0, nil) else {
            throw ImageRedactorError.invalidSource(sourceURL)
        }

        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw ImageRedactorError.contextCreationFailed
        }

        // Copia pixels originais
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Queima preto sólido opaco nas regiões aprovadas pelo usuário sem antialiasing para evitar bordas semitransparentes
        context.setAllowsAntialiasing(false)
        context.setShouldAntialias(false)
        context.setBlendMode(.copy)
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        for rect in regions {
            let integralRect = CGRect(
                x: floor(rect.origin.x),
                y: floor(rect.origin.y),
                width: ceil(rect.width),
                height: ceil(rect.height)
            )
            let safeRect = integralRect.intersection(CGRect(x: 0, y: 0, width: width, height: height))
            if !safeRect.isNull && safeRect.width > 0 && safeRect.height > 0 {
                context.fill(safeRect)
            }
        }

        guard let finalImage = context.makeImage() else {
            throw ImageRedactorError.exportFailed
        }

        let destinationURL = destinationRedactedURL(for: sourceURL, directory: directory)

        return try OutputWriter.withStagingFile(targetURL: destinationURL) { stagingURL in
            // PNG garante raster lossless e pixel sólido irreversível
            guard let destination = CGImageDestinationCreateWithURL(
                stagingURL as CFURL,
                UTType.png.identifier as CFString,
                1,
                nil
            ) else {
                throw ImageRedactorError.exportFailed
            }

            CGImageDestinationAddImage(destination, finalImage, nil)
            guard CGImageDestinationFinalize(destination) else {
                throw ImageRedactorError.exportFailed
            }
        }
    }

    private static func destinationRedactedURL(for sourceURL: URL, directory: URL?) -> URL {
        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let candidateName = "\(rawBaseName)-redacted.png"
        var candidateURL = baseDir.appendingPathComponent(candidateName)

        let fm = FileManager.default
        if !fm.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        var counter = 2
        while true {
            let nextName = "\(rawBaseName)-redacted-\(counter).png"
            candidateURL = baseDir.appendingPathComponent(nextName)
            if !fm.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }
}
