import Foundation

public enum WidgetGameSnapshotMapper {
    public static func map(_ game: Game) -> WidgetGameSnapshot {
        WidgetGameSnapshot(
            gameId: game.id,
            awayTeamName: game.awayTeam.name,
            homeTeamName: game.homeTeam.name,
            awayScore: game.score.away,
            homeScore: game.score.home,
            status: game.status,
            inningText: GameProjectionFormatter.inningText(for: game),
            baseState: game.bases,
            recentPlay: GameProjectionFormatter.shortRecentPlay(game.recentPlay, limit: 32)
        )
    }
}
