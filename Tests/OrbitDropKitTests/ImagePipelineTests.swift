import XCTest
import Foundation
import CoreGraphics
import ImageIO
@testable import OrbitDropKit

final class ImagePipelineTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropImagePipelineTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    /// Cria uma imagem PNG sintética válida em disco com dimensões conhecidas.
    private func createSyntheticPNG(width: Int = 64, height: Int = 64) throws -> URL {
        let fileURL = tempDirectory.appendingPathComponent("test-\(UUID().uuidString).png")
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
            throw XCTSkip("Não foi possível criar CGContext")
        }

        context.setFillColor(CGColor(red: 1.0, green: 0.2, blue: 0.4, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        guard let image = context.makeImage() else {
            throw XCTSkip("Não foi possível criar CGImage")
        }

        guard let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, "public.png" as CFString, 1, nil) else {
            throw XCTSkip("Não foi possível criar CGImageDestination")
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw XCTSkip("Não foi possível finalizar escrita do PNG")
        }

        return fileURL
    }

    func testConvertPNGtoJPEG() throws {
        let sourceURL = try createSyntheticPNG(width: 80, height: 80)
        let sourceDataBefore = try Data(contentsOf: sourceURL)

        let resultURL = try ImagePipeline.convert(
            sourceURL: sourceURL,
            targetExtension: "jpg",
            compressionQuality: 0.85
        )

        // 1. Verifica existência e terminação
        XCTAssertTrue(FileManager.default.fileExists(atPath: resultURL.path))
        XCTAssertEqual(resultURL.pathExtension.lowercased(), "jpg")
        XCTAssertTrue(resultURL.lastPathComponent.contains("-converted"))

        // 2. Decodificação da saída
        guard let sourceRef = CGImageSourceCreateWithURL(resultURL as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, nil) as? [CFString: Any] else {
            XCTFail("Saída JPEG deve ser decodificável pelo ImageIO")
            return
        }

        let width = properties[kCGImagePropertyPixelWidth] as? Int
        let height = properties[kCGImagePropertyPixelHeight] as? Int
        XCTAssertEqual(width, 80)
        XCTAssertEqual(height, 80)

        // 3. Regra Sagrada: original permanece 100% inalterado
        let sourceDataAfter = try Data(contentsOf: sourceURL)
        XCTAssertEqual(sourceDataBefore, sourceDataAfter, "Arquivo original nunca pode ser modificado")
    }

    func testConvertInvalidSourceThrows() {
        let fakeURL = tempDirectory.appendingPathComponent("corrupted.png")
        try? "not an image".write(to: fakeURL, atomically: true, encoding: .utf8)

        XCTAssertThrowsError(
            try ImagePipeline.convert(sourceURL: fakeURL, targetExtension: "jpg")
        )
    }
}
