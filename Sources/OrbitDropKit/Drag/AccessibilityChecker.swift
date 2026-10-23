import Foundation
import AppKit

@MainActor
public enum AccessibilityChecker {
    /// Verifica se o processo atual possui autorização de Acessibilidade (TCC).
    public static func isProcessTrusted(prompt: Bool = false) -> Bool {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options: [CFString: Bool] = [key: prompt]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Abre o painel de Acessibilidade nos Ajustes do Sistema para o usuário conceder permissão.
    public static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
