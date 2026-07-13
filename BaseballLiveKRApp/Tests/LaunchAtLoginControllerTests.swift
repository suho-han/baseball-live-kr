import XCTest
@testable import BaseballLiveKR

@MainActor
final class LaunchAtLoginControllerTests: XCTestCase {
    func testNotFoundLoginItemStaysToggleOnSoOffCanUnregister() {
        let presentation = LaunchAtLoginController.presentation(for: .notFound)

        XCTAssertTrue(presentation.isEnabled)
        XCTAssertEqual(presentation.statusText, "앱 확인 필요")
    }

    func testRequiresApprovalLoginItemStaysToggleOnSoOffCanUnregister() {
        let presentation = LaunchAtLoginController.presentation(for: .requiresApproval)

        XCTAssertTrue(presentation.isEnabled)
        XCTAssertEqual(presentation.statusText, "승인 필요")
    }

    func testNotRegisteredLoginItemTurnsToggleOff() {
        let presentation = LaunchAtLoginController.presentation(for: .notRegistered)

        XCTAssertFalse(presentation.isEnabled)
        XCTAssertEqual(presentation.statusText, "꺼짐")
    }
}
