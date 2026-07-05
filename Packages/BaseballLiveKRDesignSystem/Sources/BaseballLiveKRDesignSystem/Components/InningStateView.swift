import SwiftUI

public struct InningStateView: View {
    private let text: String
    @Environment(\.kboFontScale) private var fontScale

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(KboTypographyToken.footnote(scaledBy: fontScale))
            .foregroundStyle(KboSemanticColorToken.contentSecondary)
            .lineLimit(1)
            .padding(.horizontal, KboSpacingToken.medium)
            .padding(.vertical, KboSpacingToken.xSmall + 2)
            .background(KboSurfaceToken.glassControl)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(KboSurfaceToken.glassBorder.opacity(0.58), lineWidth: 1)
            }
    }
}
