import Foundation
import AppKit

@MainActor
public final class StatusItemController: NSObject {
    private var statusItem: NSStatusItem?
    public var onTestRadialTriggered: (() -> Void)?
    public var onOpenDropZoneTriggered: (() -> Void)?
    public var onOpenFloatShelfTriggered: (() -> Void)?
    public var onOpenSettingsTriggered: (() -> Void)?
    public var onOpenOnboardingTriggered: (() -> Void)?

    public override init() {
        super.init()
    }

    public func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = item.button {
            if let image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath.circle", accessibilityDescription: "OrbitDrop") {
                button.image = image
            } else {
                button.title = "⨀"
            }
            button.toolTip = "OrbitDrop — Conversor Nativo Ilimitado"
        }

        let menu = NSMenu()

        let headerItem = NSMenuItem(title: "OrbitDrop — Pronto (Ilimitado)", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        menu.addItem(NSMenuItem.separator())

        let testItem = NSMenuItem(title: "Testar Menu Radial no Cursor", action: #selector(testRadialAction), keyEquivalent: "t")
        testItem.target = self
        menu.addItem(testItem)

        let dropZoneItem = NSMenuItem(title: "Abrir Drop Zone Flutuante", action: #selector(openDropZoneAction), keyEquivalent: "d")
        dropZoneItem.target = self
        menu.addItem(dropZoneItem)

        let floatShelfItem = NSMenuItem(title: "Abrir Prateleira Flutuante", action: #selector(openFloatShelfAction), keyEquivalent: "f")
        floatShelfItem.target = self
        menu.addItem(floatShelfItem)

        let tutorialItem = NSMenuItem(title: "Tutorial / Boas-Vindas...", action: #selector(openOnboardingAction), keyEquivalent: "")
        tutorialItem.target = self
        menu.addItem(tutorialItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Ajustes...", action: #selector(openSettingsAction), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let accessItem = NSMenuItem(title: "Verificar Permissão de Acessibilidade...", action: #selector(checkAccessibilityAction), keyEquivalent: "")
        accessItem.target = self
        menu.addItem(accessItem)

        menu.addItem(NSMenuItem.separator())

        let aboutItem = NSMenuItem(title: "Sobre OrbitDrop", action: #selector(aboutAction), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(title: "Encerrar OrbitDrop", action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
        self.statusItem = item
    }

    @objc private func testRadialAction() {
        onTestRadialTriggered?()
    }

    @objc private func openDropZoneAction() {
        onOpenDropZoneTriggered?()
    }

    @objc private func openFloatShelfAction() {
        onOpenFloatShelfTriggered?()
    }

    @objc private func openOnboardingAction() {
        onOpenOnboardingTriggered?()
    }

    @objc private func openSettingsAction() {
        onOpenSettingsTriggered?()
    }

    @objc private func checkAccessibilityAction() {
        let isTrusted = AccessibilityChecker.isProcessTrusted(prompt: true)
        if !isTrusted {
            let alert = NSAlert()
            alert.messageText = "Permissão de Acessibilidade Necessária"
            alert.informativeText = "Para abrir o menu radial quando você toca Shift durante o arrasto no Finder, o macOS exige permissão de Acessibilidade em Ajustes do Sistema."
            alert.addButton(withTitle: "Abrir Ajustes do Sistema")
            alert.addButton(withTitle: "Usar Modo Drop Zone")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                AccessibilityChecker.openAccessibilitySettings()
            } else {
                onOpenDropZoneTriggered?()
            }
        } else {
            let alert = NSAlert()
            alert.messageText = "Acessibilidade Autorizada"
            alert.informativeText = "O OrbitDrop está autorizado a detectar teclas durante o arrasto global de arquivos."
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    @objc private func aboutAction() {
        let alert = NSAlert()
        alert.messageText = "OrbitDrop"
        alert.informativeText = "Conversor e manipulador nativo de arquivos para macOS.\n\n• Operações 100% locais e offline\n• Conversões e lotes ilimitados sem qualquer paywall\n• Swift 6 + AppKit nativo"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quitAction() {
        NSApp.terminate(nil)
    }
}
