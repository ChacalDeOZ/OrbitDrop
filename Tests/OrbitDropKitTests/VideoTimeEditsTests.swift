import XCTest
import AVFoundation
@testable import OrbitDropKit

final class VideoTimeEditsTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropVideoTimeTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    func testVideoTrimmer() async throws {
        let mp4URL = try await SyntheticMediaGenerator.createMP4(
            durationSeconds: 1.0,
            width: 160,
            height: 120,
            directory: tempDirectory
        )

        let trimmedURL = try await VideoTrimmer.trim(
            sourceURL: mp4URL,
            startTimeSeconds: 0.2,
            durationSeconds: 0.5,
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: trimmedURL.path))
        XCTAssertTrue(trimmedURL.lastPathComponent.contains("-trimmed"))

        let asset = AVURLAsset(url: trimmedURL)
        let duration = try await asset.load(.duration)
        XCTAssertEqual(CMTimeGetSeconds(duration), 0.5, accuracy: 0.1)
    }

    func testVideoSpeedController() async throws {
        let mp4URL = try await SyntheticMediaGenerator.createMP4(
            durationSeconds: 1.0,
            width: 160,
            height: 120,
            directory: tempDirectory
        )

        let fastURL = try await VideoSpeedController.changeSpeed(
            sourceURL: mp4URL,
            speedFactor: 2.0,
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: fastURL.path))
        XCTAssertTrue(fastURL.lastPathComponent.contains("-speed-2.0x"))

        let asset = AVURLAsset(url: fastURL)
        let duration = try await asset.load(.duration)
        XCTAssertEqual(CMTimeGetSeconds(duration), 0.5, accuracy: 0.1)
    }
}
