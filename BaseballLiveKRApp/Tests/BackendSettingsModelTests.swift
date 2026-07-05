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
}
