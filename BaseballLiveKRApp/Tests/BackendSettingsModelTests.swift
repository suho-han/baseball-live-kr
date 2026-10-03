import Foundation
import XCTest
@testable import BaseballLiveKR

@MainActor
final class BackendSettingsModelTests: XCTestCase {
    func testFirstLaunchDefaultsToProductionWhenGenericBaseURLEnvironmentExists() {
        let previousValue = getenv("BASEBALL_LIVE_KR_BASE_URL").map { String(cString: $0) }
        setenv("BASEBALL_LIVE_KR_BASE_URL", "http://127.0.0.1:17361", 1)
        defer {
            if let previousValue {
                setenv("BASEBALL_LIVE_KR_BASE_URL", previousValue, 1)
            } else {
                unsetenv("BASEBALL_LIVE_KR_BASE_URL")
            }
        }

        let defaults = UserDefaults(suiteName: "BackendSettingsModelTests.firstLaunchDefaultsToProduction")!
        defaults.removePersistentDomain(forName: "BackendSettingsModelTests.firstLaunchDefaultsToProduction")
        defer {
            defaults.removePersistentDomain(forName: "BackendSettingsModelTests.firstLaunchDefaultsToProduction")
        }

        let settings = BackendSettingsModel(defaults: defaults)

        XCTAssertEqual(settings.selectedPreset, .production)
        XCTAssertEqual(settings.effectiveBaseURL, BaseballLiveKREnvironment.productionBaseURL)
        XCTAssertEqual(BackendSettingsModel.resolvedBaseURL(defaults: defaults), BaseballLiveKREnvironment.productionBaseURL)
    }

    func testStagingPresetIsSelectableAndLocalStaysLocked() {
        let (defaults, cleanup) = makeIsolatedDefaults("BackendSettingsModelTests.stagingSelectable")
        defer { cleanup() }

        let settings = BackendSettingsModel(defaults: defaults)

        XCTAssertTrue(settings.isPresetSelectable(.staging))
        XCTAssertTrue(settings.selectPreset(.staging))
        XCTAssertEqual(settings.selectedPreset, .staging)
        XCTAssertEqual(settings.effectiveBaseURL, BaseballLiveKREnvironment.stagingBaseURL)

        XCTAssertFalse(settings.isPresetSelectable(.local))
        XCTAssertFalse(settings.selectPreset(.local))
        XCTAssertEqual(settings.selectedPreset, .staging)
    }

    func testStagingPresetUsesInjectedEnvironmentURL() {
        let environmentName = BaseballLiveKREnvironment.stagingBaseURLEnvironmentName
        let previousValue = getenv(environmentName).map { String(cString: $0) }
        setenv(environmentName, "http://127.0.0.1:17362", 1)
        defer {
            if let previousValue {
                setenv(environmentName, previousValue, 1)
            } else {
                unsetenv(environmentName)
            }
        }

        let (defaults, cleanup) = makeIsolatedDefaults("BackendSettingsModelTests.stagingEnvironmentURL")
        defer { cleanup() }

        let settings = BackendSettingsModel(defaults: defaults)

        XCTAssertTrue(settings.selectPreset(.staging))
        XCTAssertEqual(settings.effectiveBaseURL, URL(string: "http://127.0.0.1:17362"))
    }

    func testStoredStagingPresetIsHonoredOnLaunch() {
        let (defaults, cleanup) = makeIsolatedDefaults("BackendSettingsModelTests.stagingStored")
        defer { cleanup() }

        defaults.set("staging", forKey: "baseball-live-kr.backend-preset")

        let settings = BackendSettingsModel(defaults: defaults)

        XCTAssertEqual(settings.selectedPreset, .staging)
    }

    func testSavePersistsStagingPreset() {
        let (defaults, cleanup) = makeIsolatedDefaults("BackendSettingsModelTests.stagingSave")
        defer { cleanup() }

        let settings = BackendSettingsModel(defaults: defaults)
        XCTAssertTrue(settings.selectPreset(.staging))
        XCTAssertTrue(settings.save())

        let reloaded = BackendSettingsModel(defaults: defaults)

        XCTAssertEqual(reloaded.selectedPreset, .staging)
    }

    private func makeIsolatedDefaults(_ name: String) -> (UserDefaults, () -> Void) {
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return (defaults, { defaults.removePersistentDomain(forName: name) })
    }
}
