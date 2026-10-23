import XCTest
import Foundation
@testable import OrbitDropKit

final class OutputWriterTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropOutputWriterTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    func testDestinationURLNaming() {
        let sourceURL = tempDirectory.appendingPathComponent("nature.png")
        let destination = OutputWriter.destinationURL(
            for: sourceURL,
            targetExtension: "jpg",
            directory: tempDirectory
        )
        XCTAssertEqual(destination.lastPathComponent, "nature-converted.jpg")
    }

    func testCollisionResolutionWithMultipleExistingFiles() throws {
        let sourceURL = tempDirectory.appendingPathComponent("report.png")

        // Simular arquivos existentes
        let file1 = tempDirectory.appendingPathComponent("report-converted.jpg")
        let file2 = tempDirectory.appendingPathComponent("report-converted-2.jpg")
        try "dummy1".write(to: file1, atomically: true, encoding: .utf8)
        try "dummy2".write(to: file2, atomically: true, encoding: .utf8)

        let resolved = OutputWriter.destinationURL(
            for: sourceURL,
            targetExtension: "jpg",
            directory: tempDirectory
        )

        XCTAssertEqual(resolved.lastPathComponent, "report-converted-3.jpg")
    }

    func testAtomicPromotionWithStagingFile() throws {
        let sourceURL = tempDirectory.appendingPathComponent("document.png")
        let destination = OutputWriter.destinationURL(for: sourceURL, targetExtension: "jpg", directory: tempDirectory)

        let finalURL = try OutputWriter.withStagingFile(targetURL: destination) { stagingURL in
            try "converted content".write(to: stagingURL, atomically: true, encoding: .utf8)
        }

        XCTAssertEqual(finalURL, destination)
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path))
        let content = try String(contentsOf: destination, encoding: .utf8)
        XCTAssertEqual(content, "converted content")
    }

    func testCleanupOnFailureWithoutTouchingDestination() {
        let sourceURL = tempDirectory.appendingPathComponent("sample.png")
        let destination = OutputWriter.destinationURL(for: sourceURL, targetExtension: "jpg", directory: tempDirectory)

        enum DummyError: Error { case failedConversion }

        XCTAssertThrowsError(
            try OutputWriter.withStagingFile(targetURL: destination) { stagingURL in
                try "partial bytes".write(to: stagingURL, atomically: true, encoding: .utf8)
                throw DummyError.failedConversion
            }
        )

        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path), "Destino não pode existir se o job falhar")
    }
}
