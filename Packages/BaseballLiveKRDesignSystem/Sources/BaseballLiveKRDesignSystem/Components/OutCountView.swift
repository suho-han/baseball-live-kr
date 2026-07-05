import SwiftUI

public struct OutCountView: View {
    private let outs: Int

    public init(outs: Int) {
        self.outs = min(max(outs, 0), 3)
    }

    public var body: some View {
        HStack(spacing: KboSpacingToken.xSmall) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index < outs ? KboSemanticColorToken.statusLive : KboSemanticColorToken.contentMuted.opacity(0.28))
                    .frame(width: dotSize, height: dotSize)
                    .overlay {
                        Circle()
                            .stroke(index < outs ? KboSemanticColorToken.statusLive : KboSurfaceToken.cardBorder, lineWidth: 1)
                    }
            }
        }
        .padding(.horizontal, KboSpacingToken.small)
        .padding(.vertical, KboSpacingToken.xSmall)
        .background(KboSurfaceToken.glassControl)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(KboSurfaceToken.glassBorder, lineWidth: 1)
        }
    }

    private var dotSize: CGFloat {
        KboSpacingToken.small
    }
}
