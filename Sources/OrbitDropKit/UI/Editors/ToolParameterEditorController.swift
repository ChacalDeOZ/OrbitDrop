import Foundation
import AppKit

public enum EditableToolType: Sendable {
    case videoSpeed(initialSpeed: Double)
    case imageCompression(initialQuality: Float)
    case imageAdjustments(contrast: Float, brightness: Float, saturation: Float)
    case pdfRotate(degrees: Int)
}

public enum EditorResult: Sendable {
    case videoSpeed(speed: Double)
    case imageCompression(quality: Float)
    case imageAdjustments(contrast: Float, brightness: Float, saturation: Float)
    case pdfRotate(degrees: Int)
}

@MainActor
public final class ToolParameterEditorController: NSWindowController {
    public static let shared = ToolParameterEditorController()

    private let toolType: EditableToolType
    private var onCommit: ((EditorResult) -> Void)?

    // Controles dinâmicos
    private let titleLabel = NSTextField(labelWithString: "")
    private let valueLabel = NSTextField(labelWithString: "")
    private let slider1 = NSSlider()
    private let slider2 = NSSlider()
    private let slider3 = NSSlider()
    private let label1 = NSTextField(labelWithString: "")
    private let label2 = NSTextField(labelWithString: "")
    private let label3 = NSTextField(labelWithString: "")

    private let resetButton = NSButton(title: "Redefinir", target: nil, action: nil)
    private let cancelButton = NSButton(title: "Cancelar", target: nil, action: nil)
    private let exportButton = NSButton(title: "Exportar Cópia", target: nil, action: nil)

    public init(toolType: EditableToolType = .videoSpeed(initialSpeed: 2.0)) {
        self.toolType = toolType

        let contentRect = NSRect(x: 100, y: 100, width: 440, height: 280)
        let window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public static func present(
        for toolType: EditableToolType,
        sourceURL: URL,
        onCommit: @escaping (EditorResult) -> Void
    ) {
        let controller = ToolParameterEditorController(toolType: toolType)
        controller.onCommit = onCommit
        controller.configureForTool(sourceURL: sourceURL)
        controller.window?.center()
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func setupViews() {
        guard let contentView = window?.contentView else { return }

        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        valueLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        valueLabel.textColor = .secondaryLabelColor

        slider1.target = self
        slider1.action = #selector(sliderChanged)
        slider2.target = self
        slider2.action = #selector(sliderChanged)
        slider3.target = self
        slider3.action = #selector(sliderChanged)

        resetButton.bezelStyle = .rounded
        resetButton.target = self
        resetButton.action = #selector(resetAction)

        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancelAction)

        exportButton.bezelStyle = .rounded
        exportButton.keyEquivalent = "\r"
        exportButton.target = self
        exportButton.action = #selector(exportAction)

        let footerStack = NSStackView(views: [resetButton, NSView(), cancelButton, exportButton])
        footerStack.orientation = .horizontal
        footerStack.distribution = .fill

        let mainStack = NSStackView(views: [
            titleLabel,
            valueLabel,
            label1, slider1,
            label2, slider2,
            label3, slider3,
            footerStack
        ])
        mainStack.orientation = .vertical
        mainStack.alignment = .leading
        mainStack.spacing = 10
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            footerStack.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            slider1.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            slider2.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            slider3.widthAnchor.constraint(equalTo: mainStack.widthAnchor)
        ])
    }

    private func configureForTool(sourceURL: URL) {
        window?.title = "Editor de Parâmetros — \(sourceURL.lastPathComponent)"

        switch toolType {
        case .videoSpeed(let initial):
            titleLabel.stringValue = "Ajustar Velocidade do Vídeo"
            valueLabel.stringValue = "Fator atual: \(String(format: "%.2fx", initial))"
            label1.stringValue = "Velocidade (0.25x a 4.0x):"
            slider1.minValue = 0.25
            slider1.maxValue = 4.0
            slider1.doubleValue = initial
            label2.isHidden = true
            slider2.isHidden = true
            label3.isHidden = true
            slider3.isHidden = true

        case .imageCompression(let initial):
            titleLabel.stringValue = "Comprimir Imagem"
            valueLabel.stringValue = "Qualidade: \(Int(initial * 100))%"
            label1.stringValue = "Taxa de Qualidade / Compressão:"
            slider1.minValue = 0.10
            slider1.maxValue = 0.95
            slider1.doubleValue = Double(initial)
            label2.isHidden = true
            slider2.isHidden = true
            label3.isHidden = true
            slider3.isHidden = true

        case .imageAdjustments(let contrast, let brightness, let saturation):
            titleLabel.stringValue = "Ajustes de Luz e Cor"
            valueLabel.stringValue = "Contraste: \(String(format: "%.1f", contrast)) | Brilho: \(String(format: "%.1f", brightness)) | Saturação: \(String(format: "%.1f", saturation))"
            label1.stringValue = "Contraste:"
            slider1.minValue = 0.5
            slider1.maxValue = 2.0
            slider1.doubleValue = Double(contrast)

            label2.isHidden = false
            slider2.isHidden = false
            label2.stringValue = "Brilho:"
            slider2.minValue = -0.5
            slider2.maxValue = 0.5
            slider2.doubleValue = Double(brightness)

            label3.isHidden = false
            slider3.isHidden = false
            label3.stringValue = "Saturação:"
            slider3.minValue = 0.0
            slider3.maxValue = 2.0
            slider3.doubleValue = Double(saturation)

        case .pdfRotate(let initial):
            titleLabel.stringValue = "Organizar / Girar Páginas do PDF"
            valueLabel.stringValue = "Ângulo: \(initial)°"
            label1.stringValue = "Rotação:"
            slider1.minValue = 0
            slider1.maxValue = 270
            slider1.numberOfTickMarks = 4
            slider1.allowsTickMarkValuesOnly = true
            slider1.doubleValue = Double(initial)
            label2.isHidden = true
            slider2.isHidden = true
            label3.isHidden = true
            slider3.isHidden = true
        }
    }

    @objc private func sliderChanged() {
        switch toolType {
        case .videoSpeed:
            let val = slider1.doubleValue
            valueLabel.stringValue = "Fator atual: \(String(format: "%.2fx", val))"
        case .imageCompression:
            let val = slider1.doubleValue
            valueLabel.stringValue = "Qualidade: \(Int(val * 100))%"
        case .imageAdjustments:
            valueLabel.stringValue = "Contraste: \(String(format: "%.1f", slider1.doubleValue)) | Brilho: \(String(format: "%.1f", slider2.doubleValue)) | Saturação: \(String(format: "%.1f", slider3.doubleValue))"
        case .pdfRotate:
            let val = Int(slider1.doubleValue)
            valueLabel.stringValue = "Ângulo: \(val)°"
        }
    }

    @objc private func resetAction() {
        switch toolType {
        case .videoSpeed:
            slider1.doubleValue = 1.0
        case .imageCompression:
            slider1.doubleValue = 0.80
        case .imageAdjustments:
            slider1.doubleValue = 1.0
            slider2.doubleValue = 0.0
            slider3.doubleValue = 1.0
        case .pdfRotate:
            slider1.doubleValue = 0.0
        }
        sliderChanged()
    }

    @objc private func cancelAction() {
        window?.close()
    }

    @objc private func exportAction() {
        window?.close()
        switch toolType {
        case .videoSpeed:
            onCommit?(.videoSpeed(speed: slider1.doubleValue))
        case .imageCompression:
            onCommit?(.imageCompression(quality: Float(slider1.doubleValue)))
        case .imageAdjustments:
            onCommit?(.imageAdjustments(contrast: Float(slider1.doubleValue), brightness: Float(slider2.doubleValue), saturation: Float(slider3.doubleValue)))
        case .pdfRotate:
            onCommit?(.pdfRotate(degrees: Int(slider1.doubleValue)))
        }
    }
}
