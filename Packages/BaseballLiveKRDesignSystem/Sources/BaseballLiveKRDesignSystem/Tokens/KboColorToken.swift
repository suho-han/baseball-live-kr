import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public enum KboColorToken {
    public static let backgroundPrimary = adaptive(light: RGB.hex(0xF1F1F1), dark: RGB.hex(0x1B1B1B))
    public static let backgroundSecondary = adaptive(light: RGB.hex(0xFAFAFA), dark: RGB.hex(0x262626))
    public static let appBackgroundTop = adaptive(light: RGB.hex(0xFAFAFA), dark: RGB.hex(0x262626))
    public static let appBackgroundPrimary = backgroundPrimary
    public static let appBackgroundSecondary = adaptive(light: RGB.hex(0xE5E5E5), dark: RGB.hex(0x171717))
    public static let scoreboardSpotlightSurface = Color.white
    public static let surfaceCard = adaptive(light: RGB.hex(0xFFFFFF), dark: RGB.hex(0x1B1B1B))
    public static let surfaceElevated = adaptive(light: RGB.hex(0xFFFFFF), dark: RGB.hex(0x262626))
    public static let borderMuted = adaptive(light: RGB.hex(0xEBEBEB), dark: RGB.hex(0xFFFFFF, alpha: 26.0 / 255.0))
    public static let borderEmphasized = adaptive(light: RGB.hex(0xD4D4D4), dark: RGB.hex(0x525252))
    public static let shadow = adaptive(light: RGB.hex(0x000000), dark: RGB.hex(0x000000))

    public static let textPrimary = adaptive(light: RGB.hex(0x171717), dark: RGB.hex(0xFAFAFA))
    public static let textSecondary = adaptive(light: RGB.hex(0x737373), dark: RGB.hex(0xA3A3A3))
    public static let textMuted = adaptive(light: RGB.hex(0xA3A3A3), dark: RGB.hex(0x737373))
    public static let scoreboardSpotlightTextPrimary = fixed(RGB.hex(0x171717))
    public static let scoreboardSpotlightTextSecondary = fixed(RGB.hex(0x737373)).opacity(0.86)

    public static let accentNeutral = adaptive(light: RGB.hex(0x262626), dark: RGB.hex(0xEBEBEB))
    public static let accentBlue = adaptive(light: RGB.hex(0x00458C), dark: RGB.hex(0xA0CAFF))
    public static let accentTeal = adaptive(light: RGB.hex(0x005348), dark: RGB.hex(0x83DAC9))

    public static let statusLive = adaptive(light: RGB.hex(0xA50C25), dark: RGB.hex(0xFFC6C1))
    public static let statusFinal = adaptive(light: RGB.hex(0x737373), dark: RGB.hex(0xA3A3A3))
    public static let statusDelayed = adaptive(light: RGB.hex(0x745B00), dark: RGB.hex(0xFDCF4F))
    public static let statusScheduled = adaptive(light: RGB.hex(0x00458C), dark: RGB.hex(0xA0CAFF))

    public static let success = adaptive(light: RGB.hex(0x007004), dark: RGB.hex(0x9FE59B))
    public static let warning = statusDelayed
    public static let danger = statusLive

    private struct RGB {
        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double

        init(_ red: Double, _ green: Double, _ blue: Double, alpha: Double = 1) {
            self.red = red
            self.green = green
            self.blue = blue
            self.alpha = alpha
        }

        static func hex(_ value: Int, alpha: Double = 1) -> RGB {
            RGB(
                Double((value >> 16) & 0xFF) / 255.0,
                Double((value >> 8) & 0xFF) / 255.0,
                Double(value & 0xFF) / 255.0,
                alpha: alpha
            )
        }
    }

    private static func fixed(_ rgb: RGB) -> Color {
        Color(red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: rgb.alpha)
    }

    private static func adaptive(light: RGB, dark: RGB) -> Color {
#if canImport(AppKit)
        Color(NSColor(name: nil) { appearance in
            let match = appearance.bestMatch(from: [.darkAqua, .aqua])
            let selected = match == .darkAqua ? dark : light
            return NSColor(
                calibratedRed: selected.red,
                green: selected.green,
                blue: selected.blue,
                alpha: selected.alpha
            )
        })
#elseif canImport(UIKit)
        Color(UIColor { traits in
            let selected = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: selected.red,
                green: selected.green,
                blue: selected.blue,
                alpha: selected.alpha
            )
        })
#else
        fixed(dark)
#endif
    }
}
