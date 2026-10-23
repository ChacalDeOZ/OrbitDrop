import XCTest
import AppKit
@testable import OrbitDropKit

final class CopyActionsTests: XCTestCase {
    @MainActor
    func testCopyActionWritesURLsToPasteboard() {
        let u1 = URL(fileURLWithPath: "/tmp/file1.png")
        let u2 = URL(fileURLWithPath: "/tmp/file2.jpg")

        CopyAction.execute(urls: [u1, u2])

        let pasteboard = NSPasteboard.general
        let readObjects = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL]

        XCTAssertNotNil(readObjects)
        XCTAssertEqual(readObjects?.count, 2)
        XCTAssertEqual(readObjects?[0].path, u1.path)
        XCTAssertEqual(readObjects?[1].path, u2.path)
    }

    @MainActor
    func testCopyPathActionFormatsPathsCorrectly() {
        let u1 = URL(fileURLWithPath: "/Users/test/Documents/photo.png")
        let u2 = URL(fileURLWithPath: "/Users/test/Desktop/doc.pdf")

        let formatted = CopyPathAction.formatPaths(urls: [u1, u2])
        let expected = "/Users/test/Documents/photo.png\n/Users/test/Desktop/doc.pdf"
        XCTAssertEqual(formatted, expected)

        CopyPathAction.execute(urls: [u1, u2])
        let stringContent = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(stringContent, expected)
    }

    func testActionTypeEnumeration() {
        let allActions = ActionType.allCases
        XCTAssertEqual(allActions.count, 6)
        let ids = allActions.map { $0.id }
        XCTAssertTrue(ids.contains("action.copy"))
        XCTAssertTrue(ids.contains("action.copyPath"))
        XCTAssertTrue(ids.contains("action.airDrop"))
        XCTAssertTrue(ids.contains("action.float"))
        XCTAssertTrue(ids.contains("action.move"))
        XCTAssertTrue(ids.contains("action.terminal"))
    }
}
