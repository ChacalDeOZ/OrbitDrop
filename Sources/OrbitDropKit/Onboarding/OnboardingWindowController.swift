import Foundation
import AppKit

@MainActor
public final class OnboardingWindowController: NSWindowController {
    public static let shared = OnboardingWindowController()

    private var currentStep: OnboardingStep = .welcome
    private let titleLabel = NSTextField(labelWithString: "")
    private let descriptionLabel = NSTextField(wrappingLabelWithString: "")
    private let stepIndicatorLabel = NSTextField(labelWithString: "")
    private let statusBadgeLabel = NSTextField(labelWithString: "")
    private let interactiveBox = NSBox()
    private let nextButton = NSButton(title: "Continuar", target: nil, action: nil)
    private let actionButton = NSButton(title: "Abrir Ajustes", target: nil, action: nil)

    public init() {
        let contentRect = NSRect(x: 100, y: 100, width: 520, height: 420)
        let window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Bem-vindo ao OrbitDrop"
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)
        setupViews()
        updateUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        guard let contentView = window?.contentView else { return }

        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        descriptionLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        stepIndicatorLabel.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        stepIndicatorLabel.textColor = .secondaryLabelColor

        statusBadgeLabel.font = NSFont.systemFont(ofSize: 12, weight: .semibold)

        interactiveBox.boxType = .custom
        interactiveBox.cornerRadius = 8
        interactiveBox.borderWidth = 1
        interactiveBox.borderColor = .separatorColor
        interactiveBox.fillColor = NSColor.controlBackgroundColor.withAlphaComponent(0.6)
        interactiveBox.translatesAutoresizingMaskIntoConstraints = false

        let boxLabel = NSTextField(labelWithString: "Área de Demonstração / Teste Prático")
        boxLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        boxLabel.textColor = .secondaryLabelColor
        boxLabel.translatesAutoresizingMaskIntoConstraints = false
        interactiveBox.addSubview(boxLabel)
        NSLayoutConstraint.activate([
            boxLabel.centerXAnchor.constraint(equalTo: interactiveBox.centerXAnchor),
            boxLabel.centerYAnchor.constraint(equalTo: interactiveBox.centerYAnchor),
            interactiveBox.heightAnchor.constraint(equalToConstant: 70)
        ])

        nextButton.bezelStyle = .rounded
        nextButton.keyEquivalent = "\r"
        nextButton.target = self
        nextButton.action = #selector(nextAction)

        actionButton.bezelStyle = .rounded
        actionButton.target = self
        actionButton.action = #selector(extraAction)

        let buttonRow = NSStackView(views: [actionButton, nextButton])
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 12

        let stack = NSStackView(views: [stepIndicatorLabel, titleLabel, descriptionLabel, statusBadgeLabel, interactiveBox, buttonRow])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            interactiveBox.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    private func updateUI() {
        stepIndicatorLabel.stringValue = "PASSO \(currentStep.rawValue + 1) DE 5"
        titleLabel.stringValue = currentStep.title
        descriptionLabel.stringValue = currentStep.description

        switch currentStep {
        case .welcome:
            statusBadgeLabel.isHidden = true
            interactiveBox.isHidden = true
            actionButton.isHidden = true

        case .interactiveDemo:
            statusBadgeLabel.isHidden = false
            statusBadgeLabel.stringValue = "💡 Dica: Arraste arquivos no Finder e aperte Shift, Command ou Control"
            statusBadgeLabel.textColor = .systemBlue
            interactiveBox.isHidden = false
            actionButton.isHidden = true

        case .permissions:
            let isTrusted = AccessibilityChecker.isProcessTrusted(prompt: false)
            statusBadgeLabel.isHidden = false
            if isTrusted {
                statusBadgeLabel.stringValue = "✓ Acessibilidade Concedida (Monitoramento global ativo)"
                statusBadgeLabel.textColor = .systemGreen
                actionButton.isHidden = true
            } else {
                statusBadgeLabel.stringValue = "⚠️ Acessibilidade Pendente (Exigida para interceptação de tecla externa)"
                statusBadgeLabel.textColor = .systemOrange
                actionButton.isHidden = false
                actionButton.title = "Abrir Ajustes de Acessibilidade"
            }
            interactiveBox.isHidden = true

        case .firstTest:
            statusBadgeLabel.isHidden = false
            statusBadgeLabel.stringValue = "🎯 Fallback garantido: a Drop Zone flutuante dispensa permissões"
            statusBadgeLabel.textColor = .systemGreen
            interactiveBox.isHidden = false
            actionButton.isHidden = false
            actionButton.title = "Abrir Drop Zone de Teste"

        case .completed:
            statusBadgeLabel.isHidden = true
            interactiveBox.isHidden = true
            actionButton.isHidden = true
        }

        if currentStep == .completed {
            nextButton.title = "Começar a Usar"
        } else {
            nextButton.title = "Continuar"
        }
    }

    @objc private func nextAction() {
        if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            currentStep = next
            updateUI()
        } else {
            OnboardingState.shared.markCompleted()
            window?.close()
        }
    }

    @objc private func extraAction() {
        if currentStep == .permissions {
            AccessibilityChecker.openAccessibilitySettings()
        } else if currentStep == .firstTest {
            // Abrir Drop Zone de teste para o usuário praticar
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Finder.app"))
        }
    }

    public func show() {
        currentStep = .welcome
        updateUI()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
