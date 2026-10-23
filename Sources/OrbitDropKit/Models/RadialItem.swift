import Foundation

public struct RadialItem: Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let iconName: String
    public let targetExtension: String
    public let isAvailable: Bool

    public init(
        id: String,
        title: String,
        iconName: String,
        targetExtension: String,
        isAvailable: Bool = true
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.targetExtension = targetExtension
        self.isAvailable = isAvailable
    }
}
