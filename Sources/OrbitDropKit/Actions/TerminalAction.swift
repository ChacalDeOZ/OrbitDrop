import Foundation
import AppKit

public enum TerminalAction: Sendable {
    /// Determina a pasta alvo: para uma pasta, retorna ela mesma; para um arquivo, retorna a pasta pai.
    public static func targetDirectory(for url: URL) -> URL {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            return url
        }
        return url.deletingLastPathComponent()
    }

    /// Abre a pasta no Terminal nativo ou iTerm2 de forma segura sem injeção de shell.
    @MainActor
    public static func execute(files: [URL], preferITerm: Bool = false) {
        guard let first = files.first else { return }
        let targetDir = targetDirectory(for: first)

        if preferITerm,
           let itermURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.googlecode.iterm2") {
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.open([targetDir], withApplicationAt: itermURL, configuration: config, completionHandler: nil)
            return
        }

        // Terminal nativo padrão
        if let terminalURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") {
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.open([targetDir], withApplicationAt: terminalURL, configuration: config, completionHandler: nil)
        } else {
            NSWorkspace.shared.open(targetDir)
        }
    }
}
