import SwiftUI

public struct KboStatusPill: View {
    public enum Style: Sendable {
        case live
        case final
        case delayed
        case scheduled
        case neutral
    }

    private let text: String
    private let style: Style
    private let showsPulse: Bool
    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.kboFontScale) private var fontScale

    public init(text: String, style: Style, showsPulse: Bool = false) {
        self.text = text
        self.style = style
        self.showsPulse = showsPulse
    }

    public var body: some View {
        HStack(spacing: KboSpacingToken.xSmall) {
            if style == .live {
                Circle()
                    .fill(dotColor)
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(isPulsing && reduceMotion == false ? 1.26 : 1)
                    .opacity(isPulsing && reduceMotion == false ? 0.62 : 1)
            }

            Text(text)
                .font(KboTypographyToken.caption(scaledBy: fontScale))
                .lineLimit(1)
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, KboSpacingToken.small)
        .padding(.vertical, KboSpacingToken.xSmall)
        .frame(minHeight: KboControlToken.pillHeight)
        .background(backgroundColor)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(borderColor, lineWidth: 1)
        }
        .onAppear {
            guard showsPulse, style == .live, reduceMotion == false else { return }
            withAnimation(KboMotionToken.livePulse) {
                isPulsing = true
            }
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .live:
            return KboColorToken.surfaceCard
        case .final:
            return KboSemanticColorToken.contentPrimary
        case .delayed:
            return KboSemanticColorToken.contentPrimary
        case .scheduled, .neutral:
            return KboSemanticColorToken.contentPrimary
        }
    }

    private var dotColor: Color {
        style == .live ? KboColorToken.surfaceCard : foregroundColor
    }

    private var backgroundColor: Color {
        switch style {
        case .live:
            return KboSemanticColorToken.statusLive
        case .final:
            return KboSurfaceToken.glassControl
        case .delayed:
            return KboSemanticColorToken.statusDelayed.opacity(0.20)
        case .scheduled:
            return KboSurfaceToken.glassControl
        case .neutral:
            return KboSurfaceToken.glassControl
        }
    }

    private var borderColor: Color {
        switch style {
        case .live:
            return KboSemanticColorToken.statusLive
        case .final:
            return KboSurfaceToken.glassBorder
        case .delayed:
            return KboSemanticColorToken.statusDelayed.opacity(0.56)
        case .scheduled:
            return KboSemanticColorToken.statusScheduled.opacity(0.56)
        case .neutral:
            return KboSurfaceToken.glassBorder
        }
    }

    private var dotSize: CGFloat {
        KboSpacingToken.small
    }
}
