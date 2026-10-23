import XCTest
import CoreGraphics
import ImageIO
@testable import OrbitDropKit

final class AnnotationAndCollageTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropAnnotationTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    private func createTestPNG(width: Int = 50, height: Int = 50, color: (CGFloat, CGFloat, CGFloat) = (0.2, 0.4, 0.8)) throws -> URL {
        let fileURL = tempDirectory.appendingPathComponent("fixture-\(UUID().uuidString).png")
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
        ) else {
            throw XCTSkip("Erro ao criar CGContext")
        }

        context.setFillColor(CGColor(red: color.0, green: color.1, blue: color.2, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        guard let image = context.makeImage(),
              let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, "public.png" as CFString, 1, nil) else {
            throw XCTSkip("Erro ao criar destino PNG")
        }

        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        return fileURL
    }

    func testAnnotatorRendersOverlay() throws {
        let sourceURL = try createTestPNG(width: 100, height: 100)
        let redColor = CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        let whiteColor = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        let rectAnnotation = AnnotationItem.rectangle(rect: CGRect(x: 10, y: 10, width: 40, height: 40), strokeColor: redColor, lineWidth: 2)
        let textAnnotation = AnnotationItem.text("Aprovado", at: CGPoint(x: 10, y: 60), color: whiteColor)

        let outputURL = try ImageAnnotator.annotate(
            sourceURL: sourceURL,
            annotations: [rectAnnotation, textAnnotation],
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        XCTAssertTrue(outputURL.lastPathComponent.contains("-annotated"))

        guard let sourceRef = CGImageSourceCreateWithURL(outputURL as CFURL, nil) else {
            XCTFail("Imagem anotada deve ser decodificável")
            return
        }
        XCTAssertGreaterThan(CGImageSourceGetCount(sourceRef), 0)
    }

    func testCollageCombinesMultipleImages() throws {
        let f1 = try createTestPNG(width: 50, height: 50, color: (1.0, 0, 0))
        let f2 = try createTestPNG(width: 50, height: 50, color: (0, 1.0, 0))

        let outputURL = try ImageCollageBuilder.createCollage(
            sources: [f1, f2],
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        XCTAssertTrue(outputURL.lastPathComponent.contains("-collage"))

        guard let sourceRef = CGImageSourceCreateWithURL(outputURL as CFURL, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, nil) as? [CFString: Any] else {
            XCTFail("Colagem deve ser decodificável")
            return
        }

        let width = props[kCGImagePropertyPixelWidth] as? Int ?? 0
        let height = props[kCGImagePropertyPixelHeight] as? Int ?? 0
        XCTAssertGreaterThanOrEqual(width, 100, "Largura de 2 imagens 50x50 lado a lado deve ser >= 100")
        XCTAssertGreaterThanOrEqual(height, 50)
    }
}
