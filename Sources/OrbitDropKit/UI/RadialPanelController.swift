import Foundation
import AppKit

@MainActor
public final class FocusableNonActivatingPanel: NSPanel {
    public override var canBecomeKey: Bool {
        true
    }
}

@MainActor
public final class RadialPanelController {
    public private(set) var panel: NSPanel
    public let wheelView: RadialWheelView
    public let panelSize: CGFloat = 340.0

    public init() {
        let contentRect = NSRect(x: 0, y: 0, width: panelSize, height: panelSize)
        panel = FocusableNonActivatingPanel(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = false
        panel.ignoresMouseEvents = false
        panel.acceptsMouseMovedEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]

        wheelView = RadialWheelView(frame: contentRect)
        panel.contentView = wheelView
    }

    /// Exibe o painel radial ancorado na coordenada de tela do cursor.
    /// Se já estiver visível, mantém a âncora fixa para permitir que o cursor alcance os setores.
    public func show(
        at cursorLocation: CGPoint,
        mode: WheelMode,
        items: [RadialItem],
        forceReposition: Bool = false
    ) {
        if isVisible && !forceReposition {
            // Roda já ancorada no ponto original: apenas atualiza modo e itens se mudarem
            if wheelView.mode != mode || wheelView.items != items {
                wheelView.mode = mode
                wheelView.items = items
            }
            return
        }

        wheelView.mode = mode
        wheelView.items = items

        let screen = NSScreen.screens.first(where: { NSMouseInRect(cursorLocation, $0.frame, false) }) ?? NSScreen.main
        let screenFrame = screen?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)

        let clamped = RadialGeometry.clampedCenter(
            cursor: cursorLocation,
            screenFrame: screenFrame,
            wheelRadius: panelSize / 2.0,
            margin: 20.0
        )

        let origin = CGPoint(
            x: clamped.x - (panelSize / 2.0),
            y: clamped.y - (panelSize / 2.0)
        )

        panel.setFrameOrigin(origin)
        panel.orderFrontRegardless()
        panel.makeKey()
        panel.makeFirstResponder(wheelView)
    }

    /// Oculta o painel radial.
    public func hide() {
        panel.orderOut(nil)
        wheelView.activeSectorIndex = nil
    }

    public var isVisible: Bool {
        panel.isVisible
    }
}
