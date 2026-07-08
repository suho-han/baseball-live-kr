import XCTest
@testable import BaseballLiveKR

final class MenuBarPresentationTests: XCTestCase {
    @MainActor
    func testMenuBarItemUsesStableLabelPresentation() {
        XCTAssertEqual(BaseballLiveKRmacOSApp.menuBarItemTitle, "Baseball LIVE KR")
        XCTAssertEqual(BaseballLiveKRmacOSApp.menuBarItemImageName, "MenuBarBaseball")
    }
}
