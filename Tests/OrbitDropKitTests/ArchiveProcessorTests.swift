import XCTest
@testable import OrbitDropKit

final class ArchiveProcessorTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropArchiveTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    func testCreateAndExtractZIP() throws {
        let folderToCompress = tempDirectory.appendingPathComponent("MyData")
        try FileManager.default.createDirectory(at: folderToCompress, withIntermediateDirectories: true)

        let fileA = folderToCompress.appendingPathComponent("fileA.txt")
        let fileB = folderToCompress.appendingPathComponent("fileB.txt")
        try "Content A".write(to: fileA, atomically: true, encoding: .utf8)
        try "Content B".write(to: fileB, atomically: true, encoding: .utf8)

        let zipURL = try ArchiveProcessor.createZIP(
            sources: [folderToCompress],
            directory: tempDirectory
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: zipURL.path))
        XCTAssertEqual(zipURL.pathExtension.lowercased(), "zip")

        let extractDir = tempDirectory.appendingPathComponent("Extracted")
        try ArchiveProcessor.extract(
            archiveURL: zipURL,
            destinationDirectory: extractDir
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: extractDir.path))
    }

    func testPathTraversalRejection() {
        // Validação de segurança pura contra "../"
        XCTAssertFalse(ArchiveProcessor.isPathSafe(relativePath: "../escaped.txt"))
        XCTAssertFalse(ArchiveProcessor.isPathSafe(relativePath: "folder/../../escaped.txt"))
        XCTAssertFalse(ArchiveProcessor.isPathSafe(relativePath: "/etc/passwd"))
        XCTAssertTrue(ArchiveProcessor.isPathSafe(relativePath: "subfolder/valid-file.txt"))
        XCTAssertTrue(ArchiveProcessor.isPathSafe(relativePath: "valid-file.txt"))
    }
}
