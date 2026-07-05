import SwiftUI

public struct KboPrimaryActionButton: View {
    private let title: String
    private let systemImage: String?
    private let tint: Color
    private let isDisabled: Bool
    private let action: () -> Void
    @Environment(\.kboFontScale) private var fontScale

    public init(
        title: String,
        systemImage: String? = nil,
        tint: Color = KboSemanticColorToken.accentBlue,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.isDisabled = isDisabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: KboSpacingToken.small) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(KboTypographyToken.system(size: 15, weight: .semibold, scaledBy: fontScale))
                        .accessibilityHidden(true)
                }

                Text(title)
                    .font(KboTypographyToken.system(size: 14, weight: .bold, scaledBy: fontScale))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity, minHeight: KboControlToken.primaryButtonHeight)
            .padding(.horizontal, KboSpacingToken.large)
            .background(backgroundColor)
            .clipShape(shape)
            .overlay {
                shape
                    .stroke(borderColor, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.74 : 1)
        .accessibilityLabel(title)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: KboRadiusToken.large, style: .continuous)
    }

    private var foregroundColor: Color {
        isDisabled ? KboSemanticColorToken.contentMuted : KboColorToken.backgroundPrimary
    }

    private var backgroundColor: Color {
        isDisabled ? KboSurfaceToken.glassControl : tint
    }

    private var borderColor: Color {
        isDisabled ? KboSurfaceToken.cardBorder : tint.opacity(0.72)
    }
}
