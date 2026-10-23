import XCTest
import AVFoundation
import ImageIO
@testable import OrbitDropKit

final class VideoTranscodeAndFramesTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropVideoTranscodeTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    func testTranscodeMP4ToMOV() async throws {
        let mp4URL = try await SyntheticMediaGenerator.createMP4(
            durationSeconds: 1.0,
            width: 160,
            height: 120,
            directory: tempDirectory
        )

        let movURL = try await VideoTranscoder.transcode(
            sourceURL: mp4URL,
            targetExtension: "mov",
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: movURL.path))
        XCTAssertEqual(movURL.pathExtension.lowercased(), "mov")

        let asset = AVURLAsset(url: movURL)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        XCTAssertFalse(tracks.isEmpty)
    }

    func testExtractFrameToPNG() async throws {
        let mp4URL = try await SyntheticMediaGenerator.createMP4(
            durationSeconds: 1.0,
            width: 160,
            height: 120,
            directory: tempDirectory
        )

        let frameURL = try await VideoFrameExtractor.extractFrame(
            sourceURL: mp4URL,
            atSeconds: 0.5,
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: frameURL.path))
        XCTAssertEqual(frameURL.pathExtension.lowercased(), "png")

        guard let sourceRef = CGImageSourceCreateWithURL(frameURL as CFURL, nil) else {
            XCTFail("Frame extraído deve ser imagem válida")
            return
        }
        XCTAssertGreaterThan(CGImageSourceGetCount(sourceRef), 0)
    }
}
