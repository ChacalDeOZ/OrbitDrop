import Foundation
import AppKit

@MainActor
public final class FloatShelfController: NSWindowController {
    public private(set) var items: [FileDescriptor] = []
    public var onItemsChanged: (([FileDescriptor]) -> Void)?

    private let shelfView: FloatShelfContainerView

    public init() {
        let contentRect = NSRect(x: 100, y: 100, width: 340, height: 220)
        let window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "OrbitDrop — Float Shelf"
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        self.shelfView = FloatShelfContainerView(frame: window.contentView?.bounds ?? .zero)
        shelfView.autoresizingMask = [.width, .height]
        window.contentView = shelfView

        super.init(window: window)

        shelfView.controller = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func add(files: [URL]) {
        for url in files {
            let descriptor = FileDescriptor(url: url)
            if !items.contains(where: { $0.url == url }) {
                items.append(descriptor)
            }
        }
        shelfView.needsDisplay = true
        onItemsChanged?(items)
    }

    public func remove(at index: Int) {
        guard index >= 0 && index < items.count else { return }
        items.remove(at: index)
        shelfView.needsDisplay = true
        onItemsChanged?(items)
    }

    public func clear() {
        items.removeAll()
        shelfView.needsDisplay = true
        onItemsChanged?(items)
    }

    public func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@MainActor
private final class FloatShelfContainerView: NSView, NSDraggingSource {
    weak var controller: FloatShelfController?

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
        guard let items = controller?.items else { return }

        if items.isEmpty {
            drawEmptyState()
            return
        }

        // Renderizar lista simples de itens
        var yOffset = bounds.maxY - 28.0
        for (index, item) in items.enumerated() {
            guard yOffset >= 0 else { break }
            let itemRect = CGRect(x: 12, y: yOffset, width: bounds.width - 24, height: 22)

            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: NSColor.labelColor
            ]
            let str = "\(index + 1). \(item.displayName)" as NSString
            str.draw(in: itemRect, withAttributes: attrs)

            yOffset -= 24.0
        }
    }

    private func drawEmptyState() {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let str = "Prateleira Vazia — Arraste arquivos aqui" as NSString
        let size = str.size(withAttributes: attrs)
        let rect = CGRect(
            x: bounds.midX - size.width / 2.0,
            y: bounds.midY - size.height / 2.0,
            width: size.width,
            height: size.height
        )
        str.draw(in: rect, withAttributes: attrs)
    }

    // MARK: - NSDraggingDestination (Drag In)

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        .copy
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
              !urls.isEmpty else {
            return false
        }
        controller?.add(files: urls)
        return true
    }

    // MARK: - NSDraggingSource (Drag Out)

    private var dragStartLocation: CGPoint?

    override func mouseDown(with event: NSEvent) {
        dragStartLocation = convert(event.locationInWindow, from: nil)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let items = controller?.items, !items.isEmpty else { return }
        let currentLoc = convert(event.locationInWindow, from: nil)
        if let start = dragStartLocation, hypot(currentLoc.x - start.x, currentLoc.y - start.y) > 4 {
            startDraggingItems(items: items, with: event)
            dragStartLocation = nil
        }
    }

    private func startDraggingItems(items: [FileDescriptor], with event: NSEvent) {
        let draggingItems = items.map { item -> NSDraggingItem in
            let draggingItem = NSDraggingItem(pasteboardWriter: item.url as NSURL)
            let icon = NSImage(systemSymbolName: "doc.fill", accessibilityDescription: nil) ?? NSImage()
            draggingItem.setDraggingFrame(
                CGRect(x: event.locationInWindow.x - 16, y: event.locationInWindow.y - 16, width: 32, height: 32),
                contents: icon
            )
            return draggingItem
        }
        guard !draggingItems.isEmpty else { return }
        beginDraggingSession(with: draggingItems, event: event, source: self)
    }

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        .copy
    }
}
