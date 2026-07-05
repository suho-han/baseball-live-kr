import SwiftUI

public struct ScoreDigitsView: View {
    public enum Mode: Sendable {
        case scoreboardLarge
        case scoreboardCompact
        case menuBarCompact
    }

    private let score: Int
    private let mode: Mode
    @Environment(\.kboFontScale) private var fontScale

    public init(score: Int, mode: Mode = .scoreboardCompact) {
        self.score = score
        self.mode = mode
    }

    public var body: some View {
        Text(String(score))
            .font(font)
            .monospacedDigit()
            .foregroundStyle(KboSemanticColorToken.contentPrimary)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .frame(minWidth: minWidth, alignment: .trailing)
            .padding(.horizontal, horizontalInset)
            .padding(.vertical, verticalInset)
            .background(KboSurfaceToken.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(KboSurfaceToken.cardBorder, lineWidth: 1)
            }
    }

    private var font: Font {
        switch mode {
        case .scoreboardLarge:
            return KboTypographyToken.scoreLarge(scaledBy: fontScale)
        case .scoreboardCompact:
            return KboTypographyToken.scoreCompact(scaledBy: fontScale)
        case .menuBarCompact:
            return KboTypographyToken.menuBarCompact(scaledBy: fontScale)
        }
    }

    private var minWidth: CGFloat {
        switch mode {
        case .scoreboardLarge:
            return 72
        case .scoreboardCompact:
            return 48
        case .menuBarCompact:
            return 28
        }
    }

    private var horizontalInset: CGFloat {
        switch mode {
        case .scoreboardLarge:
            return KboSpacingToken.small
        case .scoreboardCompact:
            return KboSpacingToken.xSmall
        case .menuBarCompact:
            return KboSpacingToken.xSmall
        }
    }

    private var verticalInset: CGFloat {
        switch mode {
        case .scoreboardLarge:
            return KboSpacingToken.xSmall
        case .scoreboardCompact:
            return KboSpacingToken.xSmall
        case .menuBarCompact:
            return 0
        }
    }

    private var cornerRadius: CGFloat {
        switch mode {
        case .scoreboardLarge:
            return KboRadiusToken.medium
        case .scoreboardCompact:
            return KboRadiusToken.small
        case .menuBarCompact:
            return KboRadiusToken.small
        }
    }
}
