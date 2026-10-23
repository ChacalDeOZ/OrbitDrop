import XCTest
@testable import OrbitDropKit

final class RadialWheelPaginationTests: XCTestCase {
    @MainActor
    func testPaginationWhenItemsCountExceedsEight() {
        let wheel = RadialWheelView(frame: NSRect(x: 0, y: 0, width: 340, height: 340))

        let twelveItems = (1...12).map {
            RadialItem(id: "item.\($0)", title: "Item \($0)", iconName: "star", targetExtension: "")
        }
        wheel.items = twelveItems

        // Página 1: 7 itens + 1 "Mais (1/2)"
        XCTAssertEqual(wheel.displayedItems.count, 8)
        XCTAssertEqual(wheel.displayedItems.last?.id, "page.next")
        XCTAssertTrue(wheel.displayedItems.last?.title.contains("Mais (1/2)") == true)

        // Avançar para página 2
        wheel.cycleNextPage()
        XCTAssertEqual(wheel.currentPageIndex, 1)
        // Página 2: 5 itens restantes + 1 "Mais (2/2)"
        XCTAssertEqual(wheel.displayedItems.count, 6)
        XCTAssertTrue(wheel.displayedItems.last?.title.contains("Mais (2/2)") == true)

        // Ciclar de volta para página 1
        wheel.cycleNextPage()
        XCTAssertEqual(wheel.currentPageIndex, 0)
        XCTAssertEqual(wheel.displayedItems.count, 8)
    }

    @MainActor
    func testNoPaginationWhenItemsCountIsEightOrLess() {
        let wheel = RadialWheelView(frame: NSRect(x: 0, y: 0, width: 340, height: 340))
        let fiveItems = (1...5).map {
            RadialItem(id: "item.\($0)", title: "Item \($0)", iconName: "star", targetExtension: "")
        }
        wheel.items = fiveItems

        XCTAssertEqual(wheel.displayedItems.count, 5)
        XCTAssertFalse(wheel.displayedItems.contains(where: { $0.id == "page.next" }))
    }
}
