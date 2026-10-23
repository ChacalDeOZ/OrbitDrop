import XCTest
import CoreGraphics
import ImageIO
@testable import OrbitDropKit

final class ImageCompressorTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropCompressorTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    private func createGradientPNG(width: Int = 300, height: Int = 300) throws -> URL {
        let fileURL = tempDirectory.appendingPathComponent("gradient-\(UUID().uuidString).png")
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

        // Desenhar padrão complexo
        for x in 0..<width {
            for y in 0..<height {
                let r = CGFloat(x) / CGFloat(width)
                let g = CGFloat(y) / CGFloat(height)
                let b = CGFloat((x + y) % 256) / 256.0
                context.setFillColor(CGColor(red: r, green: g, blue: b, alpha: 1.0))
                context.fill(CGRect(x: x, y: y, width: 1, height: 1))
            }
        }

        guard let image = context.makeImage(),
              let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, "public.png" as CFString, 1, nil) else {
            throw XCTSkip("Erro ao criar destino PNG")
        }

        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        return fileURL
    }

    func testCompressReducesFileSize() throws {
        let sourceURL = try createGradientPNG(width: 200, height: 200)
        let originalSize = (try? FileManager.default.attributesOfItem(atPath: sourceURL.path)[.size] as? NSNumber)?.int64Value ?? 0
        XCTAssertGreaterThan(originalSize, 5_000)

        let compressedURL = try ImageCompressor.compress(
            sourceURL: sourceURL,
            targetBytes: originalSize / 2,
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: compressedURL.path))
        XCTAssertTrue(compressedURL.lastPathComponent.contains("-compressed"))

        let compressedSize = (try? FileManager.default.attributesOfItem(atPath: compressedURL.path)[.size] as? NSNumber)?.int64Value ?? 0
        XCTAssertLessThan(compressedSize, originalSize, "Tamanho comprimido deve ser menor que o original")

        // Validar decodificação da saída
        guard let sourceRef = CGImageSourceCreateWithURL(compressedURL as CFURL, nil) else {
            XCTFail("Arquivo comprimido deve ser decodificável")
            return
        }
        XCTAssertGreaterThan(CGImageSourceGetCount(sourceRef), 0)
    }

    func testCompressWithImpossibleTargetDoesNotHang() throws {
        let sourceURL = try createGradientPNG(width: 50, height: 50)
        // Pedir alvo impossível de 10 bytes: deve retornar menor compressão viável sem travar
        let compressedURL = try ImageCompressor.compress(
            sourceURL: sourceURL,
            targetBytes: 10,
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: compressedURL.path))
    }

    func testCompressKeepsCandidateUnderTargetInsteadOfOvershooting() throws {
        let sourceURL = try createGradientPNG(width: 250, height: 250)
        let originalSize = (try? FileManager.default.attributesOfItem(atPath: sourceURL.path)[.size] as? NSNumber)?.int64Value ?? 0
        let target = originalSize / 3

        let compressedURL = try ImageCompressor.compress(
            sourceURL: sourceURL,
            targetBytes: target,
            directory: tempDirectory,
            maxSteps: 6
        )

        let compressedSize = (try? FileManager.default.attributesOfItem(atPath: compressedURL.path)[.size] as? NSNumber)?.int64Value ?? 0
        XCTAssertLessThanOrEqual(compressedSize, target, "Compressor deve respeitar o teto quando alcançável")
    }
}
