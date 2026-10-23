import XCTest
import AVFoundation
@testable import OrbitDropKit

final class AudioChannelsTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropAudioChannelsTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    func testSyntheticWAVGeneration() throws {
        let wavURL = try SyntheticMediaGenerator.createWAV(
            durationSeconds: 1.0,
            sampleRate: 44100,
            channels: 2,
            frequency: 440.0,
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: wavURL.path))
        let file = try AVAudioFile(forReading: wavURL)
        XCTAssertEqual(file.processingFormat.channelCount, 2)
        XCTAssertEqual(file.processingFormat.sampleRate, 44100)
        XCTAssertGreaterThan(file.length, 40000)
    }

    func testStereoToMonoConversion() throws {
        let stereoURL = try SyntheticMediaGenerator.createWAV(
            durationSeconds: 1.0,
            channels: 2,
            directory: tempDirectory
        )

        let monoURL = try AudioChannelConverter.convertChannels(
            sourceURL: stereoURL,
            targetChannels: 1,
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: monoURL.path))
        XCTAssertTrue(monoURL.lastPathComponent.contains("-mono"))

        let file = try AVAudioFile(forReading: monoURL)
        XCTAssertEqual(file.processingFormat.channelCount, 1)
        XCTAssertGreaterThan(file.length, 40000)
    }

    func testMonoToStereoConversion() throws {
        let monoURL = try SyntheticMediaGenerator.createWAV(
            durationSeconds: 1.0,
            channels: 1,
            directory: tempDirectory
        )

        let stereoURL = try AudioChannelConverter.convertChannels(
            sourceURL: monoURL,
            targetChannels: 2,
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: stereoURL.path))
        XCTAssertTrue(stereoURL.lastPathComponent.contains("-stereo"))

        let file = try AVAudioFile(forReading: stereoURL)
        XCTAssertEqual(file.processingFormat.channelCount, 2)
    }

    func testRejectsInvalidTargetChannels() throws {
        let wav = try SyntheticMediaGenerator.createWAV(durationSeconds: 0.5, directory: tempDirectory)

        XCTAssertThrowsError(
            try AudioChannelConverter.convertChannels(sourceURL: wav, targetChannels: 0, directory: tempDirectory)
        )

        XCTAssertThrowsError(
            try AudioChannelConverter.convertChannels(sourceURL: wav, targetChannels: 6, directory: tempDirectory)
        )
    }
}
