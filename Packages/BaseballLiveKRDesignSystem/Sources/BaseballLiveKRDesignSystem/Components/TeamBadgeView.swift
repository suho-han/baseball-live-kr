import SwiftUI

public struct TeamBadgeView: View {
    public enum Emphasis: Sendable {
        case normal
        case highlighted
    }

    private let shortName: String
    private let teamID: String?
    private let accentColor: Color
    private let emphasis: Emphasis
    private let fixedWidth: CGFloat?
    private let logoSize: CGFloat
    private let nameWidth: CGFloat?
    private let foregroundColor: Color?
    @Environment(\.kboFontScale) private var fontScale

    public init(
        shortName: String,
        fullName: String? = nil,
        accentColor: Color,
        emphasis: Emphasis = .normal,
        fixedWidth: CGFloat? = nil,
        logoSize: CGFloat = 20,
        nameWidth: CGFloat? = nil,
        foregroundColor: Color? = nil
    ) {
        self.shortName = shortName
        self.teamID = fullName
        self.accentColor = accentColor
        self.emphasis = emphasis
        self.fixedWidth = fixedWidth
        self.logoSize = logoSize
        self.nameWidth = nameWidth
        self.foregroundColor = foregroundColor
    }

    public var body: some View {
        HStack(spacing: KboSpacingToken.small) {
            teamLogoView

            Text(shortName)
                .font(KboTypographyToken.headline(scaledBy: fontScale))
                .foregroundStyle(teamNameColor)
                .frame(width: nameWidth, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, KboSpacingToken.small)
        .padding(.vertical, 6)
        .frame(width: fixedWidth, alignment: fixedWidth == nil ? .leading : .center)
        .background(accentColor.opacity(emphasis == .highlighted ? 0.36 : 0.24))
        .clipShape(RoundedRectangle(cornerRadius: KboRadiusToken.pill, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KboRadiusToken.pill, style: .continuous)
                .stroke(accentColor.opacity(0.5), lineWidth: emphasis == .highlighted ? 1.5 : 1)
        }
    }

    private var teamNameColor: Color {
        if let foregroundColor {
            return foregroundColor
        }

        guard let teamID, TeamColorResolver.usesLightForeground(forTeamID: teamID) else {
            return accentColor
        }

        return KboColorToken.textPrimary
    }

    @ViewBuilder
    private var teamLogoView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(accentColor)

            Text(teamToken)
                .font(KboTypographyToken.system(size: max(9, logoSize * 0.42), weight: .black, scaledBy: fontScale))
                .foregroundStyle(teamTokenColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: logoSize, height: logoSize)
    }

    private var teamToken: String {
        let source = teamID?.trimmingCharacters(in: .whitespacesAndNewlines)
        ?? shortName.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(source.prefix(2)).uppercased()
    }

    private var teamTokenColor: Color {
        guard let teamID, TeamColorResolver.usesLightForeground(forTeamID: teamID) else {
            return KboColorToken.textPrimary
        }

        return .white
    }
}
