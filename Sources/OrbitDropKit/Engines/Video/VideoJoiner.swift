import Foundation
import AVFoundation

public enum VideoJoinerError: LocalizedError, Sendable {
    case emptySources
    case invalidSource(URL)
    case exportFailed(String)

    public var errorDescription: String? {
        switch self {
        case .emptySources:
            return "Nenhum clipe de vídeo informado para junção."
        case .invalidSource(let url):
            return "Não foi possível carregar vídeo: \(url.lastPathComponent)"
        case .exportFailed(let reason):
            return "Falha na junção de vídeos: \(reason)"
        }
    }
}

public enum VideoJoiner: Sendable {
    /// Concatena múltiplos clipes de vídeo em um único arquivo MP4.
    @discardableResult
    public static func join(
        sources: [URL],
        directory: URL? = nil
    ) async throws -> URL {
        guard !sources.isEmpty else { throw VideoJoinerError.emptySources }

        let composition = AVMutableComposition()
        guard let compVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw VideoJoinerError.exportFailed("Falha ao criar trilha de vídeo na composição")
        }

        var compAudioTrack: AVMutableCompositionTrack?
        var currentTime: CMTime = .zero

        for url in sources {
            let asset = AVURLAsset(url: url)
            let assetDuration = try await asset.load(.duration)
            let timeRange = CMTimeRange(start: .zero, duration: assetDuration)

            if let videoTrack = try? await asset.loadTracks(withMediaType: .video).first {
                try compVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: currentTime)
                if currentTime == .zero {
                    compVideoTrack.preferredTransform = try await videoTrack.load(.preferredTransform)
                }
            }

            if let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first {
                if compAudioTrack == nil {
                    compAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                }
                if let audioComp = compAudioTrack {
                    let currentAudioEnd = audioComp.timeRange.duration
                    if CMTimeCompare(currentTime, currentAudioEnd) > 0 {
                        let gap = CMTimeSubtract(currentTime, currentAudioEnd)
                        audioComp.insertEmptyTimeRange(CMTimeRange(start: currentAudioEnd, duration: gap))
                    }
                    let trackDur = (try? await audioTrack.load(.timeRange).duration) ?? assetDuration
                    let validRange = CMTimeRange(start: .zero, duration: min(assetDuration, trackDur))
                    try? audioComp.insertTimeRange(validRange, of: audioTrack, at: currentTime)
                }
            }

            currentTime = CMTimeAdd(currentTime, assetDuration)
        }

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw VideoJoinerError.exportFailed("Falha ao criar sessão de exportação")
        }

        let firstURL = sources[0]
        let destinationURL = destinationJoinedURL(for: firstURL, directory: directory)

        return try await OutputWriter.withStagingFileAsync(targetURL: destinationURL) { stagingURL in
            exportSession.outputURL = stagingURL
            exportSession.outputFileType = .mp4

            await exportSession.export()
            if exportSession.status != .completed {
                let msg = exportSession.error?.localizedDescription ?? "Status inválido"
                throw VideoJoinerError.exportFailed(msg)
            }
        }
    }

    private static func destinationJoinedURL(for sourceURL: URL, directory: URL?) -> URL {
        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let candidateName = "\(rawBaseName)-joined.mp4"
        var candidateURL = baseDir.appendingPathComponent(candidateName)

        let fm = FileManager.default
        if !fm.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        var counter = 2
        while true {
            let nextName = "\(rawBaseName)-joined-\(counter).mp4"
            candidateURL = baseDir.appendingPathComponent(nextName)
            if !fm.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }
}
