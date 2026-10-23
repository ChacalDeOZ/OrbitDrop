import Foundation

public struct AppSettings: Sendable, Codable, Equatable {
    public var saveBesideOriginal: Bool
    public var customOutputDirectory: String?
    public var revealInFinderOnComplete: Bool
    public var preferITerm: Bool
    public var maxConcurrency: Int

    public init(
        saveBesideOriginal: Bool = true,
        customOutputDirectory: String? = nil,
        revealInFinderOnComplete: Bool = true,
        preferITerm: Bool = false,
        maxConcurrency: Int = 4
    ) {
        self.saveBesideOriginal = saveBesideOriginal
        self.customOutputDirectory = customOutputDirectory
        self.revealInFinderOnComplete = revealInFinderOnComplete
        self.preferITerm = preferITerm
        self.maxConcurrency = maxConcurrency
    }
}
