import Foundation
import AppKit

@MainActor
public final class RadialWheelView: NSView {
    public var mode: WheelMode = .convert {
        didSet { needsDisplay = true }
    }
    public var items: [RadialItem] = [] {
        didSet {
            currentPageIndex = 0
            activeSectorIndex = nil
            needsDisplay = true
        }
    }
    public var onDropConfirmed: ((RadialItem, [URL]) -> Void)?
    public var onSectorSelected: ((RadialItem) -> Void)?
    public var onDismissRequested: (() -> Void)?

    public private(set) var currentPageIndex: Int = 0 {
        didSet {
            activeSectorIndex = nil
            needsDisplay = true
        }
    }

    /// Retorna os itens paginados da página atual (máximo 8 setores para visual limpo).
    public var displayedItems: [RadialItem] {
        guard items.count > 8 else { return items }
        let pageSize = 7
        let totalPages = max(1, Int(ceil(Double(items.count) / Double(pageSize))))
        let safePage = currentPageIndex % totalPages
        let start = safePage * pageSize
        let end = min(start + pageSize, items.count)
        var slice = Array(items[start..<end])
        slice.append(
            RadialItem(
                id: "page.next",
                title: "Mais (\(safePage + 1)/\(totalPages))",
                iconName: "ellipsis.circle",
                targetExtension: ""
            )
        )
        return slice
    }

    private var trackingArea: NSTrackingArea?

    public var activeSectorIndex: Int? {
        didSet {
            if oldValue != activeSectorIndex {
                needsDisplay = true
            }
        }
    }

    public let innerRadius: CGFloat = 46.0
    public let outerRadius: CGFloat = 155.0

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
    }

    public override var acceptsFirstResponder: Bool {
        true
    }

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        self.trackingArea = area
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let activeItems = displayedItems
        let count = max(activeItems.count, 1)

        // 1. Fundo Circular Exterior Elegante com Glassmorphism
        context.saveGState()

        // Sombra suave exterior
        context.setShadow(offset: CGSize(width: 0, height: -4), blur: 16, color: NSColor.black.withAlphaComponent(0.35).cgColor)
        context.setFillColor(NSColor(calibratedWhite: 0.12, alpha: 0.94).cgColor)
        context.addArc(center: center, radius: outerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.fillPath()
        context.restoreGState()

        // Borda sutil metálica do anel exterior
        context.saveGState()
        context.setStrokeColor(NSColor(calibratedWhite: 0.35, alpha: 0.55).cgColor)
        context.setLineWidth(1.2)
        context.addArc(center: center, radius: outerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.strokePath()
        context.restoreGState()

        // 2. Linhas Divisórias Discretas entre Setores
        if count > 1 {
            context.saveGState()
            context.setStrokeColor(NSColor(calibratedWhite: 0.28, alpha: 0.40).cgColor)
            context.setLineWidth(1.0)
            let span = 360.0 / CGFloat(count)
            for i in 0..<count {
                let angleDeg = CGFloat(i) * span - (span / 2.0)
                let rad = (90.0 - angleDeg) * .pi / 180.0
                let pInner = CGPoint(x: center.x + innerRadius * cos(rad), y: center.y + innerRadius * sin(rad))
                let pOuter = CGPoint(x: center.x + outerRadius * cos(rad), y: center.y + outerRadius * sin(rad))
                context.move(to: pInner)
                context.addLine(to: pOuter)
            }
            context.strokePath()
            context.restoreGState()
        }

        // 3. Desenhar Setores Ativos e Ícones
        for (index, item) in activeItems.enumerated() {
            let isActive = (index == activeSectorIndex)
            drawSector(context: context, center: center, index: index, count: count, item: item, isActive: isActive)
        }

        // 4. Centro Neutro (Badge de Modo Estilo macOS Nativo)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -1), blur: 6, color: NSColor.black.withAlphaComponent(0.4).cgColor)
        context.setFillColor(NSColor(calibratedWhite: 0.18, alpha: 0.98).cgColor)
        context.addArc(center: center, radius: innerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.fillPath()
        context.restoreGState()

        // Borda do centro
        context.saveGState()
        context.setStrokeColor(NSColor(calibratedWhite: 0.35, alpha: 0.6).cgColor)
        context.setLineWidth(1.2)
        context.addArc(center: center, radius: innerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.strokePath()
        context.restoreGState()

        // Texto do Modo Central (Tipografia refinada)
        let modeAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: NSColor(calibratedWhite: 0.92, alpha: 1.0)
        ]
        let modeStr = mode.title as NSString
        let modeSize = modeStr.size(withAttributes: modeAttributes)
        let modeRect = CGRect(
            x: center.x - modeSize.width / 2.0,
            y: center.y - modeSize.height / 2.0 + 4,
            width: modeSize.width,
            height: modeSize.height
        )
        modeStr.draw(in: modeRect, withAttributes: modeAttributes)

        // Subtítulo do atalho no centro
        let hintAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 8, weight: .medium),
            .foregroundColor: NSColor(calibratedWhite: 0.55, alpha: 1.0)
        ]
        let hintStr = mode.shortcutHint as NSString
        let hintSize = hintStr.size(withAttributes: hintAttrs)
        let hintRect = CGRect(
            x: center.x - hintSize.width / 2.0,
            y: center.y - modeSize.height / 2.0 - 10,
            width: hintSize.width,
            height: hintSize.height
        )
        hintStr.draw(in: hintRect, withAttributes: hintAttrs)
    }

    private func drawSector(
        context: CGContext,
        center: CGPoint,
        index: Int,
        count: Int,
        item: RadialItem,
        isActive: Bool
    ) {
        let span = 360.0 / CGFloat(count)
        let midAngleDeg = CGFloat(index) * span
        let startAngleDeg = midAngleDeg - (span / 2.0)
        let endAngleDeg = midAngleDeg + (span / 2.0)

        let cgStart = (90.0 - endAngleDeg) * .pi / 180.0
        let cgEnd = (90.0 - startAngleDeg) * .pi / 180.0

        if isActive {
            context.saveGState()
            // Destaque luminoso azul sutil nativo Apple
            context.setFillColor(NSColor.controlAccentColor.withAlphaComponent(0.42).cgColor)
            let path = CGMutablePath()
            path.addArc(center: center, radius: outerRadius - 1.5, startAngle: cgStart, endAngle: cgEnd, clockwise: false)
            path.addArc(center: center, radius: innerRadius + 1.5, startAngle: cgEnd, endAngle: cgStart, clockwise: true)
            path.closeSubpath()
            context.addPath(path)
            context.fillPath()
            context.restoreGState()
        }

        // Ponto central do setor
        let midRadius = (innerRadius + outerRadius) / 2.0
        let midPoint = RadialGeometry.sectorMidPoint(
            sectorIndex: index,
            sectorCount: count,
            center: center,
            radius: midRadius
        )

        // 1. Desenhar Ícone SF Symbol acima do texto
        let iconSize: CGFloat = (count > 6) ? 14 : 18
        if let sfImage = NSImage(systemSymbolName: item.iconName, accessibilityDescription: nil) {
            let config = NSImage.SymbolConfiguration(pointSize: iconSize, weight: isActive ? .bold : .medium)
            if let tinted = sfImage.withSymbolConfiguration(config) {
                let iconRect = CGRect(
                    x: midPoint.x - iconSize / 2.0,
                    y: midPoint.y + 2,
                    width: iconSize,
                    height: iconSize
                )
                NSGraphicsContext.saveGraphicsState()
                tinted.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)
                NSGraphicsContext.restoreGraphicsState()
            }
        }

        // 2. Desenhar Título com tamanho dinâmico para não sobrepor
        let fontSize: CGFloat = (count > 6) ? 10.0 : 11.5
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: isActive ? .bold : .medium),
            .foregroundColor: isActive ? NSColor.white : NSColor(calibratedWhite: 0.92, alpha: 1.0)
        ]
        let titleStr = item.title as NSString
        let titleSize = titleStr.size(withAttributes: titleAttrs)
        let titleRect = CGRect(
            x: midPoint.x - titleSize.width / 2.0,
            y: midPoint.y - titleSize.height + 1,
            width: titleSize.width,
            height: titleSize.height
        )
        titleStr.draw(in: titleRect, withAttributes: titleAttrs)
    }

    // MARK: - Keyboard Navigation (Acessibilidade)

    public override func keyDown(with event: NSEvent) {
        let activeItems = displayedItems
        let count = activeItems.count
        guard count > 0 else {
            super.keyDown(with: event)
            return
        }

        switch event.keyCode {
        case 123, 126: // Seta Esquerda ou Seta Cima
            activeSectorIndex = KeyboardNavigator.previousIndex(current: activeSectorIndex, count: count)
        case 124, 125: // Seta Direita ou Seta Baixo
            activeSectorIndex = KeyboardNavigator.nextIndex(current: activeSectorIndex, count: count)
        case 36, 49: // Enter ou Barra de Espaço
            if let idx = activeSectorIndex, idx < count {
                let selected = activeItems[idx]
                if selected.id == "page.next" {
                    cycleNextPage()
                } else {
                    onSectorSelected?(selected)
                }
            }
        case 53: // Escape
            onDismissRequested?()
        default:
            super.keyDown(with: event)
        }
    }

    // MARK: - Mouse Event Handling (Cliques e Movimentação)

    public override func mouseMoved(with event: NSEvent) {
        let localPoint = convert(event.locationInWindow, from: nil)
        updateActiveSector(from: localPoint)
    }

    public override func mouseEntered(with event: NSEvent) {
        let localPoint = convert(event.locationInWindow, from: nil)
        updateActiveSector(from: localPoint)
    }

    public override func mouseExited(with event: NSEvent) {
        activeSectorIndex = nil
    }

    public override func mouseDown(with event: NSEvent) {
        let localPoint = convert(event.locationInWindow, from: nil)
        updateActiveSector(from: localPoint)
    }

    public override func mouseDragged(with event: NSEvent) {
        let localPoint = convert(event.locationInWindow, from: nil)
        updateActiveSector(from: localPoint)
    }

    public override func mouseUp(with event: NSEvent) {
        let localPoint = convert(event.locationInWindow, from: nil)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let activeItems = displayedItems

        if let sectorIdx = RadialGeometry.sectorIndex(
            at: localPoint,
            center: center,
            sectorCount: activeItems.count,
            innerRadius: innerRadius,
            outerRadius: outerRadius
        ), sectorIdx < activeItems.count {
            let selectedItem = activeItems[sectorIdx]
            if selectedItem.id == "page.next" {
                cycleNextPage()
            } else {
                onSectorSelected?(selectedItem)
            }
        } else {
            onDismissRequested?()
        }
    }

    public func cycleNextPage() {
        let pageSize = 7
        let totalPages = max(1, Int(ceil(Double(items.count) / Double(pageSize))))
        currentPageIndex = (currentPageIndex + 1) % totalPages
    }

    // MARK: - NSDraggingDestination (Arrasto e Soltura de Arquivos)

    public override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        if let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           !urls.isEmpty {
            let descriptors = urls.map { FileDescriptor(url: $0) }
            if mode == .convert {
                let dynamicTargets = FormatRegistry.defaultRegistry().availableTargets(for: descriptors)
                if !dynamicTargets.isEmpty {
                    self.items = dynamicTargets
                }
            } else if mode == .tools {
                let dynamicTools = ToolRegistry.availableTools(for: descriptors)
                if !dynamicTools.isEmpty {
                    self.items = dynamicTools
                }
            }
        }

        let localPoint = convert(sender.draggingLocation, from: nil)
        updateActiveSector(from: localPoint)
        return .copy
    }

    public override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        let localPoint = convert(sender.draggingLocation, from: nil)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let activeItems = displayedItems

        if let sectorIdx = RadialGeometry.sectorIndex(
            at: localPoint,
            center: center,
            sectorCount: activeItems.count,
            innerRadius: innerRadius,
            outerRadius: outerRadius
        ), sectorIdx < activeItems.count, activeItems[sectorIdx].id == "page.next" {
            // Se o usuário passar o mouse/drag sobre "Mais...", avança a página
            cycleNextPage()
        } else {
            updateActiveSector(from: localPoint)
        }
        return .copy
    }

    public override func draggingExited(_ sender: (any NSDraggingInfo)?) {
        activeSectorIndex = nil
    }

    public override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        guard let pboard = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
              !pboard.isEmpty else {
            return false
        }

        let localPoint = convert(sender.draggingLocation, from: nil)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let activeItems = displayedItems

        if let sectorIdx = RadialGeometry.sectorIndex(
            at: localPoint,
            center: center,
            sectorCount: activeItems.count,
            innerRadius: innerRadius,
            outerRadius: outerRadius
        ), sectorIdx < activeItems.count {
            let selectedItem = activeItems[sectorIdx]
            if selectedItem.id == "page.next" {
                cycleNextPage()
                return false
            }
            onDropConfirmed?(selectedItem, pboard)
            return true
        }

        return false
    }

    private func updateActiveSector(from location: CGPoint) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let activeItems = displayedItems
        activeSectorIndex = RadialGeometry.sectorIndex(
            at: location,
            center: center,
            sectorCount: activeItems.count,
            innerRadius: innerRadius,
            outerRadius: outerRadius
        )
    }

    @objc private func handleAccessibilityPress(_ itemObj: Any?) {
        guard let item = itemObj as? RadialItem else { return }
        if item.id == "page.next" {
            cycleNextPage()
        } else {
            onSectorSelected?(item)
        }
    }

    // MARK: - Accessibility (VoiceOver)

    public override func isAccessibilityElement() -> Bool {
        false
    }

    public override func accessibilityChildren() -> [Any]? {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let activeItems = displayedItems
        let count = activeItems.count

        return activeItems.enumerated().map { (index, item) -> Any in
            let element = RadialSectorAccessibilityElement()
            element.item = item
            element.actionTarget = self
            element.actionSelector = #selector(handleAccessibilityPress)
            element.setAccessibilityRole(.button)
            element.setAccessibilityLabel(item.title)
            element.setAccessibilityHelp("Ação ou formato de destino: \(item.title)")
            element.setAccessibilityParent(self)

            let midPoint = RadialGeometry.sectorMidPoint(sectorIndex: index, sectorCount: count, center: center, radius: (innerRadius + outerRadius) / 2)
            let localRect = NSRect(x: midPoint.x - 20, y: midPoint.y - 20, width: 40, height: 40)
            let winRect = convert(localRect, to: nil)
            let screenRect = window?.convertToScreen(winRect) ?? winRect
            element.setAccessibilityFrame(screenRect)

            return element
        }
    }
}
