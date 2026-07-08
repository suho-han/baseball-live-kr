import XCTest
@testable import BaseballLiveKR

final class MenuBarPresentationTests: XCTestCase {
    func testMenuBarItemUsesStableTitleAndSystemImagePresentation() {
        XCTAssertEqual(BaseballLiveKRmacOSApp.menuBarItemTitle, "Baseball LIVE KR")
        XCTAssertEqual(BaseballLiveKRmacOSApp.menuBarItemSystemImage, "baseball.fill")
    }
}
