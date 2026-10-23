import Foundation
import AppKit

public enum AirDropAction: Sendable {
    /// Verifica se há arquivos locais para compartilhamento via AirDrop.
    public static func canShare(files: [URL]) -> Bool {
        guard !files.isEmpty else { return false }
        return true
    }

    /// Executa o compartilhamento nativo AirDrop no macOS.
    @MainActor
    public static func execute(files: [URL], from view: NSView? = nil) {
        guard canShare(files: files) else { return }

        let items = files as [NSURL]
        if let airdropService = NSSharingService(named: .sendViaAirDrop),
           airdropService.canPerform(withItems: items) {
            airdropService.perform(withItems: items)
            return
        }

        // Fallback para o seletor nativo de compartilhamento do sistema
        if let targetView = view {
            let picker = NSSharingServicePicker(items: items)
            picker.show(relativeTo: targetView.bounds, of: targetView, preferredEdge: .minY)
        }
    }
}
