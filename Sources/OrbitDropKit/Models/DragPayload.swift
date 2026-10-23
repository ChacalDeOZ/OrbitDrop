import Foundation

public struct DragPayload: Sendable, Equatable {
    public let files: [FileDescriptor]
    public let sourceApp: String?
    public let timestamp: Date

    public init(
        files: [FileDescriptor],
        sourceApp: String? = nil,
        timestamp: Date = Date()
    ) {
        self.files = files
        self.sourceApp = sourceApp
        self.timestamp = timestamp
    }
}
