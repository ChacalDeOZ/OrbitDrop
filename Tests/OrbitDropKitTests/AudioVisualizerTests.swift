import XCTest
import AVFoundation
@testable import OrbitDropKit

final class AudioVisualizerTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropVisualizerTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    func testCreateVisualizerVideoFromWAV() async throws {
        let audioURL = try SyntheticMediaGenerator.createWAV(
            durationSeconds: 1.0,
            sampleRate: 44100,
            channels: 2,
            frequency: 440.0,
            directory: tempDirectory
        )

        let videoURL = try await AudioVisualizer.createVisualizerVideo(
            audioURL: audioURL,
            outputDirectory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: videoURL.path))
        XCTAssertEqual(videoURL.pathExtension.lowercased(), "mp4")

        let asset = AVURLAsset(url: videoURL)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        XCTAssertFalse(tracks.isEmpty, "O arquivo resultante deve conter trilha de vídeo")

        let duration = try await asset.load(.duration)
        XCTAssertGreaterThan(CMTimeGetSeconds(duration), 0.5)
    }
}
