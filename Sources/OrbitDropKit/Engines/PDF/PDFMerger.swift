import Foundation
import PDFKit

public enum PDFEngineError: LocalizedError, Sendable {
    case emptySources
    case invalidSource(URL)
    case encryptedDocument(URL)
    case writeFailed(String)

    public var errorDescription: String? {
        switch self {
        case .emptySources:
            return "Nenhum arquivo PDF fornecido."
        case .invalidSource(let url):
            return "Não foi possível carregar PDF: \(url.lastPathComponent)"
        case .encryptedDocument(let url):
            return "O arquivo PDF está protegido por senha e não pôde ser aberto: \(url.lastPathComponent)"
        case .writeFailed(let reason):
            return "Falha ao gravar arquivo PDF: \(reason)"
        }
    }
}

public enum PDFMerger: Sendable {
    /// Concatena múltiplos arquivos PDF em um único documento consolidado.
    @discardableResult
    public static func merge(
        sources: [URL],
        directory: URL? = nil
    ) throws -> URL {
        guard !sources.isEmpty else { throw PDFEngineError.emptySources }

        let mergedDoc = PDFDocument()
        var insertIndex = 0

        for url in sources {
            guard let doc = PDFDocument(url: url) else {
                throw PDFEngineError.invalidSource(url)
            }
            if doc.isLocked {
                throw PDFEngineError.encryptedDocument(url)
            }

            for p in 0..<doc.pageCount {
                if let page = doc.page(at: p) {
                    mergedDoc.insert(page, at: insertIndex)
                    insertIndex += 1
                }
            }
        }

        let firstURL = sources[0]
        let baseDir = directory ?? firstURL.deletingLastPathComponent()
        let rawBaseName = firstURL.deletingPathExtension().lastPathComponent
        let destinationURL = destinationMergedURL(in: baseDir, baseName: rawBaseName)

        return try OutputWriter.withStagingFile(targetURL: destinationURL) { stagingURL in
            guard mergedDoc.write(to: stagingURL) else {
                throw PDFEngineError.writeFailed("Falha ao salvar PDF mesclado")
            }
        }
    }

    private static func destinationMergedURL(in directory: URL, baseName: String) -> URL {
        let fm = FileManager.default
        var candidate = directory.appendingPathComponent("\(baseName)-merged.pdf")
        if !fm.fileExists(atPath: candidate.path) { return candidate }

        var counter = 2
        while true {
            candidate = directory.appendingPathComponent("\(baseName)-merged-\(counter).pdf")
            if !fm.fileExists(atPath: candidate.path) { return candidate }
            counter += 1
        }
    }
}
