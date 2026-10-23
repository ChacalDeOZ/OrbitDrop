import Foundation
import AVFoundation

public enum VideoSplitterError: LocalizedError, Sendable {
    case invalidSource(URL)
    case invalidPartsCount

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível carregar vídeo: \(url.lastPathComponent)"
        case .invalidPartsCount:
            return "Quantidade de partes para divisão deve ser maior que 1."
        }
    }
}

public enum VideoSplitter: Sendable {
    /// Divide um vídeo em N partes iguais.
    @discardableResult
    public static func split(
        sourceURL: URL,
        partsCount: Int,
        directory: URL? = nil
    ) async throws -> [URL] {
        guard partsCount > 1 else { throw VideoSplitterError.invalidPartsCount }

        let asset = AVURLAsset(url: sourceURL)
        let totalDuration = try await asset.load(.duration)
        let totalSeconds = CMTimeGetSeconds(totalDuration)

        let partDuration = totalSeconds / Double(partsCount)
        var outputURLs: [URL] = []

        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension.isEmpty ? "mp4" : sourceURL.pathExtension

        for i in 0..<partsCount {
            let start = Double(i) * partDuration
            let partNumber = String(format: "%03d", i + 1)
            let partName = "\(rawBaseName)-part-\(partNumber).\(ext)"
            let targetURL = baseDir.appendingPathComponent(partName)

            let trimmed = try await VideoTrimmer.trim(
                sourceURL: sourceURL,
                startTimeSeconds: start,
                durationSeconds: partDuration,
                directory: baseDir
            )

            // Renomeia o -trimmed para o nome padronizado -part-001
            if trimmed != targetURL {
                if FileManager.default.fileExists(atPath: targetURL.path) {
                    try? FileManager.default.removeItem(at: targetURL)
                }
                try FileManager.default.moveItem(at: trimmed, to: targetURL)
                outputURLs.append(targetURL)
            } else {
                outputURLs.append(trimmed)
            }
        }

        return outputURLs
    }
}
