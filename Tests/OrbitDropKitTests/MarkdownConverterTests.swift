import XCTest
@testable import OrbitDropKit

final class MarkdownConverterTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropMarkdownTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    func testConvertHTMLToMarkdown() throws {
        let html = """
        <html>
        <body>
        <h1>Título Principal</h1>
        <p>Este é um parágrafo com <strong>texto em negrito</strong> e <em>itálico</em>.</p>
        <ul>
            <li>Item 1</li>
            <li>Item 2</li>
        </ul>
        </body>
        </html>
        """
        let htmlURL = tempDirectory.appendingPathComponent("document.html")
        try html.write(to: htmlURL, atomically: true, encoding: .utf8)

        let mdURL = try MarkdownConverter.convertToMarkdown(sourceURL: htmlURL, directory: tempDirectory)

        XCTAssertTrue(FileManager.default.fileExists(atPath: mdURL.path))
        XCTAssertEqual(mdURL.pathExtension.lowercased(), "md")

        let content = try String(contentsOf: mdURL, encoding: .utf8)
        XCTAssertTrue(content.contains("# Título Principal"))
        XCTAssertTrue(content.contains("**texto em negrito**"))
        XCTAssertTrue(content.contains("*itálico*"))
        XCTAssertTrue(content.contains("- Item 1"))
    }

    func testConvertPlainTextToMarkdown() throws {
        let plainText = "Texto simples de anotação sem tags."
        let txtURL = tempDirectory.appendingPathComponent("notes.txt")
        try plainText.write(to: txtURL, atomically: true, encoding: .utf8)

        let mdURL = try MarkdownConverter.convertToMarkdown(sourceURL: txtURL, directory: tempDirectory)
        XCTAssertTrue(FileManager.default.fileExists(atPath: mdURL.path))

        let content = try String(contentsOf: mdURL, encoding: .utf8)
        XCTAssertTrue(content.contains("Texto simples de anotação sem tags."))
    }

    func testConvertSourceCodeToMarkdownFencedBlock() throws {
        let code = "func hello() { print(\"Hi\") }"
        let codeURL = tempDirectory.appendingPathComponent("script.swift")
        try code.write(to: codeURL, atomically: true, encoding: .utf8)

        let mdURL = try MarkdownConverter.convertToMarkdown(sourceURL: codeURL, directory: tempDirectory)
        let content = try String(contentsOf: mdURL, encoding: .utf8)

        XCTAssertTrue(content.contains("```swift"))
        XCTAssertTrue(content.contains("func hello()"))
    }
}
