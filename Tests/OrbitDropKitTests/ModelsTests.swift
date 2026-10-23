import XCTest
import Foundation
import UniformTypeIdentifiers
@testable import OrbitDropKit

final class ModelsTests: XCTestCase {
    func testFileDescriptorInitialization() {
        let tempURL = URL(fileURLWithPath: "/tmp/sample.png")
        let descriptor = FileDescriptor(
            url: tempURL,
            displayName: "sample.png",
            fileSize: 1024,
            contentType: .png,
            isDirectory: false
        )

        XCTAssertEqual(descriptor.url, tempURL)
        XCTAssertEqual(descriptor.displayName, "sample.png")
        XCTAssertEqual(descriptor.fileSize, 1024)
        XCTAssertEqual(descriptor.contentType, .png)
        XCTAssertFalse(descriptor.isDirectory)
    }

    func testDragPayloadCreation() {
        let tempURL = URL(fileURLWithPath: "/tmp/photo.heic")
        let descriptor = FileDescriptor(url: tempURL)
        let payload = DragPayload(
            files: [descriptor],
            sourceApp: "com.apple.finder"
        )

        XCTAssertEqual(payload.files.count, 1)
        XCTAssertEqual(payload.files.first?.url, tempURL)
        XCTAssertEqual(payload.sourceApp, "com.apple.finder")
    }

    func testWheelModeKeys() {
        XCTAssertEqual(WheelMode.convert.title, "Converter")
        XCTAssertEqual(WheelMode.tools.title, "Ferramentas")
        XCTAssertEqual(WheelMode.actions.title, "Ações")
    }

    func testRadialItemCreation() {
        let item = RadialItem(
            id: "convert.jpeg",
            title: "JPEG",
            iconName: "photo",
            targetExtension: "jpg",
            isAvailable: true
        )

        XCTAssertEqual(item.id, "convert.jpeg")
        XCTAssertEqual(item.targetExtension, "jpg")
        XCTAssertTrue(item.isAvailable)
    }
}
