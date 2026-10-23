import Foundation
import AppKit

public enum ActionDispatcher: Sendable {
    /// Retorna os itens radiais correspondentes às 6 ações do sistema.
    public static func availableActions() -> [RadialItem] {
        ActionType.allCases.map { $0.asRadialItem }
    }

    /// Roteia a execução da ação selecionada para o respectivo despachante.
    @MainActor
    public static func dispatch(
        actionID: String,
        files: [URL],
        sourceView: NSView? = nil,
        floatShelf: FloatShelfController? = nil
    ) {
        guard let action = ActionType(rawValue: actionID) else { return }

        switch action {
        case .airDrop:
            AirDropAction.execute(files: files, from: sourceView)

        case .floatShelf:
            if let shelf = floatShelf {
                shelf.add(files: files)
                shelf.show()
            }

        case .copy:
            CopyAction.execute(urls: files)

        case .move:
            let openPanel = NSOpenPanel()
            openPanel.title = "Escolha a pasta de destino para Mover"
            openPanel.canChooseFiles = false
            openPanel.canChooseDirectories = true
            openPanel.canCreateDirectories = true
            openPanel.allowsMultipleSelection = false
            NSApp.activate(ignoringOtherApps: true)
            if openPanel.runModal() == .OK, let targetDir = openPanel.url {
                do {
                    let moved = try MoveAction.move(files: files, to: targetDir)
                    if !moved.isEmpty {
                        NSWorkspace.shared.activateFileViewerSelecting(moved)
                    }
                } catch {
                    NSLog("[ActionDispatcher] Erro ao mover arquivos: %@", error.localizedDescription)
                }
            }

        case .copyPath:
            CopyPathAction.execute(urls: files)

        case .terminal:
            let preferITerm = SettingsManager.shared.settings.preferITerm
            TerminalAction.execute(files: files, preferITerm: preferITerm)
        }
    }
}
