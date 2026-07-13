import XCTest
@testable import BaseballLiveKR

final class MenuBarExtraLabelPolicyTests: XCTestCase {
    func testMenuBarItemUsesStableIconInsteadOfDynamicSummary() {
        let dynamicSummary = "KIA 3:2 한화"

        XCTAssertEqual(BaseballLiveKRmacOSApp.menuBarItemSystemImage, "baseball.fill")
        XCTAssertNotEqual(BaseballLiveKRmacOSApp.menuBarItemSystemImage, dynamicSummary)
        XCTAssertNotEqual(BaseballLiveKRmacOSApp.menuBarItemSystemImage, BaseballLiveKRmacOSApp.menuBarItemTitle)
    }

    func testStatusItemControllerUsesStaticMenuBarPresentationConstants() throws {
        let appSource = try String(contentsOfFile: macOSAppSourcePath, encoding: .utf8)
        let controllerSource = try String(contentsOfFile: menuBarStatusItemControllerSourcePath, encoding: .utf8)

        XCTAssertTrue(appSource.contains("static let menuBarItemSystemImage = \"baseball.fill\""))
        XCTAssertTrue(controllerSource.contains("NSStatusItem.squareLength"))
        XCTAssertTrue(controllerSource.contains("BaseballLiveKRmacOSApp.menuBarItemSystemImage"))
        XCTAssertTrue(controllerSource.contains("BaseballLiveKRmacOSApp.menuBarItemTitle"))
        XCTAssertFalse(appSource.contains("Label(menuBarTitle, systemImage:"))
        XCTAssertFalse(controllerSource.contains("GameProjectionFormatter.scoreLine"))
    }

    private var macOSAppSourcePath: String {
        let testFileURL = URL(fileURLWithPath: #filePath)
        return testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("macOS/BaseballLiveKRmacOSApp.swift")
            .path
    }

    private var menuBarStatusItemControllerSourcePath: String {
        let testFileURL = URL(fileURLWithPath: #filePath)
        return testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("macOS/MenuBarStatusItemController.swift")
            .path
    }
}
