import XCTest
@testable import BaseballLiveKR

final class MenuBarExtraLabelPolicyTests: XCTestCase {
    func testMenuBarLabelUsesStableBaseballIconWhileHelpKeepsDynamicSummary() {
        let dynamicSummary = "KIA 3:2 한화"

        let policy = MenuBarExtraLabelPolicy(dynamicSummary: dynamicSummary)

        XCTAssertEqual(policy.systemImageName, "baseball.fill")
        XCTAssertNotEqual(policy.systemImageName, dynamicSummary)
        XCTAssertNotEqual(policy.systemImageName, "Baseball LIVE KR")
        XCTAssertEqual(policy.helpText, dynamicSummary)
    }

    func testMacOSAppSceneUsesStablePolicyIconInsteadOfDynamicSummaryAsMenuBarTitle() throws {
        let source = try String(contentsOfFile: macOSAppSourcePath, encoding: .utf8)

        XCTAssertTrue(source.contains("Image(systemName: labelPolicy.systemImageName)"))
        XCTAssertFalse(source.contains("Text(labelPolicy.visualTitle)"))
        XCTAssertFalse(source.contains("Label(menuBarTitle, systemImage:"))
        XCTAssertFalse(source.contains(".accessibilityLabel(Text(labelPolicy.helpText))"))
        XCTAssertFalse(source.contains(".accessibilityLabel(Text(labelPolicy.dynamicSummary))"))
    }

    private var macOSAppSourcePath: String {
        let testFileURL = URL(fileURLWithPath: #filePath)
        return testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("macOS/BaseballLiveKRmacOSApp.swift")
            .path
    }
}
