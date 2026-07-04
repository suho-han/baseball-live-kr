import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif
#if canImport(BaseballLiveKRCore)
import BaseballLiveKRCore
#endif
#if canImport(BaseballLiveKRDesignSystem)
import BaseballLiveKRDesignSystem
#endif
#if canImport(BaseballLiveKRFeatures)
import BaseballLiveKRFeatures
#endif

struct AppSettingsView: View {
    @ObservedObject var viewModel: TodayGamesViewModel
    @ObservedObject var settings: BackendSettingsModel
    @ObservedObject var updateChecker: AppUpdateCheckModel
    @Binding var appearanceMode: KboAppearanceMode
    @Binding var isMenuBarEnabled: Bool
    let onApplyBackendSettings: () -> Void

    init(
        viewModel: TodayGamesViewModel,
        settings: BackendSettingsModel,
        updateChecker: AppUpdateCheckModel,
        appearanceMode: Binding<KboAppearanceMode>,
        isMenuBarEnabled: Binding<Bool> = .constant(true),
        onApplyBackendSettings: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.settings = settings
        self.updateChecker = updateChecker
        _appearanceMode = appearanceMode
        _isMenuBarEnabled = isMenuBarEnabled
        self.onApplyBackendSettings = onApplyBackendSettings
    }

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

            appearanceSettingsView
                .tabItem {
                    Label("표시", systemImage: "circle.lefthalf.filled")
                }

#if os(macOS)
            menuBarSettingsView
                .tabItem {
                    Label("메뉴바", systemImage: "menubar.rectangle")
                }
#endif

            updateSettingsView
                .tabItem {
                    Label("업데이트", systemImage: "arrow.down.circle")
                }
        }
    }

    private var teamSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KboSpacingToken.large) {
                teamSettingsHeader

                LazyVGrid(columns: teamGridColumns, spacing: KboSpacingToken.medium) {
                    TeamClearSelectionCard(
                        isSelected: viewModel.selectedTeamID == nil
                    ) {
                        viewModel.selectTeam(nil)
                    }

                    ForEach(viewModel.allTeams) { team in
                        TeamSelectionCard(
                            team: team,
                            isSelected: viewModel.selectedTeamID == team.id
                        ) {
                            viewModel.selectTeam(team.id)
                        }
                    }
                }
            }
            .padding(KboSpacingToken.xLarge)
        }
        .background(settingsBackground)
    }

    private var appearanceSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                KboCommandBar(
                    eyebrow: "Display",
                    title: "화면 모드",
                    subtitle: "앱의 배경색과 글자색을 다크, 화이트, 시스템 설정에 맞춰 전환합니다."
                ) {
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(KboSemanticColorToken.accentBlue)
                        .frame(width: 44, height: 44)
                        .background(KboSemanticColorToken.accentBlue.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } actions: {
                    Text(appearanceMode.title)
                        .font(KboTypographyToken.caption)
                        .foregroundStyle(KboTheme.primaryText)
                        .padding(.horizontal, KboSpacingToken.medium)
                        .padding(.vertical, KboSpacingToken.small)
                        .background(KboSurfaceToken.glassControl)
                        .clipShape(Capsule())
                }

                KboGlassPanel(style: .card, cornerRadius: 22) {
                    Picker("화면 모드", selection: $appearanceMode) {
                        ForEach(KboAppearanceMode.allCases) { mode in
                            Label(mode.title, systemImage: systemImage(for: mode))
                                .tag(mode)
                        }
                    }
#if os(macOS)
                    .pickerStyle(.radioGroup)
#else
                    .pickerStyle(.segmented)
#endif
                    .foregroundStyle(KboTheme.primaryText)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
        .background(settingsBackground)
    }

    private var teamGridColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 240), spacing: KboSpacingToken.medium)
        ]
    }

    private var teamSettingsHeader: some View {
        let selectedTeam = viewModel.selectedTeam
        let accentColor = selectedTeam.map { TeamColorResolver.color(forTeamID: $0.id) } ?? KboSemanticColorToken.accentBlue

        return KboGlassPanel(style: .navigation, cornerRadius: 22) {
            HStack(spacing: KboSpacingToken.medium) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accentColor.opacity(0.16))

                    Image(systemName: selectedTeam == nil ? "star" : "star.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(accentColor)
                }
                .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 5) {
                    Text(selectedTeam.map(\.koreanFullName) ?? "전체 경기")
                        .font(KboTypographyToken.headline)
                        .foregroundStyle(KboTheme.primaryText)

                    Text(selectedTeam.map { "\($0.name) 중심으로 경기와 알림을 정렬합니다." } ?? "응원팀을 고르면 오늘 화면과 메뉴바에서 먼저 보여줍니다.")
                        .font(KboTypographyToken.footnote)
                        .foregroundStyle(KboTheme.secondaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                selectedTeamStatusPill(selectedTeam: selectedTeam, accentColor: accentColor)
            }
            .padding(KboSpacingToken.large)
        }
    }

    private func selectedTeamStatusPill(selectedTeam: KboTeamOption?, accentColor: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: selectedTeam == nil ? "circle" : "checkmark.circle.fill")
                .font(.system(size: 13, weight: .semibold))

            Text(selectedTeam?.name ?? "전체")
                .font(KboTypographyToken.caption)
                .lineLimit(1)
        }
        .foregroundStyle(selectedTeam == nil ? KboTheme.secondaryText : accentColor)
        .padding(.horizontal, KboSpacingToken.medium)
        .padding(.vertical, KboSpacingToken.small)
        .background(accentColor.opacity(selectedTeam == nil ? 0.08 : 0.14))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(accentColor.opacity(selectedTeam == nil ? 0.18 : 0.38), lineWidth: 1)
        }
    }

    private var settingsBackground: some View {
        LinearGradient(
            colors: [
                KboColorToken.appBackgroundTop,
                KboColorToken.appBackgroundPrimary,
                KboColorToken.appBackgroundSecondary
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var updateSettingsView: some View {
        Form {
            Section {
                LabeledContent("현재 버전", value: updateChecker.currentVersionText)

                LabeledContent("마지막 확인", value: updateChecker.lastCheckedText)

                LabeledContent("상태") {
                    updateStatusLabel
                }

                Button {
                    Task {
                        await updateChecker.checkForUpdates()
                    }
                } label: {
                    Label("업데이트 확인", systemImage: "arrow.clockwise")
                }
                .disabled(updateChecker.state == .checking)

                Button {
                    updateChecker.openRepositoryPage()
                } label: {
                    Label("Repository", systemImage: "arrow.up.right.square")
                }
            } header: {
                Text("버전 업데이트")
            }
        }
        .formStyle(.grouped)
    }

#if os(macOS)
    private var menuBarSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KboSpacingToken.large) {
                KboCommandBar(
                    eyebrow: "Menu Bar",
                    title: "메뉴바",
                    subtitle: "상단 메뉴바의 Baseball LIVE KR 상태 아이콘을 수동으로 시작하거나 종료합니다."
                ) {
                    Image(systemName: "menubar.rectangle")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(menuBarAccentColor)
                        .frame(width: 44, height: 44)
                        .background(menuBarAccentColor.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } actions: {
                    menuBarStatusPill
                }

                KboGlassPanel(style: .card, cornerRadius: 22) {
                    VStack(alignment: .leading, spacing: KboSpacingToken.large) {
                        Toggle(isOn: $isMenuBarEnabled) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("메뉴바 아이콘 표시")
                                    .font(KboTypographyToken.headline)
                                    .foregroundStyle(KboTheme.primaryText)

                                Text("끄면 상단 메뉴바의 Baseball LIVE KR 아이콘과 대시보드가 사라집니다.")
                                    .font(KboTypographyToken.caption)
                                    .foregroundStyle(KboTheme.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .toggleStyle(.switch)

                        HStack(spacing: KboSpacingToken.small) {
                            KboPrimaryActionButton(
                                title: "시작",
                                systemImage: "play.circle.fill",
                                tint: KboSemanticColorToken.success,
                                isDisabled: isMenuBarEnabled
                            ) {
                                isMenuBarEnabled = true
                            }

                            Button {
                                isMenuBarEnabled = false
                            } label: {
                                secondaryMenuBarButtonLabel(title: "종료", systemImage: "stop.circle")
                            }
                            .buttonStyle(.plain)
                            .disabled(isMenuBarEnabled == false)
                            .opacity(isMenuBarEnabled ? 1 : 0.5)
                        }
                    }
                    .padding(KboSpacingToken.large)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(KboSpacingToken.xLarge)
        }
        .background(settingsBackground)
    }

    private var menuBarStatusPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(menuBarAccentColor)
                .frame(width: 8, height: 8)

            Text(isMenuBarEnabled ? "실행 중" : "중지됨")
                .font(KboTypographyToken.caption)
                .foregroundStyle(KboTheme.primaryText)
        }
        .padding(.horizontal, KboSpacingToken.medium)
        .padding(.vertical, KboSpacingToken.small)
        .background(menuBarAccentColor.opacity(0.14))
        .clipShape(Capsule())
    }

    private var menuBarAccentColor: Color {
        isMenuBarEnabled ? KboSemanticColorToken.success : KboTheme.secondaryText
    }

    private func secondaryMenuBarButtonLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))

            Text(title)
                .font(KboTypographyToken.caption)
                .lineLimit(1)
        }
        .foregroundStyle(KboTheme.primaryText)
        .frame(maxWidth: .infinity, minHeight: KboControlToken.primaryButtonHeight)
        .background(KboSurfaceToken.glassControl)
        .clipShape(RoundedRectangle(cornerRadius: KboRadiusToken.large, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KboRadiusToken.large, style: .continuous)
                .stroke(KboSurfaceToken.glassBorder.opacity(0.7), lineWidth: 1)
        }
    }
#endif

    private func systemImage(for mode: KboAppearanceMode) -> String {
        switch mode {
        case .system:
            return "desktopcomputer"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }

    @ViewBuilder
    private var updateStatusLabel: some View {
        switch updateChecker.state {
        case .idle:
            Text("미확인")
                .foregroundStyle(.secondary)
        case .checking:
            ProgressView()
                .controlSize(.small)
        case .upToDate:
            Label("최신 버전", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .updateAvailable(let title):
            HStack(spacing: 8) {
                Label(title, systemImage: "arrow.down.circle.fill")
                    .foregroundStyle(.blue)

                Button("열기") {
                    updateChecker.openReleasePage()
                }
            }
        case .noPublishedRelease:
            HStack(spacing: 8) {
                Label("공개 릴리스 없음", systemImage: "info.circle.fill")
                    .foregroundStyle(.secondary)

                Button("열기") {
                    updateChecker.openReleasePage()
                }
            }
        case .failed(let message):
            Label(message, systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
    }
}
