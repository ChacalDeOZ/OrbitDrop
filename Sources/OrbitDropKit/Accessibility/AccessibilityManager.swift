import Foundation
import AppKit

public enum AccessibilityManager: Sendable {
    /// Indica se o usuário ativou a opção de redução de movimento nos Ajustes de Acessibilidade do macOS.
    @MainActor
    public static var shouldReduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }
}
