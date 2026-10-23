import Foundation

public enum WheelMode: String, Sendable, CaseIterable, Equatable {
    case convert
    case tools
    case actions

    public var title: String {
        switch self {
        case .convert:
            return "Converter"
        case .tools:
            return "Ferramentas"
        case .actions:
            return "Ações"
        }
    }

    public var shortcutHint: String {
        switch self {
        case .convert:
            return "⇧ Shift"
        case .tools:
            return "⌘ Command"
        case .actions:
            return "⌃ Control"
        }
    }
}
