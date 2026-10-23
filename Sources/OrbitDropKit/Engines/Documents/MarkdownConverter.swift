import Foundation

public enum MarkdownConverterError: LocalizedError, Sendable {
    case invalidSource(URL)
    case conversionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let url):
            return "Não foi possível carregar arquivo para conversão em Markdown: \(url.lastPathComponent)"
        case .conversionFailed(let reason):
            return "Falha na conversão para Markdown: \(reason)"
        }
    }
}

public enum MarkdownConverter: Sendable {
    /// Converte arquivos de texto, código, HTML ou RTF para Markdown estruturado.
    @discardableResult
    public static func convertToMarkdown(
        sourceURL: URL,
        directory: URL? = nil
    ) throws -> URL {
        guard let data = try? Data(contentsOf: sourceURL) else {
            throw MarkdownConverterError.invalidSource(sourceURL)
        }

        let ext = sourceURL.pathExtension.lowercased()
        let markdownContent: String

        switch ext {
        case "html", "htm":
            let rawHTML = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
            markdownContent = htmlToMarkdown(rawHTML, title: sourceURL.deletingPathExtension().lastPathComponent)

        case "rtf":
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/textutil")
            process.arguments = ["-convert", "txt", "-stdout", sourceURL.path]
            let pipe = Pipe()
            process.standardOutput = pipe
            try? process.run()
            process.waitUntilExit()
            let outData = pipe.fileHandleForReading.readDataToEndOfFile()
            let plainText = String(data: outData, encoding: .utf8) ?? ""
            markdownContent = "# \(sourceURL.deletingPathExtension().lastPathComponent)\n\n" + plainText

        case "json":
            let jsonString = String(data: data, encoding: .utf8) ?? ""
            markdownContent = "# \(sourceURL.lastPathComponent)\n\n```json\n\(jsonString)\n```"

        case "swift", "py", "js", "ts", "sh", "c", "cpp", "h", "rs", "go":
            let code = String(data: data, encoding: .utf8) ?? ""
            markdownContent = "# \(sourceURL.lastPathComponent)\n\n```\(ext)\n\(code)\n```"

        default:
            // Arquivo de texto puro / genérico
            let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
            markdownContent = "# \(sourceURL.deletingPathExtension().lastPathComponent)\n\n" + text
        }

        let destinationURL = OutputWriter.destinationURL(for: sourceURL, targetExtension: "md", directory: directory)

        return try OutputWriter.withStagingFile(targetURL: destinationURL) { stagingURL in
            try markdownContent.write(to: stagingURL, atomically: true, encoding: .utf8)
        }
    }

    private static func htmlToMarkdown(_ html: String, title: String) -> String {
        var text = html
        // Substituições de tags básicas de HTML para Markdown
        text = text.replacingOccurrences(of: "<h1[^>]*>(.*?)</h1>", with: "# $1\n\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "<h2[^>]*>(.*?)</h2>", with: "## $1\n\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "<h3[^>]*>(.*?)</h3>", with: "### $1\n\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "<p[^>]*>(.*?)</p>", with: "$1\n\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "<strong[^>]*>(.*?)</strong>", with: "**$1**", options: .regularExpression)
        text = text.replacingOccurrences(of: "<b[^>]*>(.*?)</b>", with: "**$1**", options: .regularExpression)
        text = text.replacingOccurrences(of: "<em[^>]*>(.*?)</em>", with: "*$1*", options: .regularExpression)
        text = text.replacingOccurrences(of: "<i[^>]*>(.*?)</i>", with: "*$1*", options: .regularExpression)
        text = text.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "<li[^>]*>(.*?)</li>", with: "- $1\n", options: .regularExpression)
        // Remove tags restantes
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        // Decodificar entidades HTML comuns
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        return "# \(title)\n\n" + text.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
    }
}
