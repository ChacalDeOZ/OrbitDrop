import Foundation
import CoreGraphics
import ImageIO

public enum ImageToPDFError: LocalizedError, Sendable {
    case emptySources
    case invalidSource(URL)
    case contextCreationFailed
    case exportFailed

    public var errorDescription: String? {
        switch self {
        case .emptySources:
            return "Nenhuma imagem fornecida para criação de PDF."
        case .invalidSource(let url):
            return "Não foi possível carregar imagem para PDF: \(url.lastPathComponent)"
        case .contextCreationFailed:
            return "Não foi possível criar contexto PDF."
        case .exportFailed:
            return "Falha ao finalizar documento PDF."
        }
    }
}

public enum ImageToPDFConverter: Sendable {
    /// Cria um PDF onde cada imagem (ou frame de imagem) representa exatamente uma página,
    /// com streaming sob demanda para evitar estouro de memória em lotes grandes.
    @discardableResult
    public static func createPDF(
        from sources: [URL],
        outputDirectory: URL? = nil
    ) throws -> URL {
        guard !sources.isEmpty else { throw ImageToPDFError.emptySources }

        let baseDir = outputDirectory ?? sources[0].deletingLastPathComponent()
        let finalURL = uniquePDFDestination(in: baseDir, baseName: sources[0].deletingPathExtension().lastPathComponent)

        return try OutputWriter.withStagingFile(targetURL: finalURL) { stagingURL in
            guard let consumer = CGDataConsumer(url: stagingURL as CFURL) else {
                throw ImageToPDFError.contextCreationFailed
            }

            var defaultMediaBox = CGRect(x: 0, y: 0, width: 612, height: 792) // Padrão Letter
            guard let context = CGContext(consumer: consumer, mediaBox: &defaultMediaBox, nil) else {
                throw ImageToPDFError.contextCreationFailed
            }

            for url in sources {
                guard let sourceRef = CGImageSourceCreateWithURL(url as CFURL, nil) else {
                    throw ImageToPDFError.invalidSource(url)
                }

                let count = CGImageSourceGetCount(sourceRef)
                guard count > 0 else { throw ImageToPDFError.invalidSource(url) }

                for index in 0..<count {
                    guard let image = CGImageSourceCreateImageAtIndex(sourceRef, index, nil) else {
                        continue
                    }

                    let orientationVal = (CGImageSourceCopyPropertiesAtIndex(sourceRef, index, nil) as? [CFString: Any])?[kCGImagePropertyOrientation] as? UInt32
                    let isTransposed = (orientationVal == 5 || orientationVal == 6 || orientationVal == 7 || orientationVal == 8)

                    let pageWidth = isTransposed ? CGFloat(image.height) : CGFloat(image.width)
                    let pageHeight = isTransposed ? CGFloat(image.width) : CGFloat(image.height)
                    var pageBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

                    let pageInfo: [CFString: Any] = [
                        kCGPDFContextMediaBox: Data(bytes: &pageBox, count: MemoryLayout<CGRect>.size) as CFData
                    ]

                    context.beginPDFPage(pageInfo as CFDictionary)
                    context.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height)))
                    context.endPDFPage()
                }
            }

            context.closePDF()
        }
    }

    private static func uniquePDFDestination(in directory: URL, baseName: String) -> URL {
        let fm = FileManager.default
        var candidate = directory.appendingPathComponent("\(baseName)-images.pdf")
        if !fm.fileExists(atPath: candidate.path) { return candidate }

        var counter = 2
        while true {
            candidate = directory.appendingPathComponent("\(baseName)-images-\(counter).pdf")
            if !fm.fileExists(atPath: candidate.path) { return candidate }
            counter += 1
        }
    }
}
