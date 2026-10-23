import XCTest
import CoreGraphics
import ImageIO
import PDFKit
@testable import OrbitDropKit

final class ImageToPDFTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropPDFTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    private func createImage(width: Int, height: Int, index: Int) throws -> URL {
        let fileURL = tempDirectory.appendingPathComponent("page-\(index).png")
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { throw XCTSkip("Erro CGContext") }

        context.setFillColor(CGColor(red: CGFloat(index) * 0.2, green: 0.5, blue: 0.8, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let image = context.makeImage(),
              let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, "public.png" as CFString, 1, nil) else {
            throw XCTSkip("Erro PNG")
        }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        return fileURL
    }

    func testCreatesThreePagePDF() throws {
        let p1 = try createImage(width: 100, height: 80, index: 1)
        let p2 = try createImage(width: 80, height: 120, index: 2)
        let p3 = try createImage(width: 120, height: 100, index: 3)

        let pdfURL = try ImageToPDFConverter.createPDF(
            from: [p1, p2, p3],
            outputDirectory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: pdfURL.path))
        XCTAssertEqual(pdfURL.pathExtension.lowercased(), "pdf")

        guard let document = PDFDocument(url: pdfURL) else {
            XCTFail("PDF gerado deve ser válido e legível pelo PDFKit")
            return
        }
        XCTAssertEqual(document.pageCount, 3)
    }

    func testMultiFrameTIFFPagesPreservedInPDF() throws {
        let tiffURL = tempDirectory.appendingPathComponent("multipage.tiff")
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: 80,
            height: 80,
            bitsPerComponent: 8,
            bytesPerRow: 80 * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ), let img1 = context.makeImage(), let img2 = context.makeImage(),
           let destination = CGImageDestinationCreateWithURL(tiffURL as CFURL, "public.tiff" as CFString, 2, nil) else {
            throw XCTSkip("Erro ao criar multi-frame TIFF")
        }

        CGImageDestinationAddImage(destination, img1, nil)
        CGImageDestinationAddImage(destination, img2, nil)
        CGImageDestinationFinalize(destination)

        let pdfURL = try ImageToPDFConverter.createPDF(from: [tiffURL], outputDirectory: tempDirectory)
        guard let document = PDFDocument(url: pdfURL) else {
            XCTFail("PDF multi-frame deve ser legível")
            return
        }
        XCTAssertEqual(document.pageCount, 2, "PDF deve conter ambos os frames do TIFF")
    }
}
