import XCTest
@testable import OrbitDropKit

final class SettingsTests: XCTestCase {
    var testDefaults: UserDefaults!
    let suiteName = "OrbitDropSettingsTests-\(UUID().uuidString)"

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        testDefaults?.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testDefaultSettingsValues() {
        let manager = SettingsManager(userDefaults: testDefaults)
        let settings = manager.settings

        XCTAssertTrue(settings.saveBesideOriginal)
        XCTAssertNil(settings.customOutputDirectory)
        XCTAssertFalse(settings.revealInFinderOnComplete)
        XCTAssertFalse(settings.preferITerm)
        XCTAssertEqual(settings.maxConcurrency, 4)
    }

    func testUpdateAndPersistSettings() {
        let manager = SettingsManager(userDefaults: testDefaults)

        var newSettings = manager.settings
        newSettings.saveBesideOriginal = false
        newSettings.customOutputDirectory = "/Users/test/Converted"
        newSettings.revealInFinderOnComplete = true
        newSettings.preferITerm = true
        newSettings.maxConcurrency = 8

        manager.update(newSettings)

        // Criar nova instância lendo do mesmo suite para testar persistência real
        let reloadedManager = SettingsManager(userDefaults: testDefaults)
        let loaded = reloadedManager.settings

        XCTAssertFalse(loaded.saveBesideOriginal)
        XCTAssertEqual(loaded.customOutputDirectory, "/Users/test/Converted")
        XCTAssertTrue(loaded.revealInFinderOnComplete)
        XCTAssertTrue(loaded.preferITerm)
        XCTAssertEqual(loaded.maxConcurrency, 8)
    }
}
