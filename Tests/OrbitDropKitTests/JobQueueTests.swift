import XCTest
import Foundation
import CoreGraphics
import ImageIO
@testable import OrbitDropKit

final class JobQueueTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OrbitDropJobQueueTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    private func createTestPNG() throws -> URL {
        let fileURL = tempDirectory.appendingPathComponent("fixture-\(UUID().uuidString).png")
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: 32,
            height: 32,
            bitsPerComponent: 8,
            bytesPerRow: 32 * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw XCTSkip("Erro ao criar CGContext")
        }

        context.setFillColor(CGColor(red: 0.1, green: 0.4, blue: 0.9, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: 32, height: 32))

        guard let image = context.makeImage(),
              let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, "public.png" as CFString, 1, nil) else {
            throw XCTSkip("Erro ao criar destino PNG")
        }

        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        return fileURL
    }

    func testBatchEnqueueAndExecution() async throws {
        let f1 = try createTestPNG()
        let f2 = try createTestPNG()
        let queue = JobQueueActor(maxConcurrency: 2)

        let jobID = await queue.enqueue(inputs: [f1, f2], targetExtension: "jpg", directory: tempDirectory)

        // Aguarda execução
        let completedJob = try await queue.waitForCompletion(jobID: jobID, timeoutSeconds: 5.0)

        XCTAssertEqual(completedJob.status, .completed)
        XCTAssertEqual(completedJob.progress, 1.0)
        XCTAssertEqual(completedJob.outputURLs.count, 2)
        for output in completedJob.outputURLs {
            XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
            XCTAssertEqual(output.pathExtension.lowercased(), "jpg")
        }
    }

    func testJobCancellation() async throws {
        let f1 = try createTestPNG()
        let queue = JobQueueActor(maxConcurrency: 1)

        let jobID = await queue.enqueue(inputs: [f1], targetExtension: "jpg", directory: tempDirectory)
        await queue.cancel(jobID: jobID)

        let status = await queue.jobStatus(jobID: jobID)
        XCTAssertTrue(status == .cancelled || status == .completed, "Job cancelado deve ter status cancelled se não finalizou antes")
    }

    func testJobFailureStatusWhenAllInputsFail() async throws {
        let fakeURL = tempDirectory.appendingPathComponent("broken.corrupted")
        try "corrupted bytes".write(to: fakeURL, atomically: true, encoding: .utf8)
        let queue = JobQueueActor(maxConcurrency: 1)

        let jobID = await queue.enqueue(inputs: [fakeURL], targetExtension: "jpg", directory: tempDirectory)
        let result = try await queue.waitForCompletion(jobID: jobID, timeoutSeconds: 5.0)

        XCTAssertEqual(result.status, .failed, "Job deve ter status failed quando todos os inputs falharem")
        XCTAssertTrue(result.outputURLs.isEmpty)
    }

    func testAudioConversionInJobQueue() async throws {
        let wav = try SyntheticMediaGenerator.createWAV(durationSeconds: 0.5, channels: 2, directory: tempDirectory)
        let queue = JobQueueActor(maxConcurrency: 1)

        let jobID = await queue.enqueue(inputs: [wav], targetExtension: "mono", directory: tempDirectory)
        let result = try await queue.waitForCompletion(jobID: jobID, timeoutSeconds: 5.0)

        XCTAssertEqual(result.status, .completed)
        XCTAssertEqual(result.outputURLs.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.outputURLs[0].path))
    }
}
