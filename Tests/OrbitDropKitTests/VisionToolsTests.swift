import XCTest
import CoreGraphics
import CoreImage
import ImageIO
@testable import OrbitDropKit

final class VisionToolsTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropVisionTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    private func createSolidPNG(width: Int = 100, height: Int = 100) throws -> URL {
        let fileURL = tempDirectory.appendingPathComponent("vision-\(UUID().uuidString).png")
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
        ) else { throw XCTSkip("Erro ao criar CGContext") }

        context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        guard let image = context.makeImage(),
              let dest = CGImageDestinationCreateWithURL(fileURL as CFURL, "public.png" as CFString, 1, nil) else {
            throw XCTSkip("Erro ao criar PNG")
        }
        CGImageDestinationAddImage(dest, image, nil)
        CGImageDestinationFinalize(dest)
        return fileURL
    }

    func testRedactorBurnsSolidBlackPixels() throws {
        let sourceURL = try createSolidPNG(width: 100, height: 100)
        let redactionRect = CGRect(x: 10, y: 10, width: 40, height: 40)

        let outputURL = try ImageRedactor.redact(
            sourceURL: sourceURL,
            regions: [redactionRect],
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        XCTAssertTrue(outputURL.lastPathComponent.contains("-redacted"))

        guard let sourceRef = CGImageSourceCreateWithURL(outputURL as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(sourceRef, 0, nil),
              let providerData = image.dataProvider?.data,
              let bytes = CFDataGetBytePtr(providerData) else {
            XCTFail("Imagem redigida deve ser decodificável")
            return
        }

        let bytesPerPixel = image.bitsPerPixel / 8
        let bytesPerRow = image.bytesPerRow
        let sampleX = 20
        let sampleY = 20
        // CGImage coordinates use bottom-left origin; decoded provider rows are top-down.
        let offset = (image.height - 1 - sampleY) * bytesPerRow + sampleX * bytesPerPixel

        // RGB no ponto dentro da tarja deve ser preto puro
        XCTAssertEqual(bytes[offset], 0)
        XCTAssertEqual(bytes[offset + 1], 0)
        XCTAssertEqual(bytes[offset + 2], 0)
    }

    func testQRCodeReaderDecodesSyntheticQR() async throws {
        let payload = "orbitdrop://offline-test-123"
        let data = payload.data(using: .utf8)!

        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            throw XCTSkip("CIQRCodeGenerator indisponível")
        }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 8, y: 8)) else {
            throw XCTSkip("Erro ao gerar QR")
        }

        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            throw XCTSkip("Erro ao renderizar QR")
        }

        let qrURL = tempDirectory.appendingPathComponent("qr.png")
        guard let destination = CGImageDestinationCreateWithURL(qrURL as CFURL, "public.png" as CFString, 1, nil) else {
            throw XCTSkip("Erro ao criar arquivo QR")
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        CGImageDestinationFinalize(destination)

        let results = try await QRCodeReader.read(from: qrURL)
        XCTAssertTrue(results.contains(payload))
    }
}
