import Foundation
import AVFoundation

public enum AudioBleeperError: LocalizedError, Sendable {
    case invalidSource(URL)
    case bleepFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível abrir arquivo para censura: \(url.lastPathComponent)"
        case .bleepFailed(let reason):
            return "Falha ao aplicar censura em áudio: \(reason)"
        }
    }
}

public enum AudioBleeper: Sendable {
    /// Injeta tom senoidal suave de 1000 Hz nos trechos indicados em timeRanges.
    @discardableResult
    public static func bleep(
        sourceURL: URL,
        timeRanges: [(start: Double, duration: Double)],
        bleepFrequency: Float = 1000.0,
        directory: URL? = nil
    ) throws -> URL {
        guard let sourceFile = try? AVAudioFile(forReading: sourceURL) else {
            throw AudioBleeperError.invalidSource(sourceURL)
        }

        let format = sourceFile.processingFormat
        let sampleRate = Float(format.sampleRate)
        let totalFrames = Int(sourceFile.length)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalFrames)) else {
            throw AudioBleeperError.bleepFailed("Falha ao alocar buffer")
        }
        try sourceFile.read(into: buffer)

        let channels = Int(format.channelCount)
        let fadeFrames = max(1, Int(0.005 * sampleRate)) // 5 ms fade

        if let data = buffer.floatChannelData {
            for range in timeRanges {
                let startFrame = max(0, min(totalFrames - 1, Int(Float(range.start) * sampleRate)))
                let endFrame = max(startFrame, min(totalFrames, Int(Float(range.start + range.duration) * sampleRate)))
                let durationFrames = endFrame - startFrame

                guard durationFrames > 0 else { continue }

                for f in 0..<durationFrames {
                    let globalFrame = startFrame + f
                    let t = Float(f) / sampleRate
                    var gain: Float = 1.0

                    // Fade-in inicial de 5ms
                    if f < fadeFrames {
                        gain = Float(f) / Float(fadeFrames)
                    }
                    // Fade-out final de 5ms
                    else if f > durationFrames - fadeFrames {
                        gain = Float(durationFrames - f) / Float(fadeFrames)
                    }

                    let bleepSample = sin(2.0 * .pi * bleepFrequency * t) * 0.5 * gain

                    for ch in 0..<channels {
                        data[ch][globalFrame] = bleepSample
                    }
                }
            }
        }

        let destinationURL = destinationBleepedURL(for: sourceURL, directory: directory)

        return try OutputWriter.withStagingFile(targetURL: destinationURL) { stagingURL in
            let outFile = try AVAudioFile(forWriting: stagingURL, settings: format.settings)
            try outFile.write(from: buffer)
        }
    }

    private static func destinationBleepedURL(for sourceURL: URL, directory: URL?) -> URL {
        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension.isEmpty ? "wav" : sourceURL.pathExtension
        let candidateName = "\(rawBaseName)-bleeped.\(ext)"
        var candidateURL = baseDir.appendingPathComponent(candidateName)

        let fm = FileManager.default
        if !fm.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        var counter = 2
        while true {
            let nextName = "\(rawBaseName)-bleeped-\(counter).\(ext)"
            candidateURL = baseDir.appendingPathComponent(nextName)
            if !fm.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }
}
