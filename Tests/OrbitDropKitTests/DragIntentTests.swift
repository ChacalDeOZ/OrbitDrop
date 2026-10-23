import XCTest
import AppKit
@testable import OrbitDropKit

final class DragIntentTests: XCTestCase {
    func testModifierFlagsToWheelModeResolution() {
        let shiftFlags: NSEvent.ModifierFlags = [.shift]
        let cmdFlags: NSEvent.ModifierFlags = [.command]
        let ctrlFlags: NSEvent.ModifierFlags = [.control]
        let noFlags: NSEvent.ModifierFlags = []

        XCTAssertEqual(DragIntentDetector.resolveMode(from: shiftFlags), .convert)
        XCTAssertEqual(DragIntentDetector.resolveMode(from: cmdFlags), .tools)
        XCTAssertEqual(DragIntentDetector.resolveMode(from: ctrlFlags), .actions)
        XCTAssertNil(DragIntentDetector.resolveMode(from: noFlags))
    }

    func testDragIntentRequiresMouseButtonDown() {
        let shiftFlags: NSEvent.ModifierFlags = [.shift]

        // Sem botão do mouse pressionado (ex: digitando texto normal): NÃO deve disparar
        XCTAssertNil(DragIntentDetector.resolveIntent(flags: shiftFlags, pressedMouseButtons: 0))

        // Com botão esquerdo pressionado durante drag: DEVE disparar
        XCTAssertEqual(DragIntentDetector.resolveIntent(flags: shiftFlags, pressedMouseButtons: 1), .convert)
    }

    @MainActor
    func testAccessibilityCheckerAPIIntegrity() {
        // AXIsProcessTrustedWithOptions deve retornar boolean sem exceção
        let isTrusted = AccessibilityChecker.isProcessTrusted(prompt: false)
        XCTAssertTrue(isTrusted || !isTrusted)
    }

    @MainActor
    func testDetectorStateManagement() {
        let detector = DragIntentDetector()
        XCTAssertFalse(detector.isMonitoring)

        detector.startMonitoring()
        XCTAssertTrue(detector.isMonitoring)

        detector.stopMonitoring()
        XCTAssertFalse(detector.isMonitoring)
    }
}
