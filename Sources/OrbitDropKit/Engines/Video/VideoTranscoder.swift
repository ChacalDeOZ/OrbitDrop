import Foundation
import AVFoundation

public enum VideoTranscoderError: LocalizedError, Sendable {
    case invalidSource(URL)
    case unsupportedTarget(String)
    case exportSessionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível carregar vídeo: \(url.lastPathComponent)"
        case .unsupportedTarget(let ext):
            return "Formato de vídeo não suportado: .\(ext)"
        case .exportSessionFailed(let reason):
            return "Falha na transcodificação de vídeo: \(reason)"
        }
    }
}

public enum VideoTranscoder: Sendable {
    /// Converte um arquivo de vídeo entre MP4 e MOV utilizando AVAssetExportSession.
    @discardableResult
    public static func transcode(
        sourceURL: URL,
        targetExtension: String,
        directory: URL? = nil
    ) async throws -> URL {
        let asset = AVURLAsset(url: sourceURL)
        let cleanExt = targetExtension.trimmingCharacters(in: CharacterSet(charactersIn: ".")).lowercased()

        let fileType: AVFileType
        switch cleanExt {
        case "mp4":
            fileType = .mp4
        case "mov":
            fileType = .mov
        default:
            throw VideoTranscoderError.unsupportedTarget(cleanExt)
        }

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw VideoTranscoderError.exportSessionFailed("Não foi possível inicializar AVAssetExportSession")
        }

        let destinationURL = OutputWriter.destinationURL(for: sourceURL, targetExtension: cleanExt, directory: directory)

        return try await OutputWriter.withStagingFileAsync(targetURL: destinationURL) { stagingURL in
            exportSession.outputURL = stagingURL
            exportSession.outputFileType = fileType

            await exportSession.export()
            if exportSession.status != .completed {
                let msg = exportSession.error?.localizedDescription ?? "Status final inválido"
                throw VideoTranscoderError.exportSessionFailed(msg)
            }
        }
    }

    /// Extrai a trilha de áudio de um arquivo de vídeo para M4A.
    @discardableResult
    public static func extractAudio(
        sourceURL: URL,
        directory: URL? = nil
    ) async throws -> URL {
        let asset = AVURLAsset(url: sourceURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw VideoTranscoderError.exportSessionFailed("Falha ao criar sessão para extração de áudio M4A")
        }

        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let destinationURL = baseDir.appendingPathComponent("\(rawBaseName)-audio.m4a")

        return try await OutputWriter.withStagingFileAsync(targetURL: destinationURL) { stagingURL in
            exportSession.outputURL = stagingURL
            exportSession.outputFileType = .m4a

            await exportSession.export()
            if exportSession.status != .completed {
                let msg = exportSession.error?.localizedDescription ?? "Falha ao extrair áudio"
                throw VideoTranscoderError.exportSessionFailed(msg)
            }
        }
    }
}
