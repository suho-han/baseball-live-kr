import SwiftUI

public struct PitchCountView: View {
    private let balls: Int
    private let strikes: Int
    @Environment(\.kboFontScale) private var fontScale

    public init(balls: Int, strikes: Int) {
        self.balls = max(0, balls)
        self.strikes = max(0, strikes)
    }

    public var body: some View {
        HStack(spacing: KboSpacingToken.xSmall) {
            countLabel("B", value: balls, tint: KboSemanticColorToken.accentBlue)
            Divider()
                .frame(height: KboSpacingToken.medium)
                .overlay(KboSurfaceToken.cardBorder)
            countLabel("S", value: strikes, tint: KboSemanticColorToken.statusLive)
        }
        .padding(.horizontal, KboSpacingToken.small)
        .padding(.vertical, KboSpacingToken.xSmall)
        .background(KboSurfaceToken.glassControl)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(KboSurfaceToken.glassBorder, lineWidth: 1)
        }
    }

    private func countLabel(_ label: String, value: Int, tint: Color) -> some View {
        HStack(spacing: KboSpacingToken.xSmall) {
            Text(label)
                .foregroundStyle(KboSemanticColorToken.contentSecondary)
            Text("\(value)")
                .foregroundStyle(tint)
        }
        .font(KboTypographyToken.footnote(scaledBy: fontScale))
        .monospacedDigit()
        .lineLimit(1)
    }
}
