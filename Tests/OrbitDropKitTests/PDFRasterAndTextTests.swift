import XCTest
import PDFKit
import ImageIO
@testable import OrbitDropKit

final class PDFRasterAndTextTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropPDFRasterTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    private func createTextPDF() throws -> URL {
        let fileURL = tempDirectory.appendingPathComponent("text-document.pdf")
        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792) // Letter
        guard let consumer = CGDataConsumer(url: fileURL as CFURL),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw XCTSkip("Erro ao criar PDF de teste")
        }

        context.beginPDFPage(nil)
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext
        let text = "OrbitDrop PDF Text Extraction Test"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18),
            .foregroundColor: NSColor.black
        ]
        (text as NSString).draw(at: CGPoint(x: 72, y: 700), withAttributes: attrs)
        NSGraphicsContext.restoreGraphicsState()
        context.endPDFPage()
        context.closePDF()
        return fileURL
    }

    func testPDFRasterizerAt300DPI() throws {
        let pdfURL = try createTextPDF()

        let images = try PDFRasterizer.renderPages(
            sourceURL: pdfURL,
            dpi: 300,
            format: .png,
            directory: tempDirectory
        )

        XCTAssertEqual(images.count, 1)
        guard let sourceRef = CGImageSourceCreateWithURL(images[0] as CFURL, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, nil) as? [CFString: Any] else {
            XCTFail("Imagem rasterizada deve ser válida")
            return
        }

        let width = props[kCGImagePropertyPixelWidth] as? Int ?? 0
        let height = props[kCGImagePropertyPixelHeight] as? Int ?? 0
        XCTAssertEqual(width, 2550, accuracy: 2)   // 612 * 300/72
        XCTAssertEqual(height, 3300, accuracy: 2)  // 792 * 300/72
    }

    func testPDFRasterizerRotatedPage() throws {
        let pdfURL = try createTextPDF()
        guard let doc = PDFDocument(url: pdfURL), let page = doc.page(at: 0) else {
            throw XCTSkip("Falha ao abrir PDF")
        }
        page.rotation = 90
        doc.write(to: pdfURL)

        let images = try PDFRasterizer.renderPages(
            sourceURL: pdfURL,
            dpi: 300,
            format: .png,
            directory: tempDirectory
        )

        guard let sourceRef = CGImageSourceCreateWithURL(images[0] as CFURL, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, nil) as? [CFString: Any] else {
            XCTFail("Imagem rasterizada de página rotacionada deve ser válida")
            return
        }

        let width = props[kCGImagePropertyPixelWidth] as? Int ?? 0
        let height = props[kCGImagePropertyPixelHeight] as? Int ?? 0
        // Em 90 graus, dimensões Letter invertem: 3300x2550
        XCTAssertEqual(width, 3300, accuracy: 2)
        XCTAssertEqual(height, 2550, accuracy: 2)
    }

    func testPDFTextExtractor() throws {
        let pdfURL = try createTextPDF()

        let textURL = try PDFTextExtractor.extractText(
            sourceURL: pdfURL,
            format: .text,
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: textURL.path))
        let content = try String(contentsOf: textURL, encoding: .utf8)
        XCTAssertTrue(content.contains("OrbitDrop PDF Text Extraction Test"))
    }
}
