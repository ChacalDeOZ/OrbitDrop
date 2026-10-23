import XCTest
import UniformTypeIdentifiers
@testable import OrbitDropKit

final class ToolRegistryTests: XCTestCase {
    func testImageToolsFiltering() {
        let png = FileDescriptor(url: URL(fileURLWithPath: "/tmp/photo.png"), contentType: .png)
        let tools = ToolRegistry.availableTools(for: [png])

        let ids = tools.map { $0.id }
        XCTAssertTrue(ids.contains("tool.crop"))
        XCTAssertTrue(ids.contains("tool.adjust"))
        XCTAssertTrue(ids.contains("tool.ocr"))
        XCTAssertFalse(ids.contains("tool.video.trim"), "Ferramentas de vídeo não devem aparecer para imagens")
        XCTAssertFalse(ids.contains("tool.pdf.merge"))
    }

    func testVideoToolsFiltering() {
        let mov = FileDescriptor(url: URL(fileURLWithPath: "/tmp/video.mov"), contentType: .quickTimeMovie)
        let tools = ToolRegistry.availableTools(for: [mov])

        let ids = tools.map { $0.id }
        XCTAssertTrue(ids.contains("tool.video.trim"))
        XCTAssertTrue(ids.contains("tool.video.speed"))
        XCTAssertFalse(ids.contains("tool.adjust"), "Ajustes de imagem não devem aparecer para vídeos")
    }

    func testPDFToolsFiltering() {
        let pdf1 = FileDescriptor(url: URL(fileURLWithPath: "/tmp/doc1.pdf"), contentType: .pdf)
        let pdf2 = FileDescriptor(url: URL(fileURLWithPath: "/tmp/doc2.pdf"), contentType: .pdf)

        let tools = ToolRegistry.availableTools(for: [pdf1, pdf2])
        let ids = tools.map { $0.id }
        XCTAssertTrue(ids.contains("tool.pdf.merge"), "Seleção de múltiplos PDFs deve conter Merge")
        XCTAssertTrue(ids.contains("tool.ocr"))
        XCTAssertFalse(ids.contains("tool.video.trim"))
    }
}
