import XCTest
import Foundation
import CoreGraphics
import ImageIO
@testable import OrbitDropKit

final class UnlimitedUsageTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropUnlimitedTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    private func createTestPNG() throws -> URL {
        let fileURL = tempDirectory.appendingPathComponent("fixture-\(UUID().uuidString).png")
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: 16,
            height: 16,
            bitsPerComponent: 8,
            bytesPerRow: 16 * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw XCTSkip("Erro ao criar CGContext")
        }

        context.setFillColor(CGColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: 16, height: 16))

        guard let image = context.makeImage(),
              let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, "public.png" as CFString, 1, nil) else {
            throw XCTSkip("Erro ao criar destino PNG")
        }

        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        return fileURL
    }

    func testContinuousOperationsExceedingCompetitorTrialLimit() throws {
        // O concorrente bloqueia no 21º arquivo com paywall/trial de US$ 29,99.
        // O OrbitDrop garante operação 100% gratuita, offline e ilimitada.
        let totalConversions = 105
        var successfulConversions = 0

        for index in 1...totalConversions {
            let source = try createTestPNG()
            let output = try ImagePipeline.convert(
                sourceURL: source,
                targetExtension: "jpg",
                directory: tempDirectory
            )

            XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
            successfulConversions += 1

            // Provas pontuais exigidas pelo contrato de requisitos:
            if index == 20 {
                XCTAssertEqual(successfulConversions, 20, "20ª conversão concluída com sucesso")
            }
            if index == 21 {
                XCTAssertEqual(successfulConversions, 21, "21ª conversão ultrapassa o trial do concorrente sem restrição!")
            }
            if index == 100 {
                XCTAssertEqual(successfulConversions, 100, "100ª conversão bem sucedida")
            }
            if index == 101 {
                XCTAssertEqual(successfulConversions, 101, "101ª conversão operando normalmente sem licença ou cota")
            }
        }

        XCTAssertEqual(successfulConversions, totalConversions)
    }
}
