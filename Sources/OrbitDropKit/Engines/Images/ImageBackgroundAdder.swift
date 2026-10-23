import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

public enum ImageBackgroundError: LocalizedError, Sendable {
    case invalidSource(URL)
    case contextCreationFailed
    case exportFailed

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível carregar a imagem para adicionar fundo: \(url.lastPathComponent)"
        case .contextCreationFailed:
            return "Falha ao criar o contexto gráfico de expansão de tela."
        case .exportFailed:
            return "Falha ao gravar a imagem final com fundo."
        }
    }
}

public enum ImageBackgroundAdder: Sendable {
    /// Adiciona margem, cor de fundo e cantos arredondados ao redor de uma imagem.
    @discardableResult
    public static func addBackground(
        sourceURL: URL,
        padding: CGFloat = 24.0,
        backgroundColor: CGColor = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
        cornerRadius: CGFloat = 0.0,
        directory: URL? = nil
    ) throws -> URL {
        guard let sourceRef = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              CGImageSourceGetCount(sourceRef) > 0,
              let cgImage = CGImageSourceCreateImageAtIndex(sourceRef, 0, nil) else {
            throw ImageBackgroundError.invalidSource(sourceURL)
        }

        let newWidth = Int(CGFloat(cgImage.width) + (padding * 2.0))
        let newHeight = Int(CGFloat(cgImage.height) + (padding * 2.0))

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: 8,
            bytesPerRow: newWidth * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw ImageBackgroundError.contextCreationFailed
        }

        // 1. Desenhar o fundo colorido
        context.setFillColor(backgroundColor)
        context.fill(CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

        // 2. Desenhar a imagem centralizada
        let imageRect = CGRect(
            x: padding,
            y: padding,
            width: CGFloat(cgImage.width),
            height: CGFloat(cgImage.height)
        )

        if cornerRadius > 0 {
            context.saveGState()
            let clipPath = CGPath(roundedRect: imageRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
            context.addPath(clipPath)
            context.clip()
            context.draw(cgImage, in: imageRect)
            context.restoreGState()
        } else {
            context.draw(cgImage, in: imageRect)
        }

        guard let finalImage = context.makeImage() else {
            throw ImageBackgroundError.exportFailed
        }

        let destinationURL = destinationBackgroundURL(for: sourceURL, directory: directory)

        return try OutputWriter.withStagingFile(targetURL: destinationURL) { stagingURL in
            let cleanExt = sourceURL.pathExtension.isEmpty ? "png" : sourceURL.pathExtension.lowercased()
            let targetType = UTType(filenameExtension: cleanExt) ?? .png

            guard let destination = CGImageDestinationCreateWithURL(
                stagingURL as CFURL,
                targetType.identifier as CFString,
                1,
                nil
            ) else {
                throw ImageBackgroundError.exportFailed
            }

            CGImageDestinationAddImage(destination, finalImage, nil)
            guard CGImageDestinationFinalize(destination) else {
                throw ImageBackgroundError.exportFailed
            }
        }
    }

    private static func destinationBackgroundURL(for sourceURL: URL, directory: URL?) -> URL {
        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension
        let candidateName = ext.isEmpty ? "\(rawBaseName)-background" : "\(rawBaseName)-background.\(ext)"
        var candidateURL = baseDir.appendingPathComponent(candidateName)

        let fm = FileManager.default
        if !fm.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        var counter = 2
        while true {
            let nextName = ext.isEmpty ? "\(rawBaseName)-background-\(counter)" : "\(rawBaseName)-background-\(counter).\(ext)"
            candidateURL = baseDir.appendingPathComponent(nextName)
            if !fm.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }
}
