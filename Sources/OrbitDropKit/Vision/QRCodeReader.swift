import Foundation
import CoreGraphics
import ImageIO
import Vision

public enum QRCodeReaderError: LocalizedError, Sendable {
    case invalidSource(URL)

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível carregar a imagem para leitura de QR code: \(url.lastPathComponent)"
        }
    }
}

public enum QRCodeReader: Sendable {
    /// Lê todos os QR codes de uma imagem localmente via Vision framework.
    public static func read(from sourceURL: URL) async throws -> [String] {
        guard let sourceRef = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(sourceRef, 0, nil) else {
            throw QRCodeReaderError.invalidSource(sourceURL)
        }

        return try await Task.detached(priority: .userInitiated) {
            let request = VNDetectBarcodesRequest()
            request.symbologies = [.qr]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])

            return (request.results ?? []).compactMap { observation in
                observation.payloadStringValue
            }
        }.value
    }
}
