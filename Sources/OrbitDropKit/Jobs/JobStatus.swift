import Foundation

public enum JobStatus: String, Sendable, Codable, Equatable {
    case queued
    case running
    case completed
    case failed
    case cancelled
}
