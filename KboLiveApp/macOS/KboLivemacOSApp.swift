import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
#if canImport(KboLiveDesignSystem)
import KboLiveDesignSystem
#endif

@main
struct KboLivemacOSApp: App {
    private enum MainWindowLayout {
        static let minWidth: CGFloat = 980
        static let minHeight: CGFloat = 720
        static let defaultWidth: CGFloat = 1180
        static let defaultHeight: CGFloat = 860
    }

#if canImport(AppKit)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
#endif
    @StateObject private var viewModel: TodayGamesViewModel
    @StateObject private var settings = BackendSettingsModel()
    @StateObject private var navigationModel = AppNavigationModel()
    @StateObject private var updateChecker = AppUpdateCheckModel()
    @AppStorage("kboLiveFontScale") private var fontScale = Double(KboFontScale.defaultValue)

    init() {
        let settings = BackendSettingsModel()
        let viewModel = TodayGamesViewModel(client: settings.makeClient())
        _settings = StateObject(wrappedValue: settings)
        _viewModel = StateObject(wrappedValue: viewModel)

        Task {
            await viewModel.loadIfNeeded()
        }
    }

    var body: some Scene {
        Window("KBO Live", id: "main-window") {
            KboLiveHomeRootView(
                viewModel: viewModel,
                settings: settings,
                navigationModel: navigationModel,
                updateChecker: updateChecker
            )
                .frame(
                    minWidth: MainWindowLayout.minWidth,
                    minHeight: MainWindowLayout.minHeight
                )
                .environment(\.kboFontScale, CGFloat(fontScale))
                .task {
                    await updateChecker.checkOnLaunch()
                }
                .alert("업데이트가 있습니다.", isPresented: $updateChecker.isShowingUpdateAlert) {
                    Button("다운로드") {
                        updateChecker.openReleasePage()
                    }

                    Button("나중에", role: .cancel) {}
                } message: {
                    Text(updateChecker.alertMessage)
                }
        }
        .defaultSize(
            width: MainWindowLayout.defaultWidth,
            height: MainWindowLayout.defaultHeight
        )
        .windowResizability(.contentMinSize)
        .commands {
            CommandMenu("보기") {
                Button("글씨 크게") {
                    adjustFontScale(by: KboFontScale.step)
                }
                .keyboardShortcut("+", modifiers: .command)
                .disabled(CGFloat(fontScale) >= KboFontScale.maximum)

                Button("글씨 작게") {
                    adjustFontScale(by: -KboFontScale.step)
                }
                .keyboardShortcut("-", modifiers: .command)
                .disabled(CGFloat(fontScale) <= KboFontScale.minimum)
            }
        }

        MenuBarExtra {
            MenuBarDashboardView(
                viewModel: viewModel,
                navigationModel: navigationModel
            )
            .environment(\.kboFontScale, CGFloat(fontScale))
        } label: {
            Label(menuBarTitle, systemImage: "baseball.fill")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(
                viewModel: viewModel,
                settings: settings,
                updateChecker: updateChecker,
                onApplyBackendSettings: applyBackendSettings
            )
            .environment(\.kboFontScale, CGFloat(fontScale))
        }
    }

    private func adjustFontScale(by delta: CGFloat) {
        fontScale = Double(KboFontScale.clamped(CGFloat(fontScale) + delta))
    }

    private func applyBackendSettings() {
        Task {
            await viewModel.updateClient(settings.makeClient())
        }
    }

    private var menuBarTitle: String {
        if let favoriteGame = viewModel.favoriteGame {
            return GameProjectionFormatter.scoreLine(for: favoriteGame)
        }

        return viewModel.leagueGames.first.map { MenuBarGameSummaryMapper.map($0).primaryText } ?? "KBO Live"
    }
}

#if canImport(AppKit)
private final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }
}
#endif
