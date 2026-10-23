import Foundation
import UniformTypeIdentifiers

public struct FormatEdge: Sendable, Equatable, Hashable {
    public let sourceType: UTType
    public let targetExtension: String
    public let targetType: UTType
    public let family: FormatFamily
    public let title: String
    public let iconName: String
    public let supportsBatch: Bool

    public init(
        sourceType: UTType,
        targetExtension: String,
        targetType: UTType,
        family: FormatFamily,
        title: String,
        iconName: String,
        supportsBatch: Bool = true
    ) {
        self.sourceType = sourceType
        self.targetExtension = targetExtension.trimmingCharacters(in: CharacterSet(charactersIn: ".")).lowercased()
        self.targetType = targetType
        self.family = family
        self.title = title
        self.iconName = iconName
        self.supportsBatch = supportsBatch
    }
}
