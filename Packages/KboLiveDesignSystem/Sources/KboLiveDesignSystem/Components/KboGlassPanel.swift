import SwiftUI

public enum KboGlassPanelStyle: Sendable {
    case card
    case elevated
    case control
    case navigation
}

public struct KboGlassPanel<Content: View>: View {
    private let style: KboGlassPanelStyle
    private let cornerRadius: CGFloat
    private let content: Content

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(
        style: KboGlassPanelStyle = .card,
        cornerRadius: CGFloat = 24,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .background(panelBackground)
            .clipShape(shape)
            .overlay {
                shape.stroke(borderColor, lineWidth: 1)
            }
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    @ViewBuilder
    private var panelBackground: some View {
        if reduceTransparency {
            shape.fill(opaqueSurface)
        } else {
            shape.fill(material)
            shape.fill(tintGradient)
        }
    }

    private var material: Material {
        switch style {
        case .card:
            return .thinMaterial
        case .elevated:
            return .regularMaterial
        case .control, .navigation:
            return .ultraThinMaterial
        }
    }

    private var opaqueSurface: Color {
        switch style {
        case .card:
            return KboSurfaceToken.card
        case .elevated:
            return KboSurfaceToken.elevated
        case .control:
            return KboSurfaceToken.card.opacity(0.96)
        case .navigation:
            return KboSurfaceToken.elevated.opacity(0.98)
        }
    }

    private var tintGradient: LinearGradient {
        let colors: [Color]
        switch style {
        case .card:
            colors = [
                KboSurfaceToken.glassControl,
                KboSurfaceToken.card.opacity(0.62)
            ]
        case .elevated:
            colors = [
                Color.white.opacity(0.16),
                KboSurfaceToken.elevated.opacity(0.72)
            ]
        case .control:
            colors = [
                KboSemanticColorToken.accentBlue.opacity(0.12),
                KboSurfaceToken.glassControl
            ]
        case .navigation:
            colors = [
                Color.white.opacity(0.18),
                KboSurfaceToken.glassNavigation
            ]
        }

        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var borderColor: Color {
        switch style {
        case .card:
            return KboSurfaceToken.cardBorder
        case .elevated, .control, .navigation:
            return KboSurfaceToken.glassBorder
        }
    }

    private var shadowColor: Color {
        switch style {
        case .card:
            return Color.black.opacity(0.14)
        case .elevated:
            return Color.black.opacity(0.20)
        case .control, .navigation:
            return Color.black.opacity(0.12)
        }
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .card, .control:
            return 10
        case .elevated:
            return 18
        case .navigation:
            return 14
        }
    }

    private var shadowY: CGFloat {
        switch style {
        case .card, .control:
            return 6
        case .elevated, .navigation:
            return 10
        }
    }
}
