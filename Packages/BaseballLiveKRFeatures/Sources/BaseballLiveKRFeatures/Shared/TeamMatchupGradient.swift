import SwiftUI
#if canImport(BaseballLiveKRDesignSystem)
import BaseballLiveKRDesignSystem
#endif

enum TeamMatchupGradient {
    static func background(awayTeamID: String, homeTeamID: String) -> LinearGradient {
        LinearGradient(
            colors: colors(awayTeamID: awayTeamID, homeTeamID: homeTeamID),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var readabilityScrim: LinearGradient {
        LinearGradient(
            colors: [
                Color.black.opacity(0.72),
                Color.black.opacity(0.64),
                Color.black.opacity(0.64),
                Color.black.opacity(0.72)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func pageTint(awayTeamID: String, homeTeamID: String) -> LinearGradient {
        let awayColor = TeamColorResolver.color(forTeamID: awayTeamID)
        let homeColor = TeamColorResolver.color(forTeamID: homeTeamID)

        return LinearGradient(
            colors: [
                awayColor.opacity(0.28),
                awayColor.opacity(0.12),
                Color.clear,
                homeColor.opacity(0.12),
                homeColor.opacity(0.28)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private static func colors(awayTeamID: String, homeTeamID: String) -> [Color] {
        let awayColor = TeamColorResolver.color(forTeamID: awayTeamID)
        let homeColor = TeamColorResolver.color(forTeamID: homeTeamID)

        return [
            awayColor.opacity(0.44),
            awayColor.opacity(0.26),
            homeColor.opacity(0.26),
            homeColor.opacity(0.44)
        ]
    }
}
