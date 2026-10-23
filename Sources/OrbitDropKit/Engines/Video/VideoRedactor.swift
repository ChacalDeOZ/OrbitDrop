import Foundation
import AVFoundation
import CoreGraphics
import QuartzCore

public enum VideoRedactorError: LocalizedError, Sendable {
    case invalidSource(URL)
    case exportFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível carregar vídeo: \(url.lastPathComponent)"
        case .exportFailed(let reason):
            return "Falha ao exportar vídeo redigido: \(reason)"
        }
    }
}

public enum VideoRedactor: Sendable {
    /// Queima tarjas pretas sólidas nas regiões indicadas ao longo do vídeo.
    @discardableResult
    public static func redact(
        sourceURL: URL,
        regions: [CGRect],
        directory: URL? = nil
    ) async throws -> URL {
        let asset = AVURLAsset(url: sourceURL)
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            throw VideoRedactorError.invalidSource(sourceURL)
        }

        let assetDuration = try await asset.load(.duration)
        let naturalSize = try await videoTrack.load(.naturalSize)

        let composition = AVMutableComposition()
        guard let compVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw VideoRedactorError.exportFailed("Falha ao criar trilha de vídeo")
        }

        let timeRange = CMTimeRange(start: .zero, duration: assetDuration)
        try compVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)

        if let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first,
           let compAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try? compAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
        }

        let prefTransform = (try? await videoTrack.load(.preferredTransform)) ?? .identity
        let isTransposed = abs(prefTransform.b) > 0.5 && abs(prefTransform.c) > 0.5
        let renderWidth = isTransposed ? naturalSize.height : naturalSize.width
        let renderHeight = isTransposed ? naturalSize.width : naturalSize.height
        let displaySize = CGSize(width: renderWidth, height: renderHeight)

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = displaySize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = timeRange
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compVideoTrack)
        layerInstruction.setTransform(prefTransform, at: .zero)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        // Camadas de animação para sobreposição de tarjas pretas opacas
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: displaySize)
        videoLayer.frame = CGRect(origin: .zero, size: displaySize)
        parentLayer.addSublayer(videoLayer)

        for rect in regions {
            let blackBox = CALayer()
            blackBox.frame = rect
            blackBox.backgroundColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1.0)
            blackBox.opacity = 1.0
            parentLayer.addSublayer(blackBox)
        }

        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw VideoRedactorError.exportFailed("Falha ao criar sessão de exportação")
        }
        exportSession.videoComposition = videoComposition

        let destinationURL = destinationRedactedURL(for: sourceURL, directory: directory)

        return try await OutputWriter.withStagingFileAsync(targetURL: destinationURL) { stagingURL in
            exportSession.outputURL = stagingURL
            exportSession.outputFileType = .mp4

            await exportSession.export()
            if exportSession.status != .completed {
                let msg = exportSession.error?.localizedDescription ?? "Status inválido"
                throw VideoRedactorError.exportFailed(msg)
            }
        }
    }

    private static func destinationRedactedURL(for sourceURL: URL, directory: URL?) -> URL {
        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let candidateName = "\(rawBaseName)-redacted.mp4"
        var candidateURL = baseDir.appendingPathComponent(candidateName)

        let fm = FileManager.default
        if !fm.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        var counter = 2
        while true {
            let nextName = "\(rawBaseName)-redacted-\(counter).mp4"
            candidateURL = baseDir.appendingPathComponent(nextName)
            if !fm.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }
}
