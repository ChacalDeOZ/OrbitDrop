import Foundation
import AppKit

public final class RadialSectorAccessibilityElement: NSAccessibilityElement, @unchecked Sendable {
    public var item: RadialItem?
    public weak var actionTarget: AnyObject?
    public var actionSelector: Selector?

    public override func accessibilityPerformPress() -> Bool {
        guard let target = actionTarget, let selector = actionSelector else { return false }
        if Thread.isMainThread {
            _ = target.perform(selector, with: item)
        } else {
            DispatchQueue.main.sync {
                _ = target.perform(selector, with: self.item)
            }
        }
        return true
    }
}
