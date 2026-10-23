import Foundation
import AppKit

@MainActor
public final class SettingsWindowController: NSWindowController {
    public static let shared = SettingsWindowController()

    public init() {
        let contentRect = NSRect(x: 100, y: 100, width: 420, height: 260)
        let window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "OrbitDrop — Ajustes"
        window.isReleasedWhenClosed = false
        window.center()

        let view = SettingsContainerView(frame: window.contentView?.bounds ?? .zero)
        view.autoresizingMask = [.width, .height]
        window.contentView = view

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@MainActor
private final class SettingsContainerView: NSView {
    private let besideCheckbox = NSButton(checkboxWithTitle: "Salvar arquivos convertidos ao lado do original", target: nil, action: nil)
    private let revealCheckbox = NSButton(checkboxWithTitle: "Revelar arquivo no Finder ao concluir conversão", target: nil, action: nil)
    private let itermCheckbox = NSButton(checkboxWithTitle: "Usar iTerm2 em vez do Terminal padrão (se instalado)", target: nil, action: nil)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        let current = SettingsManager.shared.settings
        besideCheckbox.state = current.saveBesideOriginal ? .on : .off
        revealCheckbox.state = current.revealInFinderOnComplete ? .on : .off
        itermCheckbox.state = current.preferITerm ? .on : .off

        besideCheckbox.target = self
        besideCheckbox.action = #selector(settingChanged)
        revealCheckbox.target = self
        revealCheckbox.action = #selector(settingChanged)
        itermCheckbox.target = self
        itermCheckbox.action = #selector(settingChanged)

        let stack = NSStackView(views: [besideCheckbox, revealCheckbox, itermCheckbox])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 30),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30)
        ])
    }

    @objc private func settingChanged() {
        var updated = SettingsManager.shared.settings
        updated.saveBesideOriginal = (besideCheckbox.state == .on)
        updated.revealInFinderOnComplete = (revealCheckbox.state == .on)
        updated.preferITerm = (itermCheckbox.state == .on)
        SettingsManager.shared.update(updated)
    }
}
