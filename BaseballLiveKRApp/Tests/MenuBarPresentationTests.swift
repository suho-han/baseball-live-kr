import XCTest
@testable import BaseballLiveKR

final class MenuBarPresentationTests: XCTestCase {
    func testMenuBarItemUsesStableLabelPresentation() {
        XCTAssertEqual(BaseballLiveKRmacOSApp.menuBarItemTitle, "Baseball LIVE KR")
        XCTAssertEqual(BaseballLiveKRmacOSApp.menuBarItemImageName, "MenuBarBaseball")
        XCTAssertEqual(BaseballLiveKRmacOSApp.menuBarItemIconSize, 17)
    }
}
