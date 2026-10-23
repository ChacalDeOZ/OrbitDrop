import Foundation
import AVFoundation
import CoreGraphics

public enum AudioVisualizerError: LocalizedError, Sendable {
    case invalidSource(URL)
    case writerCreationFailed
    case compositionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível carregar arquivo de áudio: \(url.lastPathComponent)"
        case .writerCreationFailed:
            return "Falha ao inicializar o gravador de vídeo do visualizer."
        case .compositionFailed(let reason):
            return "Falha ao compor áudio com o vídeo do visualizer: \(reason)"
        }
    }
}

public enum AudioVisualizer: Sendable {
    /// Gera um clipe de vídeo MP4 contendo a representação de forma de onda animada e a trilha de áudio original.
    @discardableResult
    public static func createVisualizerVideo(
        audioURL: URL,
        outputDirectory: URL? = nil,
        width: Int = 320,
        height: Int = 240,
        fps: Int32 = 15
    ) async throws -> URL {
        guard let audioFile = try? AVAudioFile(forReading: audioURL) else {
            throw AudioVisualizerError.invalidSource(audioURL)
        }

        let format = audioFile.processingFormat
        let sampleRate = format.sampleRate
        let totalFrames = audioFile.length
        guard totalFrames > 0 else {
            throw AudioVisualizerError.invalidSource(audioURL)
        }
        let durationSeconds = Double(totalFrames) / sampleRate

        // 1. Ler amostras de áudio para análise de amplitude
        guard let readBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalFrames)) else {
            throw AudioVisualizerError.writerCreationFailed
        }
        try audioFile.read(into: readBuffer)
        let channelData = readBuffer.floatChannelData?[0]

        // 2. Criar vídeo temporário com a animação
        let tempVideoURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_vis_\(UUID().uuidString).mp4")
        defer { try? FileManager.default.removeItem(at: tempVideoURL) }

        let assetWriter = try AVAssetWriter(outputURL: tempVideoURL, fileType: .mp4)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ]
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        writerInput.expectsMediaDataInRealTime = false

        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: attributes)

        guard assetWriter.canAdd(writerInput) else {
            throw AudioVisualizerError.writerCreationFailed
        }
        assetWriter.add(writerInput)

        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)

        let totalVideoFrames = max(1, Int(durationSeconds * Double(fps)))
        let samplesPerVideoFrame = totalFrames > 0 ? Int(Double(totalFrames) / Double(totalVideoFrames)) : 1

        for frameIdx in 0..<totalVideoFrames {
            while !writerInput.isReadyForMoreMediaData {
                guard assetWriter.status != .failed && assetWriter.status != .cancelled else {
                    throw AudioVisualizerError.writerCreationFailed
                }
                try await Task.sleep(nanoseconds: 10_000_000)
            }

            var pixelBuffer: CVPixelBuffer?
            CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, nil, &pixelBuffer)

            if let buffer = pixelBuffer {
                CVPixelBufferLockBaseAddress(buffer, [])
                if let ptr = CVPixelBufferGetBaseAddress(buffer) {
                    let colorSpace = CGColorSpaceCreateDeviceRGB()
                    let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue
                    if let context = CGContext(
                        data: ptr,
                        width: width,
                        height: height,
                        bitsPerComponent: 8,
                        bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                        space: colorSpace,
                        bitmapInfo: bitmapInfo
                    ) {
                        // Fundo escuro elegante
                        context.setFillColor(CGColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0))
                        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

                        // Calcula amplitude do trecho correspondente ao frame com bounds seguros
                        var peak: CGFloat = 0.05
                        if let data = channelData {
                            let startSample = max(0, min(frameIdx * samplesPerVideoFrame, Int(totalFrames) - 1))
                            let endSample = max(startSample, min(startSample + samplesPerVideoFrame, Int(totalFrames)))
                            for s in startSample..<endSample {
                                peak = max(peak, CGFloat(abs(data[s])))
                            }
                        }

                        // Desenha barras de forma de onda
                        let barCount = 16
                        let barWidth = CGFloat(width) / CGFloat(barCount * 2)
                        context.setFillColor(CGColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1.0))

                        for b in 0..<barCount {
                            let factor = sin(CGFloat(b) / CGFloat(barCount) * .pi) * peak
                            let barHeight = max(6, factor * CGFloat(height) * 0.7)
                            let x = CGFloat(b * 2 + 1) * barWidth
                            let y = (CGFloat(height) - barHeight) / 2.0
                            context.fill(CGRect(x: x, y: y, width: barWidth * 0.8, height: barHeight))
                        }
                    }
                }
                CVPixelBufferUnlockBaseAddress(buffer, [])

                let time = CMTime(value: Int64(frameIdx), timescale: fps)
                adaptor.append(buffer, withPresentationTime: time)
            }
        }

        writerInput.markAsFinished()
        await assetWriter.finishWriting()

        // 3. Mescla o vídeo gerado com a trilha de áudio original
        let destinationURL = destinationVisualizerURL(for: audioURL, directory: outputDirectory)
        let composition = AVMutableComposition()

        let audioAsset = AVURLAsset(url: audioURL)
        let videoAsset = AVURLAsset(url: tempVideoURL)

        guard let videoTrack = try? await videoAsset.loadTracks(withMediaType: .video).first else {
            throw AudioVisualizerError.compositionFailed("Trilha de vídeo temporária ausente")
        }

        let compVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let timeRange = CMTimeRange(start: .zero, duration: try await videoAsset.load(.duration))
        try compVideoTrack?.insertTimeRange(timeRange, of: videoTrack, at: .zero)

        if let audioTrack = try? await audioAsset.loadTracks(withMediaType: .audio).first {
            let compAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            try compAudioTrack?.insertTimeRange(timeRange, of: audioTrack, at: .zero)
        }

        return try await OutputWriter.withStagingFileAsync(targetURL: destinationURL) { stagingURL in
            guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
                throw AudioVisualizerError.compositionFailed("Não foi possível criar AVAssetExportSession")
            }
            exportSession.outputURL = stagingURL
            exportSession.outputFileType = .mp4

            await exportSession.export()
            if exportSession.status != .completed {
                let msg = exportSession.error?.localizedDescription ?? "Erro de exportação desconhecido"
                throw AudioVisualizerError.compositionFailed(msg)
            }
        }
    }

    private static func destinationVisualizerURL(for sourceURL: URL, directory: URL?) -> URL {
        let baseDir = directory ?? sourceURL.deletingLastPathComponent()
        let rawBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let candidateName = "\(rawBaseName)-visualizer.mp4"
        var candidateURL = baseDir.appendingPathComponent(candidateName)

        let fm = FileManager.default
        if !fm.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        var counter = 2
        while true {
            let nextName = "\(rawBaseName)-visualizer-\(counter).mp4"
            candidateURL = baseDir.appendingPathComponent(nextName)
            if !fm.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }
}
