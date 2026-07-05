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
                shape.stroke(borderColor, lineWidth: borderWidth)
            }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    @ViewBuilder
    private var panelBackground: some View {
        shape.fill(backgroundColor)
    }

    private var backgroundColor: Color {
        KboGlassToken.opaqueSurface(for: style)
    }

    private var borderColor: Color {
        switch style {
        case .card:
            return KboSurfaceToken.cardBorder
        case .elevated:
            return KboSurfaceToken.glassBorder.opacity(0.78)
        case .control:
            return KboSurfaceToken.glassBorder.opacity(0.62)
        case .navigation:
            return KboSurfaceToken.glassBorder.opacity(0.70)
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .card, .control:
            return 1
        case .elevated, .navigation:
            return 1.25
        }
    }
}
