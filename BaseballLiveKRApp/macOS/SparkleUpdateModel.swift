import Foundation
import AppKit
import Sparkle

@MainActor
final class SparkleUpdateModel: NSObject, ObservableObject {
    enum State: Equatable {
        case idle
        case checking
        case upToDate
        case updateAvailable(String)
        case failed
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var lastCheckedAt: Date?

    private lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: false,
        updaterDelegate: self,
        userDriverDelegate: nil
    )

    private let repositoryPageURL = URL(string: "https://github.com/suho-han/baseball-live-kr")!
    private let testFeedURL: String?

    override init() {
        testFeedURL = Self.testFeedURLFromLaunchArguments()
        super.init()
        updaterController.startUpdater()
    }

    var currentVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        guard let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
              build.isEmpty == false,
              build != version else {
            return version
        }

        return "\(version) (\(build))"
    }

    var lastCheckedText: String {
        guard let lastCheckedAt else {
            return "아직 확인하지 않음"
        }

        return Self.lastCheckedFormatter.string(from: lastCheckedAt)
    }

    func checkForUpdates() {
        guard state != .checking else { return }

        state = .checking
        updaterController.checkForUpdates(nil)
    }

    func openRepositoryPage() {
        NSWorkspace.shared.open(repositoryPageURL)
    }

    private static let lastCheckedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    private static func testFeedURLFromLaunchArguments() -> String? {
        let arguments = ProcessInfo.processInfo.arguments

        guard let argumentIndex = arguments.firstIndex(of: "-sparkleTestFeedURL"),
              arguments.count > argumentIndex + 1 else {
            return nil
        }

        return arguments[argumentIndex + 1]
    }
}

extension SparkleUpdateModel: SPUUpdaterDelegate {
    func feedURLString(for updater: SPUUpdater) -> String? {
        testFeedURL
    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        state = .updateAvailable(item.displayVersionString)
        lastCheckedAt = Date()
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: any Error) {
        state = .upToDate
        lastCheckedAt = Date()
    }

    func updater(_ updater: SPUUpdater, didAbortWithError error: any Error) {
        state = .failed
        lastCheckedAt = Date()
    }
}
