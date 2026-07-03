import SwiftUI
#if canImport(BaseballLiveKRCore)
import BaseballLiveKRCore
#endif
#if canImport(BaseballLiveKRDesignSystem)
import BaseballLiveKRDesignSystem
#endif
#if canImport(BaseballLiveKRFeatures)
import BaseballLiveKRFeatures
#endif

struct TeamClearSelectionCard: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(KboSurfaceToken.glassControl)

                    Image(systemName: "slash.circle")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(KboTheme.secondaryText)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text("선택 안 함")
                        .font(KboTypographyToken.headline)
                        .foregroundStyle(KboTheme.primaryText)

                    Text("전체 경기 기준")
                        .font(KboTypographyToken.caption)
                        .foregroundStyle(KboTheme.secondaryText)
                }

                Spacer(minLength: 0)

                selectionMark
            }
            .padding(13)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .background(
                isSelected
                    ? KboSemanticColorToken.accentBlue.opacity(0.12)
                    : KboSurfaceToken.card.opacity(0.64)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected ? KboSurfaceToken.focusBorder : KboSurfaceToken.cardBorder.opacity(0.82),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private var selectionMark: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(isSelected ? KboSemanticColorToken.accentMint : KboTheme.secondaryText.opacity(0.72))
    }
}

struct TeamSelectionCard: View {
    let team: KboTeamOption
    let isSelected: Bool
    let action: () -> Void

    private var accentColor: Color {
        TeamColorResolver.color(forTeamID: team.id)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                teamLogo

                VStack(alignment: .leading, spacing: 2) {
                    Text(team.koreanFullName)
                        .font(KboTypographyToken.headline)
                        .foregroundStyle(KboTheme.primaryText)
                        .lineLimit(1)
                        .layoutPriority(1)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                selectionMark
            }
            .padding(13)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? accentColor.opacity(0.78) : KboSurfaceToken.cardBorder.opacity(0.82), lineWidth: isSelected ? 1.5 : 1)
            }
            .shadow(color: isSelected ? accentColor.opacity(0.14) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var teamLogo: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(accentColor.opacity(isSelected ? 0.22 : 0.10))

            TeamLogoImage(teamID: team.id)
                .frame(width: 34, height: 34)
        }
        .frame(width: 48, height: 48)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accentColor.opacity(isSelected ? 0.72 : 0.38), lineWidth: isSelected ? 1.5 : 1)
        }
    }

    private var cardBackground: some View {
        LinearGradient(
            colors: [
                accentColor.opacity(isSelected ? 0.18 : 0.04),
                KboSurfaceToken.card.opacity(isSelected ? 0.94 : 0.70)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var selectionMark: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(isSelected ? accentColor : KboTheme.secondaryText.opacity(0.72))
    }
}

private struct TeamLogoImage: View {
    let teamID: String

    var body: some View {
        TeamLogoTokenView(teamID: teamID, fallbackName: teamID, cornerRadius: 7)
    }
}
