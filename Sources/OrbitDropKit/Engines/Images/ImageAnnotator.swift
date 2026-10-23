import Foundation
import CoreGraphics
import AppKit
import ImageIO
import UniformTypeIdentifiers

public enum AnnotationItem: Sendable {
    case rectangle(rect: CGRect, strokeColor: CGColor, lineWidth: CGFloat)
    case text(String, at: CGPoint, color: CGColor)
    case arrow(from: CGPoint, to: CGPoint, color: CGColor, lineWidth: CGFloat)
}

public enum ImageAnnotatorError: LocalizedError, Sendable {
    case invalidSource(URL)
    case renderFailed

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível carregar a imagem para anotações: \(url.lastPathComponent)"
        case .renderFailed:
            return "Falha ao rasterizar as anotações sobre a imagem."
        }
    }
}

public enum ImageAnnotator: Sendable {
    /// Rasteriza anotações (formas, textos, setas) diretamente sobre os pixels da imagem.
    @discardableResult
    public static func annotate(
        sourceURL: URL,
        annotations: [AnnotationItem],
        directory: URL? = nil
    ) throws -> URL {
        guard let sourceRef = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              CGImageSourceGetCount(sourceRef) > 0,
              let cgImage = CGImageSourceCreateImageAtIndex(sourceRef, 0, nil) else {
            throw ImageAnnotatorError.invalidSource(sourceURL)
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
            throw ImageAnnotatorError.renderFailed
        }

        // Desenha imagem original
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Desenha cada anotação
        for item in annotations {
            switch item {
            case .rectangle(let rect, let strokeColor, let lineWidth):
                context.saveGState()
                context.setStrokeColor(strokeColor)
                context.setLineWidth(lineWidth)
                context.stroke(rect)
                context.restoreGState()

            case .text(let str, let point, let color):
                context.saveGState()
                let nsColor = NSColor(cgColor: color) ?? .white
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 14, weight: .bold),
                    .foregroundColor: nsColor
                ]
                let nsStr = str as NSString
                // Renderização de texto no contexto AppKit
                NSGraphicsContext.saveGraphicsState()
                let gContext = NSGraphicsContext(cgContext: context, flipped: false)
                NSGraphicsContext.current = gContext
                nsStr.draw(at: point, withAttributes: attrs)
                NSGraphicsContext.restoreGraphicsState()
                context.restoreGState()

            case .arrow(let from, let to, let color, let lineWidth):
                context.saveGState()
                context.setStrokeColor(color)
                context.setFillColor(color)
                context.setLineWidth(lineWidth)
                context.move(to: from)
                context.addLine(to: to)
                context.strokePath()

                // Desenha a ponta da seta no ponto de destino
                let angle = atan2(to.y - from.y, to.x - from.x)
                let arrowLength: CGFloat = max(12, lineWidth * 4)
                let arrowAngle: CGFloat = .pi / 6 // 30 graus

                let p1 = CGPoint(
                    x: to.x - arrowLength * cos(angle - arrowAngle),
                    y: to.y - arrowLength * sin(angle - arrowAngle)
                )
                let p2 = CGPoint(
                    x: to.x - arrowLength * cos(angle + arrowAngle),
                    y: to.y - arrowLength * sin(angle + arrowAngle)
                )

                let arrowPath = CGMutablePath()
                arrowPath.move(to: to)
                arrowPath.addLine(to: p1)
                arrowPath.addLine(to: p2)
                arrowPath.closeSubpath()
                context.addPath(arrowPath)
                context.fillPath()
                context.restoreGState()
            }
        }

        guard let annotatedImage = context.makeImage() else {
            throw ImageAnnotatorError.renderFailed
        }

        let destinationURL = destinationAnnotatedURL(for: sourceURL, directory: directory)

        return try OutputWriter.withStagingFile(targetURL: destinationURL) { stagingURL in
            let cleanExt = sourceURL.pathExtension.isEmpty ? "png" : sourceURL.pathExtension.lowercased()
            let targetType = UTType(filenameExtension: cleanExt) ?? .png

            guard let destination = CGImageDestinationCreateWithURL(
                stagingURL as CFURL,
                targetType.identifier as CFString,
                1,
                nil
            ) else {
                throw ImageAnnotatorError.renderFailed
            }

            CGImageDestinationAddImage(destination, annotatedImage, nil)
            guard CGImageDestinationFinalize(destination) else {
                throw ImageAnnotatorError.renderFailed
            }
        }
    }

    private static func destinationAnnotatedURL(for sourceURL: URL, directory: URL?) -> URL {
        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension
        let candidateName = ext.isEmpty ? "\(rawBaseName)-annotated" : "\(rawBaseName)-annotated.\(ext)"
        var candidateURL = baseDir.appendingPathComponent(candidateName)

        let fm = FileManager.default
        if !fm.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        var counter = 2
        while true {
            let nextName = ext.isEmpty ? "\(rawBaseName)-annotated-\(counter)" : "\(rawBaseName)-annotated-\(counter).\(ext)"
            candidateURL = baseDir.appendingPathComponent(nextName)
            if !fm.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }
}
