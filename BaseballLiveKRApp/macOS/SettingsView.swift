import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: TodayGamesViewModel
    @ObservedObject var settings: BackendSettingsModel
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
