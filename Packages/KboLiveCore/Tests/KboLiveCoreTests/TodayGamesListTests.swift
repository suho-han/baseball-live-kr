import Foundation
import Testing
@testable import KboLiveCore

struct TodayGamesListTests {
    @Test func orderedGamesPrioritizesLiveThenScheduledStates() {
        let todayGames = TodayGames(
            date: "20260610",
            games: [
                makeGame(id: "final", status: .final, startHour: 18),
                makeGame(id: "scheduled-late", status: .scheduled, startHour: 19),
                makeGame(id: "live", status: .live, startHour: 18),
                makeGame(id: "delayed", status: .delayed, startHour: 17),
                makeGame(id: "scheduled-early", status: .scheduled, startHour: 17),
                makeGame(id: "cancelled", status: .cancelled, startHour: 16)
            ]
        )

        let orderedIds = todayGames.orderedGames().map(\.id)

        #expect(orderedIds == [
            "live",
            "scheduled-early",
            "scheduled-late",
            "delayed",
            "final",
            "cancelled"
        ])
    }

    @Test func scheduledFilterIncludesDelayedGames() {
        let todayGames = TodayGames(
            date: "20260610",
            games: [
                makeGame(id: "live", status: .live, startHour: 18),
                makeGame(id: "scheduled", status: .scheduled, startHour: 17),
                makeGame(id: "delayed", status: .delayed, startHour: 19),
                makeGame(id: "final", status: .final, startHour: 16)
            ]
        )

        let orderedIds = todayGames.orderedGames(filter: .scheduled).map(\.id)

        #expect(orderedIds == ["scheduled", "delayed"])
    }

    @Test func finalFilterIncludesCancelledGames() {
        let todayGames = TodayGames(
            date: "20260610",
            games: [
                makeGame(id: "cancelled", status: .cancelled, startHour: 16),
                makeGame(id: "final", status: .final, startHour: 18),
                makeGame(id: "live", status: .live, startHour: 17)
            ]
        )

        let orderedIds = todayGames.orderedGames(filter: .final).map(\.id)

        #expect(orderedIds == ["final", "cancelled"])
    }
}

private func makeGame(id: String, status: GameStatus, startHour: Int) -> Game {
    let calendar = Calendar(identifier: .gregorian)
    let startTime = calendar.date(from: DateComponents(
        timeZone: TimeZone(identifier: "Asia/Seoul"),
        year: 2026,
        month: 6,
        day: 10,
        hour: startHour,
        minute: 30
    ))

    return Game(
        id: id,
        date: "20260610",
        venue: "잠실",
        startTime: startTime,
        status: status,
        awayTeam: Team(id: "LG", name: "LG"),
        homeTeam: Team(id: "OB", name: "두산"),
        score: Score(away: 0, home: 0),
        inning: nil,
        count: nil,
        bases: nil,
        current: nil,
        probablePitchers: ProbablePitchers(away: nil, home: nil),
        recentPlay: nil,
        sourceMeta: SourceMeta(rawStatusCode: nil, rawTopBottomCode: nil, fetchedAt: "2026-06-10T10:05:00.000Z")
    )
}
