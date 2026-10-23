import Foundation
import AppKit

public enum CopyPathAction: Sendable {
    /// Formata uma lista de URLs como caminhos de sistema limpos em UTF-8, um por linha.
    public static func formatPaths(urls: [URL]) -> String {
        urls.map { $0.path }.joined(separator: "\n")
    }

    /// Copia a representação em texto dos caminhos para a área de transferência.
    @MainActor
    public static func execute(urls: [URL]) {
        let text = formatPaths(urls: urls)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
