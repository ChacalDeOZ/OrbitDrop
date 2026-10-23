import XCTest
import PDFKit
@testable import OrbitDropKit

final class PDFPageOrganizerTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropPDFOrganizerTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    private func createTestPDF(pageCount: Int) throws -> URL {
        let fileURL = tempDirectory.appendingPathComponent("test-pages.pdf")
        let doc = PDFDocument()

        for i in 0..<pageCount {
            let pageRect = CGRect(x: 0, y: 0, width: 200, height: 200)
            let renderer = CGContext(
                data: nil,
                width: 200,
                height: 200,
                bitsPerComponent: 8,
                bytesPerRow: 200 * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )!
            renderer.setFillColor(CGColor(red: CGFloat(i) * 0.3, green: 0.5, blue: 0.7, alpha: 1.0))
            renderer.fill(pageRect)
            let img = renderer.makeImage()!
            let page = PDFPage(image: NSImage(cgImage: img, size: pageRect.size))!
            doc.insert(page, at: i)
        }

        doc.write(to: fileURL)
        return fileURL
    }

    func testRotateAndReorderPages() throws {
        let pdf = try createTestPDF(pageCount: 3)

        // Rotação da página 0 em 90 graus e exclusão da página 2
        let actions: [PDFPageAction] = [
            .rotate(pageIndex: 0, degrees: 90),
            .delete(pageIndex: 2)
        ]

        let organizedURL = try PDFPageOrganizer.reorganize(
            sourceURL: pdf,
            actions: actions,
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: organizedURL.path))
        XCTAssertTrue(organizedURL.lastPathComponent.contains("-organized"))

        guard let doc = PDFDocument(url: organizedURL) else {
            XCTFail("PDF organizado deve ser legível")
            return
        }

        XCTAssertEqual(doc.pageCount, 2, "Página 2 foi excluída, devem restar 2 páginas")
        XCTAssertEqual(doc.page(at: 0)?.rotation, 90, "Página 0 deve estar rotacionada em 90 graus")
    }
}
