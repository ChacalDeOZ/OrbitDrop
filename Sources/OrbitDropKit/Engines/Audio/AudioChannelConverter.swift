import Foundation
import AVFoundation

public enum AudioChannelError: LocalizedError, Sendable {
    case invalidSource(URL)
    case conversionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível carregar arquivo de áudio: \(url.lastPathComponent)"
        case .conversionFailed(let reason):
            return "Falha na conversão de canais: \(reason)"
        }
    }
}

public enum AudioChannelConverter: Sendable {
    /// Converte arquivo de áudio para mono (1 canal) ou estéreo (2 canais).
    @discardableResult
    public static func convertChannels(
        sourceURL: URL,
        targetChannels: UInt32,
        directory: URL? = nil
    ) throws -> URL {
        guard targetChannels == 1 || targetChannels == 2 else {
            throw AudioChannelError.conversionFailed("Target channels must be 1 (mono) or 2 (stereo)")
        }

        guard let sourceFile = try? AVAudioFile(forReading: sourceURL) else {
            throw AudioChannelError.invalidSource(sourceURL)
        }

        let sourceFormat = sourceFile.processingFormat
        let frameCount = AVAudioFrameCount(sourceFile.length)

        guard let sourceBuffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: frameCount) else {
            throw AudioChannelError.conversionFailed("Falha ao alocar buffer de entrada")
        }
        try sourceFile.read(into: sourceBuffer)

        guard let targetFormat = AVAudioFormat(
            commonFormat: sourceFormat.commonFormat,
            sampleRate: sourceFormat.sampleRate,
            channels: targetChannels,
            interleaved: false
        ) else {
            throw AudioChannelError.conversionFailed("Formato de destino inválido")
        }

        guard let targetBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCount) else {
            throw AudioChannelError.conversionFailed("Falha ao alocar buffer de saída")
        }
        targetBuffer.frameLength = frameCount

        let frames = Int(frameCount)
        let sourceChannels = Int(sourceFormat.channelCount)

        // Processamento de canais Float32
        if let srcData = sourceBuffer.floatChannelData, let dstData = targetBuffer.floatChannelData {
            if targetChannels == 1 {
                // Downmix para mono: média dos canais de entrada
                for f in 0..<frames {
                    var sum: Float = 0
                    for ch in 0..<sourceChannels {
                        sum += srcData[ch][f]
                    }
                    dstData[0][f] = sum / Float(sourceChannels)
                }
            } else if targetChannels == 2 {
                if sourceChannels == 1 {
                    // Upmix de mono para estéreo: duplica o canal
                    for f in 0..<frames {
                        let sample = srcData[0][f]
                        dstData[0][f] = sample
                        dstData[1][f] = sample
                    }
                } else if sourceChannels >= 2 {
                    // Já é estéreo ou mais: copia primeiros 2 canais
                    for f in 0..<frames {
                        dstData[0][f] = srcData[0][f]
                        dstData[1][f] = srcData[1][f]
                    }
                }
            }
        }

        let suffix = targetChannels == 1 ? "mono" : "stereo"
        let destinationURL = destinationAudioURL(for: sourceURL, suffix: suffix, directory: directory)

        return try OutputWriter.withStagingFile(targetURL: destinationURL) { stagingURL in
            let outFile = try AVAudioFile(forWriting: stagingURL, settings: targetFormat.settings)
            try outFile.write(from: targetBuffer)
        }
    }

    private static func destinationAudioURL(for sourceURL: URL, suffix: String, directory: URL?) -> URL {
        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension.isEmpty ? "wav" : sourceURL.pathExtension
        let candidateName = "\(rawBaseName)-\(suffix).\(ext)"
        var candidateURL = baseDir.appendingPathComponent(candidateName)

        let fm = FileManager.default
        if !fm.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        var counter = 2
        while true {
            let nextName = "\(rawBaseName)-\(suffix)-\(counter).\(ext)"
            candidateURL = baseDir.appendingPathComponent(nextName)
            if !fm.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }
}
