import XCTest
import Foundation
@testable import OrbitDropKit

final class TerminalAndMoveTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropTerminalAndMoveTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    func testTerminalActionTargetDirectory() {
        let subfolder = tempDirectory.appendingPathComponent("MyProject")
        try? FileManager.default.createDirectory(at: subfolder, withIntermediateDirectories: true)

        let fileInSubfolder = subfolder.appendingPathComponent("index.swift")
        try? "content".write(to: fileInSubfolder, atomically: true, encoding: .utf8)

        // Pasta: retorna a própria pasta
        let dirResult = TerminalAction.targetDirectory(for: subfolder)
        XCTAssertEqual(dirResult.path, subfolder.path)

        // Arquivo: retorna o diretório pai
        let fileResult = TerminalAction.targetDirectory(for: fileInSubfolder)
        XCTAssertEqual(fileResult.path, subfolder.path)
    }

    func testMoveActionTransfersFilesSafely() throws {
        let sourceDir = tempDirectory.appendingPathComponent("Source")
        let destDir = tempDirectory.appendingPathComponent("Destination")
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

        let fileA = sourceDir.appendingPathComponent("document.pdf")
        try "pdf bytes".write(to: fileA, atomically: true, encoding: .utf8)

        let movedURLs = try MoveAction.move(files: [fileA], to: destDir)

        XCTAssertEqual(movedURLs.count, 1)
        let destinationFile = movedURLs[0]
        XCTAssertEqual(destinationFile.lastPathComponent, "document.pdf")
        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationFile.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileA.path), "Original deve ser removido após Move")
    }

    func testMoveActionResolvesCollisionsAtDestination() throws {
        let sourceDir = tempDirectory.appendingPathComponent("Source")
        let destDir = tempDirectory.appendingPathComponent("Destination")
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

        let existing = destDir.appendingPathComponent("notes.txt")
        try "existing notes".write(to: existing, atomically: true, encoding: .utf8)

        let fileToMove = sourceDir.appendingPathComponent("notes.txt")
        try "new notes".write(to: fileToMove, atomically: true, encoding: .utf8)

        let movedURLs = try MoveAction.move(files: [fileToMove], to: destDir)

        XCTAssertEqual(movedURLs.count, 1)
        let destinationFile = movedURLs[0]
        XCTAssertEqual(destinationFile.lastPathComponent, "notes-2.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationFile.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileToMove.path))
    }
}
