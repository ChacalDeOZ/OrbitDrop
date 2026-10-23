import Foundation
import PDFKit

public enum PDFSplitter: Sendable {
    /// Divide um arquivo PDF extraindo cada página como um documento independente.
    @discardableResult
    public static func split(
        sourceURL: URL,
        directory: URL? = nil
    ) throws -> [URL] {
        guard let doc = PDFDocument(url: sourceURL) else {
            throw PDFEngineError.invalidSource(sourceURL)
        }
        if doc.isLocked {
            throw PDFEngineError.encryptedDocument(sourceURL)
        }

        let pageCount = doc.pageCount
        guard pageCount > 0 else { return [] }

        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let fm = FileManager.default
        var outputURLs: [URL] = []

        for p in 0..<pageCount {
            guard let page = doc.page(at: p) else { continue }
            let singleDoc = PDFDocument()
            singleDoc.insert(page, at: 0)

            let pageNum = String(format: "%03d", p + 1)
            let candidateName = "\(rawBaseName)-page-\(pageNum).pdf"
            var targetURL = baseDir.appendingPathComponent(candidateName)
            if fm.fileExists(atPath: targetURL.path) {
                var counter = 2
                while true {
                    let nextCandidate = "\(rawBaseName)-page-\(pageNum)-\(counter).pdf"
                    let nextURL = baseDir.appendingPathComponent(nextCandidate)
                    if !fm.fileExists(atPath: nextURL.path) {
                        targetURL = nextURL
                        break
                    }
                    counter += 1
                }
            }

            let finalURL = try OutputWriter.withStagingFile(targetURL: targetURL) { stagingURL in
                guard singleDoc.write(to: stagingURL) else {
                    throw PDFEngineError.writeFailed("Falha ao salvar página \(pageNum)")
                }
            }
            outputURLs.append(finalURL)
        }

        return outputURLs
    }
}
