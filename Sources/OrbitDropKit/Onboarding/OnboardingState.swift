import Foundation

public final class OnboardingState: @unchecked Sendable {
    public static let shared = OnboardingState()

    private let userDefaults: UserDefaults
    private let completionKey = "com.orbitdrop.hasCompletedOnboarding"
    private let lock = NSLock()

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public var hasCompletedOnboarding: Bool {
        lock.lock()
        defer { lock.unlock() }
        return userDefaults.bool(forKey: completionKey)
    }

    public func markCompleted() {
        lock.lock()
        defer { lock.unlock() }
        userDefaults.set(true, forKey: completionKey)
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        userDefaults.removeObject(forKey: completionKey)
    }
}
