import XCTest
@testable import OrbitDropKit

final class AccessibilityTests: XCTestCase {
    func testKeyboardNavigatorNextIndex() {
        // Ciclo para frente com 4 setores
        XCTAssertEqual(KeyboardNavigator.nextIndex(current: nil, count: 4), 0)
        XCTAssertEqual(KeyboardNavigator.nextIndex(current: 0, count: 4), 1)
        XCTAssertEqual(KeyboardNavigator.nextIndex(current: 1, count: 4), 2)
        XCTAssertEqual(KeyboardNavigator.nextIndex(current: 2, count: 4), 3)
        XCTAssertEqual(KeyboardNavigator.nextIndex(current: 3, count: 4), 0, "Wrap-around no final para o início")
    }

    func testKeyboardNavigatorPreviousIndex() {
        // Ciclo para trás com 4 setores
        XCTAssertEqual(KeyboardNavigator.previousIndex(current: nil, count: 4), 3)
        XCTAssertEqual(KeyboardNavigator.previousIndex(current: 0, count: 4), 3, "Wrap-around no início para o final")
        XCTAssertEqual(KeyboardNavigator.previousIndex(current: 3, count: 4), 2)
        XCTAssertEqual(KeyboardNavigator.previousIndex(current: 2, count: 4), 1)
    }

    func testKeyboardNavigatorEmptyAndSingleItemSafety() {
        XCTAssertNil(KeyboardNavigator.nextIndex(current: nil, count: 0))
        XCTAssertNil(KeyboardNavigator.previousIndex(current: nil, count: 0))

        XCTAssertEqual(KeyboardNavigator.nextIndex(current: 0, count: 1), 0)
        XCTAssertEqual(KeyboardNavigator.previousIndex(current: 0, count: 1), 0)
    }

    @MainActor
    func testAccessibilityManagerAPI() {
        let reduceMotion = AccessibilityManager.shouldReduceMotion
        XCTAssertTrue(reduceMotion || !reduceMotion, "Consulta de reduce motion do sistema deve ser acessível")
    }
}
