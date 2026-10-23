import XCTest
import UniformTypeIdentifiers
@testable import OrbitDropKit

final class FormatRegistryTests: XCTestCase {
    func testSinglePNGAvailableTargets() {
        let pngFile = FileDescriptor(
            url: URL(fileURLWithPath: "/tmp/sample.png"),
            contentType: .png
        )

        let registry = FormatRegistry.defaultRegistry()
        let targets = registry.availableTargets(for: [pngFile])

        XCTAssertFalse(targets.isEmpty)
        let extensions = targets.map { $0.targetExtension.lowercased() }
        XCTAssertTrue(extensions.contains("jpg"))
        XCTAssertTrue(extensions.contains("tiff"))
        XCTAssertTrue(extensions.contains("bmp"))
    }

    func testMultiFileCommonTargetsIntersection() {
        let pngFile = FileDescriptor(
            url: URL(fileURLWithPath: "/tmp/photo1.png"),
            contentType: .png
        )
        let heicFile = FileDescriptor(
            url: URL(fileURLWithPath: "/tmp/photo2.heic"),
            contentType: .heic
        )

        let registry = FormatRegistry.defaultRegistry()
        let commonTargets = registry.availableTargets(for: [pngFile, heicFile])

        // Ambos suportam exportação para JPEG:
        let extensions = commonTargets.map { $0.targetExtension.lowercased() }
        XCTAssertTrue(extensions.contains("jpg"))
    }

    func testDisjointTypesReturnEmptyIntersection() {
        let pngFile = FileDescriptor(
            url: URL(fileURLWithPath: "/tmp/image.png"),
            contentType: .png
        )
        let textFile = FileDescriptor(
            url: URL(fileURLWithPath: "/tmp/notes.txt"),
            contentType: .plainText
        )

        let registry = FormatRegistry.defaultRegistry()
        let commonTargets = registry.availableTargets(for: [pngFile, textFile])

        let nonArchive = commonTargets.filter { $0.targetExtension != "zip" && $0.targetExtension != "tar.gz" }
        XCTAssertTrue(nonArchive.isEmpty, "Arquivos sem formato comum não devem ter rotas de mídia em comum")
    }

    func testGenericDataOrUnknownExtensionDoesNotMatchImages() {
        let binFile = FileDescriptor(
            url: URL(fileURLWithPath: "/tmp/firmware.bin"),
            contentType: .data
        )

        let registry = FormatRegistry.defaultRegistry()
        let targets = registry.availableTargets(for: [binFile])

        let imageTargets = targets.filter { ["jpg", "png", "tiff", "bmp"].contains($0.targetExtension) }
        XCTAssertTrue(imageTargets.isEmpty, "Arquivo binário genérico (.data) não deve gerar rotas de imagem falsas")
    }

    func testFolderNamedAsImageExtensionDoesNotMatch() {
        let folder = FileDescriptor(
            url: URL(fileURLWithPath: "/tmp/Album.png"),
            contentType: .png,
            isDirectory: true
        )

        let registry = FormatRegistry.defaultRegistry()
        let targets = registry.availableTargets(for: [folder])

        let imageTargets = targets.filter { ["jpg", "png", "tiff", "bmp"].contains($0.targetExtension) }
        XCTAssertTrue(imageTargets.isEmpty, "Pastas não podem ser tratadas como arquivos de imagem para conversão")
    }

    func testPDFAvailableTargetsIncludeMarkdown() {
        let pdfFile = FileDescriptor(
            url: URL(fileURLWithPath: "/tmp/document.pdf"),
            contentType: .pdf
        )

        let targets = FormatRegistry.defaultRegistry().availableTargets(for: [pdfFile])
        XCTAssertTrue(targets.contains(where: { $0.targetExtension == "md" && $0.title == "Markdown" }))
    }
}
