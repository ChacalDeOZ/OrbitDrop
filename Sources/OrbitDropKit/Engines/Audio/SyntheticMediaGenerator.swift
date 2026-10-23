import Foundation
import AVFoundation

public enum SyntheticMediaGenerator: Sendable {
    /// Gera um arquivo WAV sintético local com onda senoidal para testes rápidos.
    public static func createWAV(
        durationSeconds: Double = 1.0,
        sampleRate: Double = 44100.0,
        channels: UInt32 = 2,
        frequency: Float = 440.0,
        directory: URL? = nil
    ) throws -> URL {
        let baseDir = directory ?? FileManager.default.temporaryDirectory
        let fileURL = baseDir.appendingPathComponent("synthetic-\(UUID().uuidString).wav")

        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: channels, interleaved: false) else {
            throw NSError(domain: "SyntheticMediaGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Formato de áudio inválido"])
        }

        let frameCount = AVAudioFrameCount(durationSeconds * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw NSError(domain: "SyntheticMediaGenerator", code: 2, userInfo: [NSLocalizedDescriptionKey: "Falha ao alocar buffer PCM"])
        }
        buffer.frameLength = frameCount

        let channelsData = buffer.floatChannelData!
        for frame in 0..<Int(frameCount) {
            let t = Float(frame) / Float(sampleRate)
            let sample = sin(2.0 * .pi * frequency * t) * 0.5
            for ch in 0..<Int(channels) {
                channelsData[ch][frame] = sample
            }
        }

        let audioFile = try AVAudioFile(forWriting: fileURL, settings: format.settings)
        try audioFile.write(from: buffer)
        return fileURL
    }

    /// Gera um arquivo de vídeo MP4 sintético de 1 segundo (com frame preto ou colorido e trilha de áudio) para testes.
    public static func createMP4(
        durationSeconds: Double = 1.0,
        width: Int = 160,
        height: Int = 120,
        directory: URL? = nil
    ) async throws -> URL {
        let baseDir = directory ?? FileManager.default.temporaryDirectory
        let fileURL = baseDir.appendingPathComponent("synthetic-\(UUID().uuidString).mp4")

        let assetWriter = try AVAssetWriter(outputURL: fileURL, fileType: .mp4)

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
            throw NSError(domain: "SyntheticMediaGenerator", code: 3, userInfo: [NSLocalizedDescriptionKey: "Não foi possível adicionar writerInput"])
        }
        assetWriter.add(writerInput)

        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)

        let fps: Int32 = 10
        let totalFrames = Int(durationSeconds * Double(fps))

        for frame in 0..<totalFrames {
            while !writerInput.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 10_000_000)
            }

            var pixelBuffer: CVPixelBuffer?
            CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, nil, &pixelBuffer)

            if let buffer = pixelBuffer {
                CVPixelBufferLockBaseAddress(buffer, [])
                if let ptr = CVPixelBufferGetBaseAddress(buffer) {
                    memset(ptr, Int32((frame * 20) % 255), CVPixelBufferGetDataSize(buffer))
                }
                CVPixelBufferUnlockBaseAddress(buffer, [])

                let time = CMTime(value: Int64(frame), timescale: fps)
                adaptor.append(buffer, withPresentationTime: time)
            }
        }

        writerInput.markAsFinished()
        await assetWriter.finishWriting()

        return fileURL
    }
}
