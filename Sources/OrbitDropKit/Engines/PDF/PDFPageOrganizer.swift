import Foundation
import PDFKit

public enum PDFPageAction: Sendable {
    case rotate(pageIndex: Int, degrees: Int)
    case delete(pageIndex: Int)
    case move(fromIndex: Int, toIndex: Int)
    case duplicate(pageIndex: Int)
}

public enum PDFPageOrganizer: Sendable {
    /// Aplica rotações, exclusões, reordenações e duplicações em páginas de um PDF.
    @discardableResult
    public static func reorganize(
        sourceURL: URL,
        actions: [PDFPageAction],
        directory: URL? = nil
    ) throws -> URL {
        guard let doc = PDFDocument(url: sourceURL) else {
            throw PDFEngineError.invalidSource(sourceURL)
        }
        if doc.isLocked {
            throw PDFEngineError.encryptedDocument(sourceURL)
        }

        for action in actions {
            switch action {
            case .rotate(let pageIndex, let degrees):
                guard pageIndex >= 0 && pageIndex < doc.pageCount,
                      let page = doc.page(at: pageIndex) else { continue }
                // Normalizar rotação em múltiplos de 90 dentro de 0...359
                let normalized = ((page.rotation + degrees) % 360 + 360) % 360
                page.rotation = normalized

            case .delete(let pageIndex):
                guard pageIndex >= 0 && pageIndex < doc.pageCount else { continue }
                doc.removePage(at: pageIndex)

            case .move(let fromIndex, let toIndex):
                guard fromIndex >= 0, fromIndex < doc.pageCount,
                      toIndex >= 0, toIndex <= doc.pageCount,
                      let page = doc.page(at: fromIndex) else { continue }
                doc.removePage(at: fromIndex)
                let adjustedTarget = (fromIndex < toIndex) ? min(toIndex, doc.pageCount) : toIndex
                doc.insert(page, at: adjustedTarget)

            case .duplicate(let pageIndex):
                guard pageIndex >= 0 && pageIndex < doc.pageCount,
                      let page = doc.page(at: pageIndex),
                      let copiedPage = page.copy() as? PDFPage else { continue }
                doc.insert(copiedPage, at: min(pageIndex + 1, doc.pageCount))
            }
        }

        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let destinationURL = uniqueOrganizedURL(in: baseDir, baseName: rawBaseName)

        return try OutputWriter.withStagingFile(targetURL: destinationURL) { stagingURL in
            guard doc.write(to: stagingURL) else {
                throw PDFEngineError.writeFailed("Falha ao salvar PDF organizado")
            }
        }
    }

    private static func uniqueOrganizedURL(in directory: URL, baseName: String) -> URL {
        let fm = FileManager.default
        var candidate = directory.appendingPathComponent("\(baseName)-organized.pdf")
        if !fm.fileExists(atPath: candidate.path) { return candidate }

        var counter = 2
        while true {
            candidate = directory.appendingPathComponent("\(baseName)-organized-\(counter).pdf")
            if !fm.fileExists(atPath: candidate.path) { return candidate }
            counter += 1
        }
    }
}
