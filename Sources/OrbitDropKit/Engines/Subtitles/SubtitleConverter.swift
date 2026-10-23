import Foundation

public enum SubtitleFormat: String, Sendable {
    case srt
    case vtt
}

public enum SubtitleError: LocalizedError, Sendable {
    case invalidSource(URL)
    case conversionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível carregar arquivo de legenda: \(url.lastPathComponent)"
        case .conversionFailed(let reason):
            return "Falha na conversão de legenda: \(reason)"
        }
    }
}

public enum SubtitleConverter: Sendable {
    /// Converte legendas bidirecionalmente entre SRT e VTT com resolução de colisões e timestamps seguros.
    @discardableResult
    public static func convert(
        sourceURL: URL,
        targetFormat: SubtitleFormat,
        directory: URL? = nil
    ) throws -> URL {
        guard let data = try? Data(contentsOf: sourceURL),
              let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            throw SubtitleError.invalidSource(sourceURL)
        }

        let normalizedContent = content.replacingOccurrences(of: "\r\n", with: "\n")
        let convertedText: String

        switch targetFormat {
        case .vtt:
            convertedText = srtToVTT(normalizedContent)
        case .srt:
            convertedText = vttToSRT(normalizedContent)
        }

        let destinationURL = OutputWriter.destinationURL(
            for: sourceURL,
            targetExtension: targetFormat.rawValue,
            directory: directory
        )

        return try OutputWriter.withStagingFile(targetURL: destinationURL) { stagingURL in
            try convertedText.write(to: stagingURL, atomically: true, encoding: .utf8)
        }
    }

    private static func srtToVTT(_ srt: String) -> String {
        let lines = srt.components(separatedBy: "\n")
        var resultLines: [String] = []

        let timestampRegex = try? NSRegularExpression(pattern: #"(\d{2}:\d{2}:\d{2}),(\d{3})\s*-->\s*(\d{2}:\d{2}:\d{2}),(\d{3})"#)

        for line in lines {
            if let regex = timestampRegex,
               let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                let converted = regex.stringByReplacingMatches(in: line, options: [], range: match.range, withTemplate: "$1.$2 --> $3.$4")
                resultLines.append(converted)
            } else {
                resultLines.append(line)
            }
        }

        return "WEBVTT\n\n" + resultLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
    }

    private static func vttToSRT(_ vtt: String) -> String {
        let lines = vtt.components(separatedBy: "\n")
        var cleanedLines: [String] = []
        let timestampRegex = try? NSRegularExpression(pattern: #"(\d{2}:)?(\d{2}:\d{2})\.(\d{3})\s*-->\s*(\d{2}:)?(\d{2}:\d{2})\.(\d{3})"#)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("WEBVTT") || trimmed.hasPrefix("NOTE") {
                continue
            }

            if let regex = timestampRegex,
               let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                // Remove qualquer cue settings após o segundo timestamp (ex: position:50%)
                let rawMatch = (line as NSString).substring(with: match.range)
                let parts = rawMatch.components(separatedBy: "-->").map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count == 2 {
                    let s1 = normalizeSRTTimestamp(parts[0])
                    let s2 = normalizeSRTTimestamp(parts[1])
                    cleanedLines.append("\(s1) --> \(s2)")
                } else {
                    cleanedLines.append(line)
                }
            } else {
                cleanedLines.append(line)
            }
        }

        return cleanedLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
    }

    private static func normalizeSRTTimestamp(_ ts: String) -> String {
        // Assegura formato HH:MM:SS,mmm
        var clean = ts.replacingOccurrences(of: ".", with: ",")
        let colons = clean.filter { $0 == ":" }.count
        if colons == 1 {
            clean = "00:" + clean
        }
        return clean
    }
}
