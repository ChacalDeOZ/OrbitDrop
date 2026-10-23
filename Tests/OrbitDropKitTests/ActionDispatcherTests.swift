import XCTest
import AppKit
@testable import OrbitDropKit

final class ActionDispatcherTests: XCTestCase {
    func testAvailableActionsCountAndItems() {
        let items = ActionDispatcher.availableActions()
        XCTAssertEqual(items.count, 6)
        let ids = items.map { $0.id }
        XCTAssertTrue(ids.contains("action.airDrop"))
        XCTAssertTrue(ids.contains("action.float"))
        XCTAssertTrue(ids.contains("action.copy"))
        XCTAssertTrue(ids.contains("action.move"))
        XCTAssertTrue(ids.contains("action.copyPath"))
        XCTAssertTrue(ids.contains("action.terminal"))
    }

    @MainActor
    func testFloatShelfStateManagement() {
        let shelf = FloatShelfController()
        XCTAssertEqual(shelf.items.count, 0)

        let u1 = URL(fileURLWithPath: "/tmp/sample1.png")
        let u2 = URL(fileURLWithPath: "/tmp/sample2.pdf")
        shelf.add(files: [u1, u2])

        XCTAssertEqual(shelf.items.count, 2)
        XCTAssertEqual(shelf.items[0].url.path, u1.path)
        XCTAssertEqual(shelf.items[1].url.path, u2.path)

        shelf.remove(at: 0)
        XCTAssertEqual(shelf.items.count, 1)
        XCTAssertEqual(shelf.items[0].url.path, u2.path)

        shelf.clear()
        XCTAssertEqual(shelf.items.count, 0)
    }

    func testAirDropActionFeasibilityCheck() {
        let u1 = URL(fileURLWithPath: "/tmp/photo.jpg")
        XCTAssertTrue(AirDropAction.canShare(files: [u1]))
        XCTAssertFalse(AirDropAction.canShare(files: []))
    }
}
