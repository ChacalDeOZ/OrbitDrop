import Foundation
import PDFKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

public enum PDFRasterFormat: String, Sendable {
    case png
    case jpeg
}

public enum PDFRasterizer: Sendable {
    /// Renderiza cada página do PDF em imagem bitmap a uma resolução nominal (padrão 300 DPI).
    @discardableResult
    public static func renderPages(
        sourceURL: URL,
        dpi: CGFloat = 300.0,
        format: PDFRasterFormat = .png,
        directory: URL? = nil
    ) throws -> [URL] {
        guard let doc = PDFDocument(url: sourceURL) else {
            throw PDFEngineError.invalidSource(sourceURL)
        }
        if doc.isLocked {
            throw PDFEngineError.encryptedDocument(sourceURL)
        }

        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let scale = dpi / 72.0
        var outputs: [URL] = []

        for index in 0..<doc.pageCount {
            autoreleasepool {
                guard let page = doc.page(at: index) else { return }
                let pageRect = page.bounds(for: .cropBox)
                let rotation = page.rotation
                let isTransposed = (rotation == 90 || rotation == 270)

                let pixelWidth = max(1, Int(round((isTransposed ? pageRect.height : pageRect.width) * scale)))
                let pixelHeight = max(1, Int(round((isTransposed ? pageRect.width : pageRect.height) * scale)))

                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
                guard let context = CGContext(
                    data: nil,
                    width: pixelWidth,
                    height: pixelHeight,
                    bitsPerComponent: 8,
                    bytesPerRow: pixelWidth * 4,
                    space: colorSpace,
                    bitmapInfo: bitmapInfo
                ) else { return }

                context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
                context.fill(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
                context.scaleBy(x: scale, y: scale)

                // Aplica a matriz de transformação nativa do PDFKit respeitando a rotação da página
                let transform = page.transform(for: .cropBox)
                context.concatenate(transform)
                page.draw(with: .cropBox, to: context)

                guard let image = context.makeImage() else { return }
                let pageNumber = String(format: "%03d", index + 1)
                let ext = (format == .png) ? "png" : "jpg"
                let targetURL = baseDir.appendingPathComponent("\(rawBaseName)-page-\(pageNumber).\(ext)")

                do {
                    let finalURL = try OutputWriter.withStagingFile(targetURL: targetURL) { stagingURL in
                        let targetType = (format == .png) ? UTType.png : UTType.jpeg
                        guard let destination = CGImageDestinationCreateWithURL(
                            stagingURL as CFURL,
                            targetType.identifier as CFString,
                            1,
                            nil
                        ) else {
                            throw PDFEngineError.writeFailed("Falha ao criar destino de imagem")
                        }

                        var properties: [CFString: Any] = [
                            kCGImagePropertyDPIWidth: dpi,
                            kCGImagePropertyDPIHeight: dpi
                        ]
                        if format == .jpeg {
                            properties[kCGImageDestinationLossyCompressionQuality] = 0.90
                        }

                        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
                        guard CGImageDestinationFinalize(destination) else {
                            throw PDFEngineError.writeFailed("Falha ao finalizar imagem")
                        }
                    }
                    outputs.append(finalURL)
                } catch {
                    return
                }
            }
        }

        return outputs
    }
}
