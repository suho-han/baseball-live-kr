import SwiftUI

public enum KboSurfaceToken {
    public static let contentBackground = KboColorToken.backgroundPrimary
    public static let card = KboColorToken.surfaceCard
    public static let elevated = KboColorToken.surfaceElevated
    public static let glassControl = Color.white.opacity(0.10)
    public static let glassNavigation = Color.white.opacity(0.12)
    public static let criticalOverlay = Color.black.opacity(0.42)

    public static let cardBorder = Color.white.opacity(0.10)
    public static let glassBorder = Color.white.opacity(0.18)
    public static let focusBorder = KboSemanticColorToken.accentBlue.opacity(0.55)
}
