import XCTest
import AVFoundation
@testable import OrbitDropKit

final class AudioToolsTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropAudioToolsTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    func testAudioNormalizerPeakAdjustment() throws {
        // Gera áudio baixo com pico de 0.2 (~ -14 dBFS)
        let lowAudioURL = try SyntheticMediaGenerator.createWAV(
            durationSeconds: 1.0,
            sampleRate: 44100,
            channels: 1,
            frequency: 440.0,
            directory: tempDirectory
        )

        let normalizedURL = try AudioNormalizer.normalize(
            sourceURL: lowAudioURL,
            targetPeakDBFS: -1.0,
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: normalizedURL.path))
        XCTAssertTrue(normalizedURL.lastPathComponent.contains("-normalized"))

        let file = try AVAudioFile(forReading: normalizedURL)
        let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))!
        try file.read(into: buffer)

        var maxPeak: Float = 0
        if let data = buffer.floatChannelData?[0] {
            for i in 0..<Int(buffer.frameLength) {
                maxPeak = max(maxPeak, abs(data[i]))
            }
        }

        // -1.0 dBFS corresponde a ~0.891 linear
        XCTAssertEqual(maxPeak, 0.891, accuracy: 0.05)
    }

    func testAudioNormalizerWithSilentAudioDoesNotCrash() throws {
        let silentURL = try SyntheticMediaGenerator.createWAV(
            durationSeconds: 0.5,
            frequency: 0.0, // onda 0
            directory: tempDirectory
        )

        let normalizedURL = try AudioNormalizer.normalize(
            sourceURL: silentURL,
            targetPeakDBFS: -1.0,
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: normalizedURL.path))
    }

    func testAudioTrimmerReducesDuration() throws {
        let sourceURL = try SyntheticMediaGenerator.createWAV(
            durationSeconds: 1.0,
            sampleRate: 44100,
            channels: 1,
            directory: tempDirectory
        )

        let trimmedURL = try AudioTrimmer.trim(
            sourceURL: sourceURL,
            startTimeSeconds: 0.2,
            durationSeconds: 0.5,
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: trimmedURL.path))
        XCTAssertTrue(trimmedURL.lastPathComponent.contains("-trimmed"))

        let file = try AVAudioFile(forReading: trimmedURL)
        let expectedFrames = Int64(0.5 * 44100)
        XCTAssertEqual(file.length, expectedFrames, accuracy: 200)
    }

    func testAudioTrimmerRejectsInvalidDurationWithoutTrapping() throws {
        let sourceURL = try SyntheticMediaGenerator.createWAV(
            durationSeconds: 1.0,
            sampleRate: 44100,
            channels: 1,
            directory: tempDirectory
        )

        XCTAssertThrowsError(
            try AudioTrimmer.trim(
                sourceURL: sourceURL,
                startTimeSeconds: 0.2,
                durationSeconds: -0.5,
                directory: tempDirectory
            )
        )

        XCTAssertThrowsError(
            try AudioTrimmer.trim(
                sourceURL: sourceURL,
                startTimeSeconds: 0.2,
                durationSeconds: 0.0,
                directory: tempDirectory
            )
        )
    }

    func testAudioBleeperInjectsTone() throws {
        let sourceURL = try SyntheticMediaGenerator.createWAV(
            durationSeconds: 1.0,
            sampleRate: 44100,
            channels: 1,
            frequency: 0.0, // silêncio inicial
            directory: tempDirectory
        )

        let bleepedURL = try AudioBleeper.bleep(
            sourceURL: sourceURL,
            timeRanges: [(start: 0.2, duration: 0.4)],
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: bleepedURL.path))
        XCTAssertTrue(bleepedURL.lastPathComponent.contains("-bleeped"))

        let file = try AVAudioFile(forReading: bleepedURL)
        let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))!
        try file.read(into: buffer)

        if let data = buffer.floatChannelData?[0] {
            // Em vez de 1 sample exato que pode cair no zero crossing de 1000Hz, checa o pico na janela de censura
            var maxWindowPeak: Float = 0.0
            let startSample = Int(0.25 * 44100)
            let endSample = Int(0.35 * 44100)
            for i in startSample..<endSample {
                maxWindowPeak = max(maxWindowPeak, abs(data[i]))
            }
            XCTAssertGreaterThan(maxWindowPeak, 0.4, "O pico na janela do bleep deve ser próximo de 0.5")
        }
    }
}
