import XCTest
import AVFoundation
@testable import OrbitDropKit

final class VideoCompositionTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropVideoCompTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    func testVideoJoinerCombinesClips() async throws {
        let v1 = try await SyntheticMediaGenerator.createMP4(durationSeconds: 0.5, width: 160, height: 120, directory: tempDirectory)
        let v2 = try await SyntheticMediaGenerator.createMP4(durationSeconds: 0.5, width: 160, height: 120, directory: tempDirectory)

        let joinedURL = try await VideoJoiner.join(sources: [v1, v2], directory: tempDirectory)

        XCTAssertTrue(FileManager.default.fileExists(atPath: joinedURL.path))
        XCTAssertTrue(joinedURL.lastPathComponent.contains("-joined"))

        let asset = AVURLAsset(url: joinedURL)
        let duration = try await asset.load(.duration)
        XCTAssertEqual(CMTimeGetSeconds(duration), 1.0, accuracy: 0.15)
    }

    func testVideoSplitterDividesIntoParts() async throws {
        let video = try await SyntheticMediaGenerator.createMP4(durationSeconds: 1.0, width: 160, height: 120, directory: tempDirectory)

        let parts = try await VideoSplitter.split(sourceURL: video, partsCount: 2, directory: tempDirectory)

        XCTAssertEqual(parts.count, 2)
        for part in parts {
            XCTAssertTrue(FileManager.default.fileExists(atPath: part.path))
            let asset = AVURLAsset(url: part)
            let duration = try await asset.load(.duration)
            XCTAssertEqual(CMTimeGetSeconds(duration), 0.5, accuracy: 0.15)
        }
    }

    func testVideoCropperAndRedactorSucceed() async throws {
        let video = try await SyntheticMediaGenerator.createMP4(durationSeconds: 0.5, width: 160, height: 120, directory: tempDirectory)

        let croppedURL = try await VideoCropper.crop(sourceURL: video, cropRect: CGRect(x: 10, y: 10, width: 80, height: 80), directory: tempDirectory)
        XCTAssertTrue(FileManager.default.fileExists(atPath: croppedURL.path))

        let redactedURL = try await VideoRedactor.redact(sourceURL: video, regions: [CGRect(x: 20, y: 20, width: 40, height: 40)], directory: tempDirectory)
        XCTAssertTrue(FileManager.default.fileExists(atPath: redactedURL.path))
    }
}
