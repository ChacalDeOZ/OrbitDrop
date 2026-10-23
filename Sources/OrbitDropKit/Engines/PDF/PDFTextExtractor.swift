import Foundation
import PDFKit

public enum PDFTextFormat: String, Sendable {
    case text = "txt"
    case markdown = "md"
}

public enum PDFTextExtractor: Sendable {
    /// Extrai texto de cada página de PDF para TXT ou Markdown estruturado.
    @discardableResult
    public static func extractText(
        sourceURL: URL,
        format: PDFTextFormat = .text,
        directory: URL? = nil
    ) throws -> URL {
        guard let doc = PDFDocument(url: sourceURL) else {
            throw PDFEngineError.invalidSource(sourceURL)
        }
        if doc.isLocked {
            throw PDFEngineError.encryptedDocument(sourceURL)
        }

        var pageTexts: [String] = []
        for index in 0..<doc.pageCount {
            let content = doc.page(at: index)?.string ?? ""
            switch format {
            case .text:
                pageTexts.append(content)
            case .markdown:
                pageTexts.append("## Página \(index + 1)\n\n\(content)")
            }
        }

        let separator = (format == .markdown) ? "\n\n---\n\n" : "\n\n"
        let finalContent = pageTexts.joined(separator: separator)

        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let targetURL = baseDir.appendingPathComponent("\(rawBaseName)-text.\(format.rawValue)")

        return try OutputWriter.withStagingFile(targetURL: targetURL) { stagingURL in
            try finalContent.write(to: stagingURL, atomically: true, encoding: .utf8)
        }
    }
}
