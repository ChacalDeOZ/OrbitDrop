import Foundation
import AppKit

public enum CopyAction: Sendable {
    /// Copia as URLs dos arquivos para a área de transferência do sistema (NSPasteboard.general)
    /// no formato de arquivos do Finder, permitindo que o usuário dê Cmd+V no Finder para colar.
    @MainActor
    public static func execute(urls: [URL]) {
        guard !urls.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects(urls as [NSURL])
    }
}
