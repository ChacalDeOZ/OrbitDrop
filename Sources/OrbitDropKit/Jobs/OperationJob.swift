import Foundation

public struct OperationJob: Sendable, Identifiable, Equatable {
    public let id: UUID
    public let inputs: [URL]
    public let targetExtension: String
    public let directory: URL?
    public var status: JobStatus
    public var progress: Double
    public var outputURLs: [URL]
    public var errorMessage: String?
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        inputs: [URL],
        targetExtension: String,
        directory: URL? = nil,
        status: JobStatus = .queued,
        progress: Double = 0.0,
        outputURLs: [URL] = [],
        errorMessage: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.inputs = inputs
        self.targetExtension = targetExtension
        self.directory = directory
        self.status = status
        self.progress = progress
        self.outputURLs = outputURLs
        self.errorMessage = errorMessage
        self.createdAt = createdAt
    }
}
