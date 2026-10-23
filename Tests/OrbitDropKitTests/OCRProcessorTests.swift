import XCTest
import AppKit
@testable import OrbitDropKit

final class OCRProcessorTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropOCRTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    func testImageOCRRecognition() async throws {
        let imageSize = CGSize(width: 600, height: 200)
        let image = NSImage(size: imageSize)
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: imageSize).fill()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 36, weight: .bold),
            .foregroundColor: NSColor.black
        ]
        ("ORBITDROP VISION OCR" as NSString).draw(at: CGPoint(x: 40, y: 80), withAttributes: attrs)
        image.unlockFocus()

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw XCTSkip("Falha ao gerar PNG")
        }

        let imgURL = tempDirectory.appendingPathComponent("ocr_source.png")
        try pngData.write(to: imgURL)

        let resultURL = try await OCRProcessor.recognizeText(
            sourceURL: imgURL,
            format: .markdown,
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: resultURL.path))
        XCTAssertEqual(resultURL.pathExtension.lowercased(), "md")

        let content = try String(contentsOf: resultURL, encoding: .utf8)
        XCTAssertTrue(content.contains("ORBITDROP"))
        XCTAssertTrue(content.contains("VISION"))
        XCTAssertTrue(content.contains("OCR"))
    }
}
