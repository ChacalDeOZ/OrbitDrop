import XCTest
import CoreGraphics
import ImageIO
@testable import OrbitDropKit

final class ImageEditsTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropImageEditsTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    private func createSyntheticImage(width: Int, height: Int) throws -> URL {
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

        context.setFillColor(CGColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        guard let image = context.makeImage(),
              let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, "public.png" as CFString, 1, nil) else {
            throw XCTSkip("Erro ao criar destino PNG")
        }

        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        return fileURL
    }

    func testImageAdjustmentsFilter() throws {
        let sourceURL = try createSyntheticImage(width: 80, height: 80)
        let outputURL = try ImageAdjustments.apply(
            sourceURL: sourceURL,
            contrast: 1.3,
            brightness: 0.1,
            saturation: 1.2,
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        XCTAssertTrue(outputURL.lastPathComponent.contains("-adjusted"))

        guard let sourceRef = CGImageSourceCreateWithURL(outputURL as CFURL, nil) else {
            XCTFail("Imagem ajustada deve ser decodificável")
            return
        }
        XCTAssertGreaterThan(CGImageSourceGetCount(sourceRef), 0)
    }

    func testImageCropperDimensions() throws {
        let sourceURL = try createSyntheticImage(width: 100, height: 100)
        let cropRect = CGRect(x: 20, y: 20, width: 40, height: 40)

        let outputURL = try ImageCropper.crop(
            sourceURL: sourceURL,
            cropRect: cropRect,
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        XCTAssertTrue(outputURL.lastPathComponent.contains("-cropped"))

        guard let sourceRef = CGImageSourceCreateWithURL(outputURL as CFURL, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, nil) as? [CFString: Any] else {
            XCTFail("Imagem cortada deve ser decodificável")
            return
        }

        let width = props[kCGImagePropertyPixelWidth] as? Int
        let height = props[kCGImagePropertyPixelHeight] as? Int
        XCTAssertEqual(width, 40)
        XCTAssertEqual(height, 40)
    }

    func testImageBackgroundAdderExpandsCanvas() throws {
        let sourceURL = try createSyntheticImage(width: 60, height: 60)
        let padding: CGFloat = 20

        let outputURL = try ImageBackgroundAdder.addBackground(
            sourceURL: sourceURL,
            padding: padding,
            backgroundColor: CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            cornerRadius: 8,
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        XCTAssertTrue(outputURL.lastPathComponent.contains("-background"))

        guard let sourceRef = CGImageSourceCreateWithURL(outputURL as CFURL, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, nil) as? [CFString: Any] else {
            XCTFail("Imagem com fundo deve ser decodificável")
            return
        }

        let width = props[kCGImagePropertyPixelWidth] as? Int
        let height = props[kCGImagePropertyPixelHeight] as? Int
        XCTAssertEqual(width, 100) // 60 + 2 * 20
        XCTAssertEqual(height, 100)
    }
}
