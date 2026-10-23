import Foundation
import CoreGraphics
import ImageIO
import Vision
import PDFKit

public enum OCRError: LocalizedError, Sendable {
    case invalidSource(URL)
    case processingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível carregar arquivo para OCR: \(url.lastPathComponent)"
        case .processingFailed(let reason):
            return "Falha no reconhecimento de texto (OCR): \(reason)"
        }
    }
}

public enum OCROutputFormat: String, Sendable {
    case plainText = "txt"
    case markdown = "md"
}

public enum OCRProcessor: Sendable {
    /// Executa reconhecimento óptico de caracteres (OCR) local via Apple Vision em Imagens ou PDFs.
    @discardableResult
    public static func recognizeText(
        sourceURL: URL,
        format: OCROutputFormat = .markdown,
        languages: [String] = ["pt-BR", "en-US"],
        directory: URL? = nil
    ) async throws -> URL {
        let ext = sourceURL.pathExtension.lowercased()
        let recognizedText: String

        if ext == "pdf" {
            recognizedText = try await processPDF(sourceURL: sourceURL, format: format, languages: languages)
        } else {
            recognizedText = try await processImage(sourceURL: sourceURL, format: format, languages: languages)
        }

        let destinationURL = OutputWriter.destinationURL(
            for: sourceURL,
            targetExtension: format.rawValue,
            directory: directory
        )

        return try OutputWriter.withStagingFile(targetURL: destinationURL) { stagingURL in
            try recognizedText.write(to: stagingURL, atomically: true, encoding: .utf8)
        }
    }

    private static func processImage(
        sourceURL: URL,
        format: OCROutputFormat,
        languages: [String]
    ) async throws -> String {
        guard let sourceRef = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(sourceRef, 0, nil) else {
            throw OCRError.invalidSource(sourceURL)
        }

        let orientationVal = (CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, nil) as? [CFString: Any])?[kCGImagePropertyOrientation] as? UInt32
        let cgOrientation = CGImagePropertyOrientation(rawValue: orientationVal ?? 1) ?? .up

        let text = try await performVisionOCR(on: cgImage, orientation: cgOrientation, languages: languages)
        let title = sourceURL.deletingPathExtension().lastPathComponent

        if format == .markdown {
            return "# OCR: \(title)\n\n" + (text.isEmpty ? "*(Nenhum texto identificado)*" : text) + "\n"
        } else {
            return text
        }
    }

    private static func processPDF(
        sourceURL: URL,
        format: OCROutputFormat,
        languages: [String]
    ) async throws -> String {
        guard let doc = PDFDocument(url: sourceURL) else {
            throw OCRError.invalidSource(sourceURL)
        }
        if doc.isLocked {
            throw OCRError.processingFailed("PDF protegido por senha.")
        }

        var pagesText: [String] = []

        for p in 0..<doc.pageCount {
            guard let page = doc.page(at: p) else { continue }
            let pageRect = page.bounds(for: .cropBox)
            let scale: CGFloat = 2.0
            let width = max(1, Int(ceil(pageRect.width * scale)))
            let height = max(1, Int(ceil(pageRect.height * scale)))

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            guard let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else { continue }

            context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            context.scaleBy(x: scale, y: scale)
            context.translateBy(x: -pageRect.origin.x, y: -pageRect.origin.y)
            page.draw(with: .cropBox, to: context)

            guard let pageImage = context.makeImage() else { continue }
            let pageText = try await performVisionOCR(on: pageImage, orientation: .up, languages: languages)

            if format == .markdown {
                pagesText.append("## Página \(p + 1)\n\n\(pageText)")
            } else {
                pagesText.append(pageText)
            }
        }

        let separator = (format == .markdown) ? "\n\n---\n\n" : "\n\n"
        return pagesText.joined(separator: separator)
    }

    private static func performVisionOCR(
        on image: CGImage,
        orientation: CGImagePropertyOrientation,
        languages: [String]
    ) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = languages

            let handler = VNImageRequestHandler(cgImage: image, orientation: orientation, options: [:])
            try handler.perform([request])

            let observations = request.results ?? []
            let sorted = observations.sorted { lhs, rhs in
                let verticalDelta = abs(lhs.boundingBox.midY - rhs.boundingBox.midY)
                if verticalDelta > 0.02 {
                    return lhs.boundingBox.midY > rhs.boundingBox.midY
                }
                return lhs.boundingBox.minX < rhs.boundingBox.minX
            }

            return sorted.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
        }.value
    }
}
