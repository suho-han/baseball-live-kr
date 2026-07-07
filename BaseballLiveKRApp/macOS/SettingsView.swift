import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: TodayGamesViewModel
    @ObservedObject var settings: BackendSettingsModel
    @ObservedObject var updateChecker: AppUpdateCheckModel
    @Binding var appearanceMode: KboAppearanceMode
    @Binding var isMenuBarEnabled: Bool
    @Binding var isLaunchAtLoginEnabled: Bool
    let launchAtLoginStatusText: String
    let launchAtLoginDetailText: String
    let onRefreshLaunchAtLogin: () -> Void
    let onApplyBackendSettings: () -> Void

    var body: some View {
        AppSettingsView(
            viewModel: viewModel,
            settings: settings,
            updateChecker: updateChecker,
            appearanceMode: $appearanceMode,
            isMenuBarEnabled: $isMenuBarEnabled,
            isLaunchAtLoginEnabled: $isLaunchAtLoginEnabled,
            launchAtLoginStatusText: launchAtLoginStatusText,
            launchAtLoginDetailText: launchAtLoginDetailText,
            onRefreshLaunchAtLogin: onRefreshLaunchAtLogin,
            onApplyBackendSettings: onApplyBackendSettings
        )
        .frame(width: 620, height: 620)
    }
}
