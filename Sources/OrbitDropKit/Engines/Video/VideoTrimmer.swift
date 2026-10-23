import Foundation
import AVFoundation

public enum VideoTrimmerError: LocalizedError, Sendable {
    case invalidSource(URL)
    case exportFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível abrir vídeo para corte: \(url.lastPathComponent)"
        case .exportFailed(let reason):
            return "Falha ao exportar vídeo cortado: \(reason)"
        }
    }
}

public enum VideoTrimmer: Sendable {
    /// Corta um trecho de vídeo entre startTimeSeconds e durationSeconds.
    @discardableResult
    public static func trim(
        sourceURL: URL,
        startTimeSeconds: Double,
        durationSeconds: Double,
        directory: URL? = nil
    ) async throws -> URL {
        let asset = AVURLAsset(url: sourceURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw VideoTrimmerError.exportFailed("Falha ao criar sessão de exportação")
        }

        let start = CMTime(seconds: startTimeSeconds, preferredTimescale: 600)
        let duration = CMTime(seconds: durationSeconds, preferredTimescale: 600)
        exportSession.timeRange = CMTimeRange(start: start, duration: duration)

        let cleanExt = sourceURL.pathExtension.isEmpty ? "mp4" : sourceURL.pathExtension.lowercased()
        let fileType: AVFileType = (cleanExt == "mov") ? .mov : .mp4

        let destinationURL = destinationTrimmedURL(for: sourceURL, directory: directory)

        return try await OutputWriter.withStagingFileAsync(targetURL: destinationURL) { stagingURL in
            exportSession.outputURL = stagingURL
            exportSession.outputFileType = fileType

            await exportSession.export()
            if exportSession.status != .completed {
                let msg = exportSession.error?.localizedDescription ?? "Status inválido"
                throw VideoTrimmerError.exportFailed(msg)
            }
        }
    }

    private static func destinationTrimmedURL(for sourceURL: URL, directory: URL?) -> URL {
        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension.isEmpty ? "mp4" : sourceURL.pathExtension
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
