import Foundation
import AppKit

@MainActor
public final class DropZoneWindowController: NSWindowController {
    public var onFilesDropped: (([URL]) -> Void)?

    public init() {
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 300, height: 180),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "OrbitDrop — Drop Zone"
        window.level = .floating
        window.isReleasedWhenClosed = false

        let dropView = DropZoneContainerView(frame: window.contentView?.bounds ?? .zero)
        dropView.autoresizingMask = [.width, .height]
        window.contentView = dropView

        super.init(window: window)

        dropView.onDrop = { [weak self] urls in
            self?.onFilesDropped?(urls)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func show() {
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@MainActor
private final class DropZoneContainerView: NSView {
    var onDrop: (([URL]) -> Void)?
    private var isHighlighted: Bool = false {
        didSet { needsDisplay = true }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Fundo com cantos arredondados
        let insetRect = bounds.insetBy(dx: 12, dy: 12)
        let path = CGPath(roundedRect: insetRect, cornerWidth: 12, cornerHeight: 12, transform: nil)

        context.saveGState()
        if isHighlighted {
            context.setFillColor(NSColor.controlAccentColor.withAlphaComponent(0.18).cgColor)
            context.setStrokeColor(NSColor.controlAccentColor.cgColor)
            context.setLineWidth(2.5)
        } else {
            context.setFillColor(NSColor.windowBackgroundColor.cgColor)
            context.setStrokeColor(NSColor.separatorColor.cgColor)
            context.setLineWidth(1.5)
            context.setLineDash(phase: 0, lengths: [6, 4])
        }
        context.addPath(path)
        context.drawPath(using: .fillStroke)
        context.restoreGState()

        // Textos
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: NSColor.labelColor
        ]
        let titleStr = "Arraste e Solte Arquivos Aqui" as NSString
        let titleSize = titleStr.size(withAttributes: titleAttrs)
        let titleRect = CGRect(
            x: bounds.midX - titleSize.width / 2.0,
            y: bounds.midY + 4,
            width: titleSize.width,
            height: titleSize.height
        )
        titleStr.draw(in: titleRect, withAttributes: titleAttrs)

        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let subStr = "Conversão instantânea local para JPEG (100% Ilimitado)" as NSString
        let subSize = subStr.size(withAttributes: subAttrs)
        let subRect = CGRect(
            x: bounds.midX - subSize.width / 2.0,
            y: bounds.midY - 20,
            width: subSize.width,
            height: subSize.height
        )
        subStr.draw(in: subRect, withAttributes: subAttrs)
    }

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        isHighlighted = true
        return .copy
    }

    override func draggingExited(_ sender: (any NSDraggingInfo)?) {
        isHighlighted = false
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        isHighlighted = false
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
              !urls.isEmpty else {
            return false
        }
        onDrop?(urls)
        return true
    }
}
