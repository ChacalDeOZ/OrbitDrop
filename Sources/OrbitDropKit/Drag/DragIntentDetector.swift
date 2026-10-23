import Foundation
import AppKit

@MainActor
public final class DragIntentDetector {
    public private(set) var isMonitoring: Bool = false
    public var onModeTriggered: ((WheelMode, CGPoint) -> Void)?
    public var onDragCancelled: (() -> Void)?
    public var onMouseUp: ((CGPoint) -> Void)?
    public var onNavigateNext: (() -> Void)?
    public var onNavigatePrevious: (() -> Void)?
    public var onSelectActive: (() -> Void)?

    private var globalFlagsMonitor: Any?
    private var globalMouseMonitor: Any?
    private var globalMouseUpMonitor: Any?
    private var globalKeyMonitor: Any?
    private var localFlagsMonitor: Any?
    private var localMouseUpMonitor: Any?
    private var localKeyMonitor: Any?

    public init() {}

    isolated deinit {
        stopMonitoring()
    }

    /// Mapeia flags modificadoras para o modo correspondente do menu radial (puro / thread-safe).
    nonisolated public static func resolveMode(from flags: NSEvent.ModifierFlags) -> WheelMode? {
        if flags.contains(.shift) {
            return .convert
        } else if flags.contains(.command) {
            return .tools
        } else if flags.contains(.control) {
            return .actions
        }
        return nil
    }

    /// Determina intenção de arrasto exigindo que o botão esquerdo do mouse esteja pressionado.
    nonisolated public static func resolveIntent(flags: NSEvent.ModifierFlags, pressedMouseButtons: Int) -> WheelMode? {
        guard (pressedMouseButtons & 1) != 0 else { return nil }
        return resolveMode(from: flags)
    }

    /// Inicia o monitoramento de eventos de teclado e mouse.
    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        // Monitor global de flags (só aciona se botão do mouse estiver pressionado)
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event.modifierFlags)
        }

        // Monitor global de arrasto
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] _ in
            self?.handleMouseDragged()
        }

        // Monitor global de soltura do mouse
        globalMouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] _ in
            let loc = NSEvent.mouseLocation
            self?.onMouseUp?(loc)
        }

        // Monitor global de teclas (Esc, Setas e Enter)
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event)
        }

        // Monitores locais para eventos dentro da aplicação
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event.modifierFlags)
            return event
        }

        localMouseUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            let loc = NSEvent.mouseLocation
            self?.onMouseUp?(loc)
            return event
        }

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event)
            return event
        }
    }

    private func handleKeyDown(_ event: NSEvent) {
        switch event.keyCode {
        case 53: // Escape
            onDragCancelled?()
        case 123, 126: // Seta Esquerda ou Cima
            onNavigatePrevious?()
        case 124, 125: // Seta Direita ou Baixo
            onNavigateNext?()
        case 36, 49: // Enter ou Espaço
            onSelectActive?()
        default:
            break
        }
    }

    /// Interrompe todos os monitores de eventos registrados.
    public func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false

        if let m = globalFlagsMonitor { NSEvent.removeMonitor(m); globalFlagsMonitor = nil }
        if let m = globalMouseMonitor { NSEvent.removeMonitor(m); globalMouseMonitor = nil }
        if let m = globalMouseUpMonitor { NSEvent.removeMonitor(m); globalMouseUpMonitor = nil }
        if let m = globalKeyMonitor { NSEvent.removeMonitor(m); globalKeyMonitor = nil }
        if let m = localFlagsMonitor { NSEvent.removeMonitor(m); localFlagsMonitor = nil }
        if let m = localMouseUpMonitor { NSEvent.removeMonitor(m); localMouseUpMonitor = nil }
        if let m = localKeyMonitor { NSEvent.removeMonitor(m); localKeyMonitor = nil }
    }

    private func handleFlagsChanged(_ flags: NSEvent.ModifierFlags) {
        let buttons = NSEvent.pressedMouseButtons
        if let mode = Self.resolveIntent(flags: flags, pressedMouseButtons: buttons) {
            let cursor = NSEvent.mouseLocation
            onModeTriggered?(mode, cursor)
        } else if Self.resolveMode(from: flags) == nil {
            // Se as teclas modificadoras foram soltas pelo usuário, fecha o menu automaticamente
            onDragCancelled?()
        }
    }

    private func handleMouseDragged() {
        let currentFlags = NSEvent.modifierFlags
        let buttons = NSEvent.pressedMouseButtons
        if let mode = Self.resolveIntent(flags: currentFlags, pressedMouseButtons: buttons) {
            let cursor = NSEvent.mouseLocation
            onModeTriggered?(mode, cursor)
        }
    }
}
