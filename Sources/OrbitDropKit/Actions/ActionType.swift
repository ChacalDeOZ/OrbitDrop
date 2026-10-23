import Foundation

public enum ActionType: String, Sendable, CaseIterable, Identifiable, Equatable {
    case airDrop = "action.airDrop"
    case floatShelf = "action.float"
    case copy = "action.copy"
    case move = "action.move"
    case copyPath = "action.copyPath"
    case terminal = "action.terminal"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .airDrop: return "AirDrop"
        case .floatShelf: return "Float Shelf"
        case .copy: return "Copiar"
        case .move: return "Mover"
        case .copyPath: return "Copiar Caminho"
        case .terminal: return "Abrir Terminal"
        }
    }

    public var iconName: String {
        switch self {
        case .airDrop: return "airplayaudio"
        case .floatShelf: return "tray.and.arrow.down"
        case .copy: return "doc.on.doc"
        case .move: return "folder"
        case .copyPath: return "link"
        case .terminal: return "terminal"
        }
    }

    public var asRadialItem: RadialItem {
        RadialItem(
            id: id,
            title: title,
            iconName: iconName,
            targetExtension: "",
            isAvailable: true
        )
    }
}
