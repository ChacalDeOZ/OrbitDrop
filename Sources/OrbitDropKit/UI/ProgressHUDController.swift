import Foundation
import AppKit

@MainActor
public final class ProgressHUDController: NSWindowController {
    public static let shared = ProgressHUDController()

    private let titleLabel = NSTextField(labelWithString: "OrbitDrop — Processando...")
    private let detailLabel = NSTextField(labelWithString: "Iniciando...")
    private let progressIndicator = NSProgressIndicator()
    private let cancelButton = NSButton(title: "Cancelar", target: nil, action: nil)

    public var onCancelRequested: (() -> Void)?

    public init() {
        let contentRect = NSRect(x: 100, y: 100, width: 360, height: 110)
        let window = NSPanel(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .transient]

        let container = ProgressHUDContainerView(frame: contentRect)
        window.contentView = container

        super.init(window: window)

        setupUI(in: container)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(in container: NSView) {
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        detailLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        detailLabel.textColor = NSColor(calibratedWhite: 0.75, alpha: 1.0)
        detailLabel.lineBreakMode = .byTruncatingMiddle
        detailLabel.translatesAutoresizingMaskIntoConstraints = false

        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = false
        progressIndicator.minValue = 0.0
        progressIndicator.maxValue = 1.0
        progressIndicator.doubleValue = 0.0
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false

        cancelButton.bezelStyle = .rounded
        cancelButton.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        cancelButton.target = self
        cancelButton.action = #selector(cancelAction)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(detailLabel)
        container.addSubview(progressIndicator)
        container.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor, constant: -12),

            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            detailLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
            detailLabel.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor, constant: -12),

            progressIndicator.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 12),
            progressIndicator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
            progressIndicator.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -18),

            cancelButton.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            cancelButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            cancelButton.widthAnchor.constraint(equalToConstant: 74)
        ])
    }

    @objc private func cancelAction() {
        onCancelRequested?()
        detailLabel.stringValue = "Cancelando..."
    }

    public func show(title: String, detail: String, onCancel: (() -> Void)? = nil) {
        self.onCancelRequested = onCancel
        titleLabel.stringValue = title
        detailLabel.stringValue = detail
        progressIndicator.doubleValue = 0.0

        if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            let origin = CGPoint(
                x: visible.maxX - 380,
                y: visible.minY + 40
            )
            window?.setFrameOrigin(origin)
        }

        window?.orderFront(nil)
    }

    public func update(progress: Double, detail: String) {
        progressIndicator.doubleValue = progress
        detailLabel.stringValue = detail
    }

    public func finish(success: Bool, message: String) {
        titleLabel.stringValue = success ? "Concluído com Sucesso!" : "Operação Falhou"
        detailLabel.stringValue = message
        progressIndicator.doubleValue = 1.0

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            self.window?.orderOut(nil)
        }
    }

    public func hide() {
        window?.orderOut(nil)
    }
}

@MainActor
private final class ProgressHUDContainerView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Fundo escuro glassmorphism
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -4), blur: 16, color: NSColor.black.withAlphaComponent(0.4).cgColor)
        context.setFillColor(NSColor(calibratedWhite: 0.14, alpha: 0.96).cgColor)
        let path = CGPath(roundedRect: bounds, cornerWidth: 14, cornerHeight: 14, transform: nil)
        context.addPath(path)
        context.fillPath()

        // Borda sutil
        context.setStrokeColor(NSColor(calibratedWhite: 0.32, alpha: 0.6).cgColor)
        context.setLineWidth(1.2)
        context.addPath(path)
        context.strokePath()
        context.restoreGState()
    }
}
