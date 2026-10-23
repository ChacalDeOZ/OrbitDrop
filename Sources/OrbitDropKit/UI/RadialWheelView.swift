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

        // 1. Fundo Circular Exterior Elegante com Glassmorphism Ultra-Refinado
        context.saveGState()

        // Sombra exterior profunda e difusa
        context.setShadow(offset: CGSize(width: 0, height: -6), blur: 20, color: NSColor.black.withAlphaComponent(0.45).cgColor)
        context.setFillColor(NSColor(calibratedWhite: 0.09, alpha: 0.95).cgColor)
        context.addArc(center: center, radius: outerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.fillPath()
        context.restoreGState()

        // Borda sutil de vidro com gradiente metálico
        context.saveGState()
        context.setStrokeColor(NSColor(calibratedWhite: 0.38, alpha: 0.50).cgColor)
        context.setLineWidth(1.2)
        context.addArc(center: center, radius: outerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.strokePath()
        context.restoreGState()

        // 2. Linhas Divisórias Discretas entre Setores
        if count > 1 {
            context.saveGState()
            context.setStrokeColor(NSColor(calibratedWhite: 0.26, alpha: 0.40).cgColor)
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

        // 4. Centro Neutro (Puck Glassmorphism com Indicador do Modo)
        drawCenterPuck(context: context, center: center)
    }

    private func drawCenterPuck(context: CGContext, center: CGPoint) {
        // Sombra sob o puck central
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -2), blur: 8, color: NSColor.black.withAlphaComponent(0.5).cgColor)
        context.setFillColor(NSColor(calibratedWhite: 0.15, alpha: 0.98).cgColor)
        context.addArc(center: center, radius: innerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.fillPath()
        context.restoreGState()

        // Borda de destaque do centro com a cor tema do modo
        let accent = modeAccentColor
        context.saveGState()
        context.setStrokeColor(accent.withAlphaComponent(0.70).cgColor)
        context.setLineWidth(1.5)
        context.addArc(center: center, radius: innerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.strokePath()
        context.restoreGState()

        // Ícone SF Symbol do Modo no Topo do Centro
        let modeIconSize: CGFloat = 13.0
        if let sfImage = NSImage(systemSymbolName: modeIconName, accessibilityDescription: nil) {
            let config = NSImage.SymbolConfiguration(pointSize: modeIconSize, weight: .bold)
                .applying(NSImage.SymbolConfiguration(paletteColors: [accent]))
            if let tinted = sfImage.withSymbolConfiguration(config) {
                let iconRect = CGRect(
                    x: center.x - modeIconSize / 2.0,
                    y: center.y + 10,
                    width: modeIconSize,
                    height: modeIconSize
                )
                NSGraphicsContext.saveGraphicsState()
                tinted.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)
                NSGraphicsContext.restoreGraphicsState()
            }
        }

        // Título do Modo Central
        let modeAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10, weight: .bold),
            .foregroundColor: NSColor(calibratedWhite: 0.95, alpha: 1.0)
        ]
        let modeStr = mode.title as NSString
        let modeSize = modeStr.size(withAttributes: modeAttributes)
        let modeRect = CGRect(
            x: center.x - modeSize.width / 2.0,
            y: center.y - 4,
            width: modeSize.width,
            height: modeSize.height
        )
        modeStr.draw(in: modeRect, withAttributes: modeAttributes)

        // Pill / Tecla Modificadora (<kbd>⇧ Shift</kbd>)
        let hintAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 8, weight: .semibold),
            .foregroundColor: NSColor(calibratedWhite: 0.85, alpha: 1.0)
        ]
        let hintStr = mode.shortcutHint as NSString
        let hintSize = hintStr.size(withAttributes: hintAttrs)
        let pillRect = CGRect(
            x: center.x - (hintSize.width + 10) / 2.0,
            y: center.y - 20,
            width: hintSize.width + 10,
            height: hintSize.height + 4
        )

        // Fundo do pill
        context.saveGState()
        context.setFillColor(NSColor(calibratedWhite: 0.25, alpha: 0.75).cgColor)
        let pillPath = CGPath(roundedRect: pillRect, cornerWidth: 3, cornerHeight: 3, transform: nil)
        context.addPath(pillPath)
        context.fillPath()
        context.restoreGState()

        hintStr.draw(
            in: CGRect(x: pillRect.origin.x + 5, y: pillRect.origin.y + 2, width: hintSize.width, height: hintSize.height),
            withAttributes: hintAttrs
        )

        // Indicador de Página (Dots) quando houver mais de 1 página
        let totalPages = max(1, Int(ceil(Double(items.count) / 7.0)))
        if items.count > 8 && totalPages > 1 {
            let dotRadius: CGFloat = 2.0
            let dotSpacing: CGFloat = 6.0
            let totalWidth = CGFloat(totalPages) * (dotRadius * 2) + CGFloat(totalPages - 1) * dotSpacing
            let startX = center.x - totalWidth / 2.0

            for p in 0..<totalPages {
                let dotCenter = CGPoint(x: startX + CGFloat(p) * (dotRadius * 2 + dotSpacing) + dotRadius, y: center.y - 30)
                context.saveGState()
                if p == (currentPageIndex % totalPages) {
                    context.setFillColor(accent.cgColor)
                } else {
                    context.setFillColor(NSColor(calibratedWhite: 0.45, alpha: 0.5).cgColor)
                }
                context.addArc(center: dotCenter, radius: dotRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
                context.fillPath()
                context.restoreGState()
            }
        }
    }

    private var modeIconName: String {
        switch mode {
        case .convert:
            return "arrow.triangle.2.circlepath"
        case .tools:
            return "wrench.and.screwdriver.fill"
        case .actions:
            return "bolt.circle.fill"
        }
    }

    private var modeAccentColor: NSColor {
        switch mode {
        case .convert:
            return NSColor(srgbRed: 0.25, green: 0.65, blue: 1.0, alpha: 1.0)
        case .tools:
            return NSColor(srgbRed: 1.0, green: 0.62, blue: 0.20, alpha: 1.0)
        case .actions:
            return NSColor(srgbRed: 0.35, green: 0.85, blue: 0.45, alpha: 1.0)
        }
    }

    private func categoryColor(for item: RadialItem) -> NSColor {
        let id = item.id.lowercased()
        let target = item.targetExtension.lowercased()

        if id == "page.next" {
            return NSColor(calibratedWhite: 0.90, alpha: 0.9)
        }
        if target == "pdf" || id.contains("pdf") {
            return NSColor(srgbRed: 0.98, green: 0.35, blue: 0.32, alpha: 1.0) // Coral Red
        }
        if ["png", "jpg", "jpeg", "heic", "webp", "avif", "tiff", "bmp"].contains(target) || id.contains("image") || id == "tool.compress" || id == "tool.crop" || id == "tool.adjust" || id == "tool.background" || id == "tool.annotate" {
            return NSColor(srgbRed: 0.30, green: 0.75, blue: 1.00, alpha: 1.0) // Sky Blue
        }
        if target == "md" || target == "txt" || id.contains("ocr") || id.contains("metadata") {
            return NSColor(srgbRed: 0.35, green: 0.88, blue: 0.55, alpha: 1.0) // Emerald Green
        }
        if ["mp4", "mov", "m4v"].contains(target) || id.contains("video") {
            return NSColor(srgbRed: 0.72, green: 0.50, blue: 1.00, alpha: 1.0) // Violet / Purple
        }
        if ["m4a", "wav", "aiff", "mp3"].contains(target) || id.contains("audio") {
            return NSColor(srgbRed: 1.00, green: 0.45, blue: 0.75, alpha: 1.0) // Pink / Magenta
        }
        if ["zip", "tar", "tar.gz"].contains(target) || id.contains("archive") {
            return NSColor(srgbRed: 1.00, green: 0.68, blue: 0.22, alpha: 1.0) // Amber / Orange
        }
        if id.hasPrefix("action.") {
            return NSColor(srgbRed: 0.40, green: 0.65, blue: 1.00, alpha: 1.0) // System Blue
        }
        if id.contains("qr") {
            return NSColor(srgbRed: 0.98, green: 0.85, blue: 0.28, alpha: 1.0) // Gold
        }
        return NSColor(calibratedWhite: 0.92, alpha: 1.0)
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
            // Destaque luminoso translúcido elegante
            context.setFillColor(NSColor.controlAccentColor.withAlphaComponent(0.48).cgColor)
            let path = CGMutablePath()
            path.addArc(center: center, radius: outerRadius - 1.5, startAngle: cgStart, endAngle: cgEnd, clockwise: false)
            path.addArc(center: center, radius: innerRadius + 1.5, startAngle: cgEnd, endAngle: cgStart, clockwise: true)
            path.closeSubpath()
            context.addPath(path)
            context.fillPath()

            // Borda de contorno sutil do setor ativo
            context.setStrokeColor(NSColor.controlAccentColor.withAlphaComponent(0.95).cgColor)
            context.setLineWidth(1.6)
            context.addPath(path)
            context.strokePath()
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

        // 1. Desenhar Ícone SF Symbol com cor categórica correspondente
        let iconSize: CGFloat = (count > 6) ? 15 : 19
        if let sfImage = NSImage(systemSymbolName: item.iconName, accessibilityDescription: nil) {
            let color = isActive ? NSColor.white : categoryColor(for: item)
            let config = NSImage.SymbolConfiguration(pointSize: iconSize, weight: isActive ? .bold : .semibold)
                .applying(NSImage.SymbolConfiguration(paletteColors: [color]))
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

        // 2. Desenhar Título com tipografia nítida e sombra para legibilidade
        let fontSize: CGFloat = (count > 6) ? 10.5 : 12.0
        let textShadow = NSShadow()
        textShadow.shadowOffset = CGSize(width: 0, height: -1)
        textShadow.shadowBlurRadius = 2.0
        textShadow.shadowColor = NSColor.black.withAlphaComponent(0.65)

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: isActive ? .bold : .semibold),
            .foregroundColor: isActive ? NSColor.white : NSColor(calibratedWhite: 0.95, alpha: 1.0),
            .shadow: textShadow
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
