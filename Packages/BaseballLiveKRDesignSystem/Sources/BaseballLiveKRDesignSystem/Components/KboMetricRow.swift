import SwiftUI

public struct KboMetricValue: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let value: String
    public let tint: Color?

    public init(title: String, value: String, tint: Color? = nil) {
        self.id = title
        self.title = title
        self.value = value
        self.tint = tint
    }
}

public struct KboMetricRow: View {
    public enum Layout: Sendable {
        case horizontal
        case vertical
    }

    private let metrics: [KboMetricValue]
    private let layout: Layout
    @Environment(\.kboFontScale) private var fontScale

    public init(_ metrics: [KboMetricValue], layout: Layout = .horizontal) {
        self.metrics = metrics
        self.layout = layout
    }

    public var body: some View {
        Group {
            switch layout {
            case .horizontal:
                HStack(spacing: KboSpacingToken.small) {
                    metricCells
                }
            case .vertical:
                VStack(spacing: KboSpacingToken.small) {
                    metricCells
                }
            }
        }
    }

    @ViewBuilder
    private var metricCells: some View {
        ForEach(metrics) { metric in
            metricCell(metric)
        }
    }

    private func metricCell(_ metric: KboMetricValue) -> some View {
        VStack(alignment: .leading, spacing: KboSpacingToken.xSmall) {
            Text(metric.title)
                .font(KboTypographyToken.caption(scaledBy: fontScale))
                .foregroundStyle(KboSemanticColorToken.contentSecondary)
                .textCase(.uppercase)
                .tracking(0.4)
                .lineLimit(1)

            Text(metric.value)
                .font(KboTypographyToken.system(size: 15, weight: .semibold, scaledBy: fontScale))
                .foregroundStyle(metric.tint ?? KboSemanticColorToken.contentPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, minHeight: KboControlToken.compactButtonHeight, alignment: .leading)
        .padding(.horizontal, KboSpacingToken.medium)
        .padding(.vertical, KboSpacingToken.small)
        .background(KboSurfaceToken.elevated)
        .clipShape(shape)
        .overlay {
            shape
                .stroke(KboSurfaceToken.cardBorder, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(metric.title), \(metric.value)")
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: KboRadiusToken.large, style: .continuous)
    }
}
