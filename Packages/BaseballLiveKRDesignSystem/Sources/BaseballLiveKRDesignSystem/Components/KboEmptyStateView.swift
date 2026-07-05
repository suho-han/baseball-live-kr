import SwiftUI

public struct KboEmptyStateView: View {
    private let title: String
    private let message: String
    private let systemImage: String
    private let style: KboGlassPanelStyle
    @Environment(\.kboFontScale) private var fontScale

    public init(
        title: String,
        message: String,
        systemImage: String = "baseball.diamond.bases",
        style: KboGlassPanelStyle = .card
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.style = style
    }

    public var body: some View {
        KboGlassPanel(style: style, cornerRadius: KboRadiusToken.xLarge) {
            HStack(alignment: .top, spacing: KboSpacingToken.large) {
                Image(systemName: systemImage)
                    .font(KboTypographyToken.system(size: 18, weight: .semibold, scaledBy: fontScale))
                    .foregroundStyle(KboSemanticColorToken.accentBlue)
                    .frame(width: KboControlToken.compactButtonHeight, height: KboControlToken.compactButtonHeight)
                    .background(KboSemanticColorToken.accentBlue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: KboRadiusToken.medium, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: KboRadiusToken.medium, style: .continuous)
                            .stroke(KboSemanticColorToken.accentBlue.opacity(0.24), lineWidth: 1)
                    }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: KboSpacingToken.small) {
                    Text(title)
                        .font(KboTypographyToken.headline(scaledBy: fontScale))
                        .foregroundStyle(KboSemanticColorToken.contentPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(message)
                        .font(KboTypographyToken.body(scaledBy: fontScale))
                        .foregroundStyle(KboSemanticColorToken.contentSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(KboSpacingToken.xLarge)
            .accessibilityElement(children: .combine)
        }
    }
}
