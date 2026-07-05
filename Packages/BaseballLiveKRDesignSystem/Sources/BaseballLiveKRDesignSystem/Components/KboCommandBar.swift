import SwiftUI

public struct KboCommandBar<LeadingAccessory: View, Actions: View>: View {
    private let eyebrow: String?
    private let title: String
    private let subtitle: String?
    private let leadingAccessory: LeadingAccessory
    private let actions: Actions
    @Environment(\.kboFontScale) private var fontScale

    public init(
        eyebrow: String? = nil,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder leadingAccessory: () -> LeadingAccessory = { EmptyView() },
        @ViewBuilder actions: () -> Actions = { EmptyView() }
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.leadingAccessory = leadingAccessory()
        self.actions = actions()
    }

    public var body: some View {
        KboGlassPanel(style: .navigation, cornerRadius: KboRadiusToken.xLarge) {
            HStack(alignment: .center, spacing: KboSpacingToken.large) {
                leadingAccessory

                VStack(alignment: .leading, spacing: KboSpacingToken.small) {
                    if let eyebrow, eyebrow.isEmpty == false {
                        Text(eyebrow)
                            .font(KboTypographyToken.caption(scaledBy: fontScale))
                            .foregroundStyle(KboSemanticColorToken.accentNeutral)
                            .textCase(.uppercase)
                            .tracking(0.8)
                    }

                    Text(title)
                        .font(KboTypographyToken.system(size: 22, weight: .bold, scaledBy: fontScale))
                        .foregroundStyle(KboSemanticColorToken.contentPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)

                    if let subtitle, subtitle.isEmpty == false {
                        Text(subtitle)
                            .font(KboTypographyToken.footnote(scaledBy: fontScale))
                            .foregroundStyle(KboSemanticColorToken.contentSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: KboSpacingToken.small)

                actions
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, KboSpacingToken.xLarge)
            .padding(.vertical, KboSpacingToken.large)
        }
    }
}
