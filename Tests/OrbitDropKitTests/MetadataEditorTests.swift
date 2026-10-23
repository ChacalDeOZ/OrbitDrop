import XCTest
import CoreGraphics
import ImageIO
@testable import OrbitDropKit

final class MetadataEditorTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropMetadataTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    private func createTestJPEGWithGPS() throws -> URL {
        let fileURL = tempDirectory.appendingPathComponent("photo_with_gps-\(UUID().uuidString).jpg")
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: 64,
            height: 64,
            bitsPerComponent: 8,
            bytesPerRow: 64 * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw XCTSkip("Erro ao criar CGContext")
        }

        context.setFillColor(CGColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: 64, height: 64))

        guard let image = context.makeImage(),
              let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, "public.jpeg" as CFString, 1, nil) else {
            throw XCTSkip("Erro ao criar destino JPEG")
        }

        let gpsDict: [CFString: Any] = [
            kCGImagePropertyGPSLatitude: 22.9068,
            kCGImagePropertyGPSLongitude: 43.1729,
            kCGImagePropertyGPSAltitude: 10
        ]
        let exifDict: [CFString: Any] = [
            kCGImagePropertyExifUserComment: "Camera secreta",
            kCGImagePropertyExifLensModel: "50mm f/1.4"
        ]

        let properties: [CFString: Any] = [
            kCGImagePropertyGPSDictionary: gpsDict,
            kCGImagePropertyExifDictionary: exifDict
        ]

        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        CGImageDestinationFinalize(destination)
        return fileURL
    }

    func testReadAndStripAllMetadata() throws {
        let sourceURL = try createTestJPEGWithGPS()

        // 1. Ler metadados originais e confirmar presença de GPS e EXIF
        let initialMeta = MetadataEditor.readMetadata(sourceURL: sourceURL)
        XCTAssertNotNil(initialMeta[kCGImagePropertyGPSDictionary as String], "GPS deve estar presente no fixture inicial")
        XCTAssertNotNil(initialMeta[kCGImagePropertyExifDictionary as String], "EXIF deve estar presente no fixture inicial")

        // 2. Executar expurgo total de metadados
        let cleanURL = try MetadataEditor.stripAllMetadata(sourceURL: sourceURL, directory: tempDirectory)

        XCTAssertTrue(FileManager.default.fileExists(atPath: cleanURL.path))
        XCTAssertTrue(cleanURL.lastPathComponent.contains("-clean"))

        // 3. Inspecionar a cópia gerada e atestar ausência de metadados privados
        let cleanMeta = MetadataEditor.readMetadata(sourceURL: cleanURL)
        XCTAssertNil(cleanMeta[kCGImagePropertyGPSDictionary as String], "GPS DEVE ser 100% removido da cópia")

        let cleanExif = cleanMeta[kCGImagePropertyExifDictionary as String] as? [String: Any]
        XCTAssertNil(cleanExif?[kCGImagePropertyExifUserComment as String], "UserComment DEVE ser removido")
        XCTAssertNil(cleanExif?[kCGImagePropertyExifLensModel as String], "LensModel DEVE ser removido")

        // 4. Confirmar que imagem continua decodificável
        guard let sourceRef = CGImageSourceCreateWithURL(cleanURL as CFURL, nil) else {
            XCTFail("Imagem sem metadados deve ser válida e decodificável")
            return
        }
        XCTAssertGreaterThan(CGImageSourceGetCount(sourceRef), 0)
    }
}
