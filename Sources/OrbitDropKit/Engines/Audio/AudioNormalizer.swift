import Foundation
import AVFoundation

public enum AudioNormalizerError: LocalizedError, Sendable {
    case invalidSource(URL)
    case normalizationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível carregar áudio para normalização: \(url.lastPathComponent)"
        case .normalizationFailed(let reason):
            return "Falha na normalização de áudio: \(reason)"
        }
    }
}

public enum AudioNormalizer: Sendable {
    /// Normaliza o volume de um arquivo de áudio ajustando o pico para targetPeakDBFS (padrão -1.0 dBFS).
    @discardableResult
    public static func normalize(
        sourceURL: URL,
        targetPeakDBFS: Float = -1.0,
        directory: URL? = nil
    ) throws -> URL {
        guard let sourceFile = try? AVAudioFile(forReading: sourceURL) else {
            throw AudioNormalizerError.invalidSource(sourceURL)
        }

        let format = sourceFile.processingFormat
        let frameCount = AVAudioFrameCount(sourceFile.length)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw AudioNormalizerError.normalizationFailed("Falha ao alocar buffer de áudio")
        }
        try sourceFile.read(into: buffer)

        let channels = Int(format.channelCount)
        let frames = Int(buffer.frameLength)

        var currentMaxPeak: Float = 0.0
        if let data = buffer.floatChannelData {
            for ch in 0..<channels {
                for f in 0..<frames {
                    let mag = abs(data[ch][f])
                    if mag > currentMaxPeak {
                        currentMaxPeak = mag
                    }
                }
            }
        }

        // Se for silêncio absoluto ou quase zero, preserva sem alterar
        if currentMaxPeak > 0.0001 {
            let targetLinear = pow(10.0, targetPeakDBFS / 20.0)
            let gain = targetLinear / currentMaxPeak

            if let data = buffer.floatChannelData {
                for ch in 0..<channels {
                    for f in 0..<frames {
                        // Multiplica com clamp de segurança em 1.0 para evitar clipping
                        data[ch][f] = max(-1.0, min(1.0, data[ch][f] * gain))
                    }
                }
            }
        }

        let destinationURL = destinationNormalizedURL(for: sourceURL, directory: directory)

        return try OutputWriter.withStagingFile(targetURL: destinationURL) { stagingURL in
            let outFile = try AVAudioFile(forWriting: stagingURL, settings: format.settings)
            try outFile.write(from: buffer)
        }
    }

    private static func destinationNormalizedURL(for sourceURL: URL, directory: URL?) -> URL {
        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension.isEmpty ? "wav" : sourceURL.pathExtension
        let candidateName = "\(rawBaseName)-normalized.\(ext)"
        var candidateURL = baseDir.appendingPathComponent(candidateName)

        let fm = FileManager.default
        if !fm.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        var counter = 2
        while true {
            let nextName = "\(rawBaseName)-normalized-\(counter).\(ext)"
            candidateURL = baseDir.appendingPathComponent(nextName)
            if !fm.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }
}
