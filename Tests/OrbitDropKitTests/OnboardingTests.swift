import XCTest
@testable import OrbitDropKit

final class OnboardingTests: XCTestCase {
    var testDefaults: UserDefaults!
    let suiteName = "OrbitDropOnboardingTests-\(UUID().uuidString)"

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        testDefaults?.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testOnboardingStepsSequence() {
        let steps = OnboardingStep.allCases
        XCTAssertEqual(steps.count, 5, "Prompt Mestre exige exatamente 5 passos de onboarding")
        XCTAssertEqual(steps[0], .welcome)
        XCTAssertEqual(steps[1], .interactiveDemo)
        XCTAssertEqual(steps[2], .permissions)
        XCTAssertEqual(steps[3], .firstTest)
        XCTAssertEqual(steps[4], .completed)
    }

    func testOnboardingStatePersistence() {
        let state = OnboardingState(userDefaults: testDefaults)
        XCTAssertFalse(state.hasCompletedOnboarding, "Inicialmente não deve estar completo")

        state.markCompleted()
        XCTAssertTrue(state.hasCompletedOnboarding)

        let reloaded = OnboardingState(userDefaults: testDefaults)
        XCTAssertTrue(reloaded.hasCompletedOnboarding, "Deve persistir estado completo no UserDefaults")
    }
}
