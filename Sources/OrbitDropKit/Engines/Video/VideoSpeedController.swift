import Foundation
import AVFoundation

public enum VideoSpeedError: LocalizedError, Sendable {
    case invalidSource(URL)
    case invalidSpeedFactor
    case exportFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível carregar vídeo: \(url.lastPathComponent)"
        case .invalidSpeedFactor:
            return "Fator de velocidade deve ser maior que zero."
        case .exportFailed(let reason):
            return "Falha ao alterar velocidade do vídeo: \(reason)"
        }
    }
}

public enum VideoSpeedController: Sendable {
    /// Altera a velocidade de reprodução do vídeo e áudio (0.25x até 4.0x) com preservação de pitch.
    @discardableResult
    public static func changeSpeed(
        sourceURL: URL,
        speedFactor: Double,
        directory: URL? = nil
    ) async throws -> URL {
        guard speedFactor > 0.05 && speedFactor <= 8.0 else {
            throw VideoSpeedError.invalidSpeedFactor
        }

        let asset = AVURLAsset(url: sourceURL)
        let totalDuration = try await asset.load(.duration)
        let timeRange = CMTimeRange(start: .zero, duration: totalDuration)
        let scaledDuration = CMTimeMultiplyByFloat64(totalDuration, multiplier: 1.0 / speedFactor)

        let composition = AVMutableComposition()

        // 1. Trilha de vídeo
        if let videoTrack = try? await asset.loadTracks(withMediaType: .video).first,
           let compVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try compVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
            compVideoTrack.scaleTimeRange(timeRange, toDuration: scaledDuration)
            compVideoTrack.preferredTransform = try await videoTrack.load(.preferredTransform)
        }

        // 2. Trilha de áudio (se houver) com ajuste para discrepâncias de duração AAC
        if let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first,
           let compAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            let trackDur = (try? await audioTrack.load(.timeRange).duration) ?? totalDuration
            let validDuration = min(totalDuration, trackDur)
            let audioTimeRange = CMTimeRange(start: .zero, duration: validDuration)
            let scaledAudioDuration = CMTimeMultiplyByFloat64(validDuration, multiplier: 1.0 / speedFactor)
            try? compAudioTrack.insertTimeRange(audioTimeRange, of: audioTrack, at: .zero)
            compAudioTrack.scaleTimeRange(audioTimeRange, toDuration: scaledAudioDuration)
        }

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw VideoSpeedError.exportFailed("Falha ao inicializar sessão de exportação")
        }
        exportSession.audioTimePitchAlgorithm = .spectral

        let cleanExt = sourceURL.pathExtension.isEmpty ? "mp4" : sourceURL.pathExtension.lowercased()
        let fileType: AVFileType = (cleanExt == "mov") ? .mov : .mp4

        let destinationURL = destinationSpeedURL(for: sourceURL, speedFactor: speedFactor, directory: directory)

        return try await OutputWriter.withStagingFileAsync(targetURL: destinationURL) { stagingURL in
            exportSession.outputURL = stagingURL
            exportSession.outputFileType = fileType

            await exportSession.export()
            if exportSession.status != .completed {
                let msg = exportSession.error?.localizedDescription ?? "Status inválido"
                throw VideoSpeedError.exportFailed(msg)
            }
        }
    }

    private static func destinationSpeedURL(for sourceURL: URL, speedFactor: Double, directory: URL?) -> URL {
        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension.isEmpty ? "mp4" : sourceURL.pathExtension
        let factorTag = String(format: "%.1f", speedFactor)
        let candidateName = "\(rawBaseName)-speed-\(factorTag)x.\(ext)"
        var candidateURL = baseDir.appendingPathComponent(candidateName)

        let fm = FileManager.default
        if !fm.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        var counter = 2
        while true {
            let nextName = "\(rawBaseName)-speed-\(factorTag)x-\(counter).\(ext)"
            candidateURL = baseDir.appendingPathComponent(nextName)
            if !fm.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }
}
