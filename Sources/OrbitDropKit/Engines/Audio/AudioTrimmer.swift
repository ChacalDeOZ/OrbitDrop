import Foundation
import AVFoundation

public enum AudioTrimmerError: LocalizedError, Sendable {
    case invalidSource(URL)
    case invalidTimeRange
    case trimmingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível abrir arquivo de áudio para corte: \(url.lastPathComponent)"
        case .invalidTimeRange:
            return "Intervalo de tempo inválido para corte de áudio."
        case .trimmingFailed(let reason):
            return "Falha no corte de áudio: \(reason)"
        }
    }
}

public enum AudioTrimmer: Sendable {
    /// Corta um arquivo de áudio extraindo o segmento a partir de startTimeSeconds com durationSeconds.
    @discardableResult
    public static func trim(
        sourceURL: URL,
        startTimeSeconds: Double,
        durationSeconds: Double,
        directory: URL? = nil
    ) throws -> URL {
        guard durationSeconds > 0, durationSeconds.isFinite,
              startTimeSeconds >= 0, startTimeSeconds.isFinite else {
            throw AudioTrimmerError.invalidTimeRange
        }

        guard let sourceFile = try? AVAudioFile(forReading: sourceURL) else {
            throw AudioTrimmerError.invalidSource(sourceURL)
        }

        let format = sourceFile.processingFormat
        let sampleRate = format.sampleRate
        let totalLength = sourceFile.length

        let startFrame = Int64(startTimeSeconds * sampleRate)
        guard startFrame >= 0 && startFrame < totalLength else {
            throw AudioTrimmerError.invalidTimeRange
        }

        sourceFile.framePosition = startFrame

        let maxAvailableFrames = totalLength - startFrame
        let desiredFrames = Int64(durationSeconds * sampleRate)
        let framesToRead = AVAudioFrameCount(min(maxAvailableFrames, desiredFrames))

        guard framesToRead > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: framesToRead) else {
            throw AudioTrimmerError.trimmingFailed("Falha ao alocar buffer de corte")
        }

        try sourceFile.read(into: buffer, frameCount: framesToRead)

        let destinationURL = destinationTrimmedURL(for: sourceURL, directory: directory)

        return try OutputWriter.withStagingFile(targetURL: destinationURL) { stagingURL in
            let outFile = try AVAudioFile(forWriting: stagingURL, settings: format.settings)
            try outFile.write(from: buffer)
        }
    }

    private static func destinationTrimmedURL(for sourceURL: URL, directory: URL?) -> URL {
        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension.isEmpty ? "wav" : sourceURL.pathExtension
        let candidateName = "\(rawBaseName)-trimmed.\(ext)"
        var candidateURL = baseDir.appendingPathComponent(candidateName)

        let fm = FileManager.default
        if !fm.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        var counter = 2
        while true {
            let nextName = "\(rawBaseName)-trimmed-\(counter).\(ext)"
            candidateURL = baseDir.appendingPathComponent(nextName)
            if !fm.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }
}
