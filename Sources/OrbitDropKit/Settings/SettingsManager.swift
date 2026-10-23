import Foundation

public final class SettingsManager: @unchecked Sendable {
    public static let shared = SettingsManager()

    private let userDefaults: UserDefaults
    private let storageKey = "com.orbitdrop.settings"
    private let lock = NSLock()
    private var cachedSettings: AppSettings

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let data = userDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.cachedSettings = decoded
        } else {
            self.cachedSettings = AppSettings()
        }
    }

    public var settings: AppSettings {
        lock.lock()
        defer { lock.unlock() }
        return cachedSettings
    }

    public func update(_ newSettings: AppSettings) {
        lock.lock()
        defer { lock.unlock() }
        self.cachedSettings = newSettings
        if let data = try? JSONEncoder().encode(newSettings) {
            userDefaults.set(data, forKey: storageKey)
        }
    }
}
