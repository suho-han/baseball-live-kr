import SwiftUI
#if canImport(KboLiveFeatures)
import KboLiveFeatures
#endif

struct AppSettingsView: View {
    @ObservedObject var viewModel: TodayGamesViewModel
    @ObservedObject var settings: BackendSettingsModel
    let onApplyBackendSettings: () -> Void

    var body: some View {
        TabView {
            BackendSettingsView(
                settings: settings,
                onApply: onApplyBackendSettings
            )
            .tabItem {
                Label("백엔드", systemImage: "server.rack")
            }

            teamSettingsView
                .tabItem {
                    Label("응원팀", systemImage: "star")
                }
        }
    }

    private var teamSettingsView: some View {
        Form {
            Picker("응원팀", selection: Binding(
                get: { viewModel.selectedTeamID ?? "" },
                set: { newValue in
                    viewModel.selectTeam(newValue.isEmpty ? nil : newValue)
                }
            )) {
                Text("선택 안 함").tag("")
                ForEach(viewModel.allTeams) { team in
                    Text(team.name).tag(team.id)
                }
            }
            .pickerStyle(.menu)
        }
        .formStyle(.grouped)
        .padding(20)
    }
}
