import XCTest
import PDFKit
@testable import OrbitDropKit

final class PDFMergeAndSplitTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropPDFMergeSplitTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    private func createTestPDF(pageCount: Int, tag: String) throws -> URL {
        let fileURL = tempDirectory.appendingPathComponent("test-\(tag).pdf")
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

    func testPDFMergerCombinesDocuments() throws {
        let pdf1 = try createTestPDF(pageCount: 1, tag: "doc1")
        let pdf2 = try createTestPDF(pageCount: 2, tag: "doc2")

        let mergedURL = try PDFMerger.merge(
            sources: [pdf1, pdf2],
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: mergedURL.path))
        XCTAssertTrue(mergedURL.lastPathComponent.contains("-merged"))

        guard let mergedDoc = PDFDocument(url: mergedURL) else {
            XCTFail("PDF merged deve ser legível")
            return
        }
        XCTAssertEqual(mergedDoc.pageCount, 3)
    }

    func testPDFSplitterDividesPages() throws {
        let pdf = try createTestPDF(pageCount: 3, tag: "multipage")

        let pages = try PDFSplitter.split(sourceURL: pdf, directory: tempDirectory)

        XCTAssertEqual(pages.count, 3)
        for (idx, pageURL) in pages.enumerated() {
            XCTAssertTrue(FileManager.default.fileExists(atPath: pageURL.path))
            let doc = PDFDocument(url: pageURL)
            XCTAssertEqual(doc?.pageCount, 1)
            let expectedNum = String(format: "%03d", idx + 1)
            XCTAssertTrue(pageURL.lastPathComponent.contains("-page-\(expectedNum)"))
        }
    }
}
