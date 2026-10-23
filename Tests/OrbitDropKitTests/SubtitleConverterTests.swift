import XCTest
@testable import OrbitDropKit

final class SubtitleConverterTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropSubtitleTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    func testSRTToVTTConversion() throws {
        let srtContent = """
        1
        00:01:20,000 --> 00:01:23,500
        Olá mundo! Primeira legenda.

        2
        00:01:24,100 --> 00:01:26,800
        Segunda linha de legenda com acentuação.
        """

        let srtURL = tempDirectory.appendingPathComponent("sample.srt")
        try srtContent.write(to: srtURL, atomically: true, encoding: .utf8)

        let vttURL = try SubtitleConverter.convert(
            sourceURL: srtURL,
            targetFormat: .vtt,
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: vttURL.path))
        XCTAssertEqual(vttURL.pathExtension.lowercased(), "vtt")

        let vttContent = try String(contentsOf: vttURL, encoding: .utf8)
        XCTAssertTrue(vttContent.hasPrefix("WEBVTT"), "VTT deve conter cabeçalho WEBVTT")
        XCTAssertTrue(vttContent.contains("00:01:20.000 --> 00:01:23.500"), "VTT deve usar ponto nos milissegundos")
    }

    func testVTTToSRTConversion() throws {
        let vttContent = """
        WEBVTT

        00:02:10.150 --> 00:02:12.750
        Linha de teste em VTT.
        """

        let vttURL = tempDirectory.appendingPathComponent("sample.vtt")
        try vttContent.write(to: vttURL, atomically: true, encoding: .utf8)

        let srtURL = try SubtitleConverter.convert(
            sourceURL: vttURL,
            targetFormat: .srt,
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: srtURL.path))
        XCTAssertEqual(srtURL.pathExtension.lowercased(), "srt")

        let srtResult = try String(contentsOf: srtURL, encoding: .utf8)
        XCTAssertFalse(srtResult.contains("WEBVTT"), "SRT não deve conter cabeçalho WEBVTT")
        XCTAssertTrue(srtResult.contains("00:02:10,150 --> 00:02:12,750"), "SRT deve usar vírgula nos milissegundos")
    }
}
