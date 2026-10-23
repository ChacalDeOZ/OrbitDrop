import Foundation
import PDFKit
import Vision

public enum PDFTextFormat: String, Sendable {
    case text = "txt"
    case markdown = "md"
}

public enum PDFTextExtractor: Sendable {
    /// Extrai texto de cada página. Páginas escaneadas usam OCR local via Vision automaticamente.
    @discardableResult
    public static func extractText(
        sourceURL: URL,
        format: PDFTextFormat = .text,
        directory: URL? = nil,
        useOCRFallback: Bool = true
    ) throws -> URL {
        guard let doc = PDFDocument(url: sourceURL) else {
            throw PDFEngineError.invalidSource(sourceURL)
        }
        if doc.isLocked {
            throw PDFEngineError.encryptedDocument(sourceURL)
        }

        var pageTexts: [String] = []
        for index in 0..<doc.pageCount {
            guard let page = doc.page(at: index) else { continue }
            let embeddedText = (page.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let content: String

            if !embeddedText.isEmpty || !useOCRFallback {
                content = embeddedText
            } else {
                content = try recognizeTextLocally(on: page)
            }

            switch format {
            case .text:
                pageTexts.append(content)
            case .markdown:
                pageTexts.append("## Página \(index + 1)\n\n\(content)")
            }
        }

        let separator = (format == .markdown) ? "\n\n---\n\n" : "\n\n"
        let finalContent = pageTexts.joined(separator: separator)

        let destinationURL = OutputWriter.destinationURL(
            for: sourceURL,
            targetExtension: format.rawValue,
            directory: directory
        )

        return try OutputWriter.withStagingFile(targetURL: destinationURL) { stagingURL in
            try finalContent.write(to: stagingURL, atomically: true, encoding: .utf8)
        }
    }

    /// OCR local, sem rede. Renderiza uma página em 144 DPI para equilibrar precisão e RAM.
    private static func recognizeTextLocally(on page: PDFPage) throws -> String {
        let pageRect = page.bounds(for: .cropBox)
        let scale: CGFloat = 2.0
        let width = max(1, Int(ceil(pageRect.width * scale)))
        let height = max(1, Int(ceil(pageRect.height * scale)))

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return ""
        }

        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -pageRect.origin.x, y: -pageRect.origin.y)
        page.draw(with: .cropBox, to: context)

        guard let image = context.makeImage() else { return "" }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["pt-BR", "en-US"]

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])

        let observations = request.results ?? []
        let sorted = observations.sorted { lhs, rhs in
            let verticalDelta = abs(lhs.boundingBox.midY - rhs.boundingBox.midY)
            if verticalDelta > 0.02 {
                return lhs.boundingBox.midY > rhs.boundingBox.midY
            }
            return lhs.boundingBox.minX < rhs.boundingBox.minX
        }

        return sorted.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
    }
}
