import Foundation
import AppKit

@MainActor
public final class RadialSectorAccessibilityElement: NSAccessibilityElement {
    public var item: RadialItem?
    public var onPress: ((RadialItem) -> Void)?

    public override func accessibilityPerformPress() -> Bool {
        guard let it = item else { return false }
        onPress?(it)
        return true
    }
}
