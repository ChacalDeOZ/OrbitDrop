import Foundation
import AVFoundation
import CoreGraphics

public enum VideoCropperError: LocalizedError, Sendable {
    case invalidSource(URL)
    case exportFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível carregar vídeo para corte: \(url.lastPathComponent)"
        case .exportFailed(let reason):
            return "Falha ao exportar corte de vídeo: \(reason)"
        }
    }
}

public enum VideoCropper: Sendable {
    /// Corta a região espacial de um vídeo aplicando transformação na composição de vídeo.
    @discardableResult
    public static func crop(
        sourceURL: URL,
        cropRect: CGRect,
        directory: URL? = nil
    ) async throws -> URL {
        let asset = AVURLAsset(url: sourceURL)
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            throw VideoCropperError.invalidSource(sourceURL)
        }

        let assetDuration = try await asset.load(.duration)
        let composition = AVMutableComposition()
        guard let compVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw VideoCropperError.exportFailed("Falha ao criar trilha de vídeo")
        }

        let timeRange = CMTimeRange(start: .zero, duration: assetDuration)
        try compVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)

        if let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first,
           let compAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try? compAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
        }

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: cropRect.width, height: cropRect.height)
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = timeRange

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compVideoTrack)
        let prefTransform = (try? await videoTrack.load(.preferredTransform)) ?? .identity
        let cropTransform = CGAffineTransform(translationX: -cropRect.origin.x, y: -cropRect.origin.y)
        let finalTransform = prefTransform.concatenating(cropTransform)
        layerInstruction.setTransform(finalTransform, at: .zero)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw VideoCropperError.exportFailed("Falha na sessão de exportação")
        }
        exportSession.videoComposition = videoComposition

        let destinationURL = destinationCroppedURL(for: sourceURL, directory: directory)

        return try await OutputWriter.withStagingFileAsync(targetURL: destinationURL) { stagingURL in
            exportSession.outputURL = stagingURL
            exportSession.outputFileType = .mp4

            await exportSession.export()
            if exportSession.status != .completed {
                let msg = exportSession.error?.localizedDescription ?? "Status inválido"
                throw VideoCropperError.exportFailed(msg)
            }
        }
    }

    private static func destinationCroppedURL(for sourceURL: URL, directory: URL?) -> URL {
        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let candidateName = "\(rawBaseName)-cropped.mp4"
        var candidateURL = baseDir.appendingPathComponent(candidateName)

        let fm = FileManager.default
        if !fm.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        var counter = 2
        while true {
            let nextName = "\(rawBaseName)-cropped-\(counter).mp4"
            candidateURL = baseDir.appendingPathComponent(nextName)
            if !fm.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }
}
