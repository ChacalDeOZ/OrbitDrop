import Foundation
import AppKit

@MainActor
public enum DragPayloadProbe {
    /// Tenta ler URLs do pasteboard global de arrasto do AppKit enquanto Finder mantém sessão ativa.
    public static func currentFileURLs() -> [URL] {
        let dragPasteboard = NSPasteboard(name: .drag)
        return dragPasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true
        ]) as? [URL] ?? []
    }
}
