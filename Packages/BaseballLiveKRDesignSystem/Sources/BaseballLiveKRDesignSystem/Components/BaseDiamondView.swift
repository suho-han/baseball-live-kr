import SwiftUI

public struct BaseDiamondView: View {
    private let firstOccupied: Bool
    private let secondOccupied: Bool
    private let thirdOccupied: Bool

    public init(firstOccupied: Bool, secondOccupied: Bool, thirdOccupied: Bool) {
        self.firstOccupied = firstOccupied
        self.secondOccupied = secondOccupied
        self.thirdOccupied = thirdOccupied
    }

    public var body: some View {
        ZStack {
            DiamondBase(isOccupied: secondOccupied, baseName: "2B")
                .offset(y: -KboSpacingToken.medium)

            DiamondBase(isOccupied: thirdOccupied, baseName: "3B")
                .offset(x: -KboSpacingToken.medium)

            DiamondBase(isOccupied: firstOccupied, baseName: "1B")
                .offset(x: KboSpacingToken.medium)
        }
        .frame(width: 40, height: 32)
    }
}

private struct DiamondBase: View {
    let isOccupied: Bool
    let baseName: String

    var body: some View {
        RoundedRectangle(cornerRadius: baseCornerRadius, style: .continuous)
            .fill(fillColor)
            .frame(width: 11, height: 11)
            .rotationEffect(.degrees(45))
            .overlay {
                RoundedRectangle(cornerRadius: baseCornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: isOccupied ? 1.25 : 1)
                    .rotationEffect(.degrees(45))
            }
            .accessibilityLabel(baseName)
            .accessibilityValue(isOccupied ? "occupied" : "empty")
    }

    private var fillColor: Color {
        isOccupied ? KboSemanticColorToken.statusScheduled : KboSurfaceToken.glassControl
    }

    private var borderColor: Color {
        isOccupied ? KboSemanticColorToken.statusScheduled : KboSurfaceToken.glassBorder.opacity(0.68)
    }

    private var baseCornerRadius: CGFloat {
        KboRadiusToken.small / 3
    }
}
