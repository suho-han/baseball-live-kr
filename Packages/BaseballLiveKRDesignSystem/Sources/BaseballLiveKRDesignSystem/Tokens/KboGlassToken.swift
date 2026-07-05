import SwiftUI

public enum KboGlassToken {
    public static func opaqueSurface(for style: KboGlassPanelStyle) -> Color {
        switch style {
        case .card:
            return KboSurfaceToken.card
        case .elevated:
            return KboSurfaceToken.elevated
        case .control:
            return KboSurfaceToken.glassControl
        case .navigation:
            return KboSurfaceToken.glassNavigation
        }
    }

    public static func borderColor(for style: KboGlassPanelStyle) -> Color {
        switch style {
        case .card:
            return KboSurfaceToken.cardBorder
        case .elevated, .control, .navigation:
            return KboSurfaceToken.glassBorder
        }
    }
}
