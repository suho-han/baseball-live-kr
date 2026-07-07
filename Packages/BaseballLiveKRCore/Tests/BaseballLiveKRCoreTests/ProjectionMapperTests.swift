import Foundation
import Testing
@testable import BaseballLiveKRCore

struct ProjectionMapperTests {
    @Test func mapsScheduledGameToWidgetSnapshot() throws {
        let response = try loadFixtureResponse()
        let game = GameDTOMapper.map(try #require(response.games.first))
        let snapshot = WidgetGameSnapshotMapper.map(game)

        #expect(snapshot.gameId == "20260610SKLG0")
        #expect(snapshot.awayTeamName == "SSG")
        #expect(snapshot.homeTeamName == "LG")
        #expect(snapshot.status == .scheduled)
        #expect(snapshot.inningText == "18:30 예정")
        #expect(snapshot.baseState == BasesState(first: false, second: false, third: false))
        #expect(snapshot.recentPlay == nil)
        #expect(snapshot.headline == "대표 경기")
        #expect(snapshot.contextText == "18:30 예정 · 잠실")
        #expect(snapshot.isFavoriteTeamGame == false)
        #expect(snapshot.fallbackKind == .none)
    }

    @Test func mapsFavoriteTeamGameToPersonalizedWidgetSnapshot() throws {
        let response = try loadFixtureResponse()
        let game = GameDTOMapper.map(response.games[1])
        let snapshot = WidgetGameSnapshotMapper.map(game, favoriteTeamID: "HH")

        #expect(snapshot.headline == "나의 팀 경기")
        #expect(snapshot.contextText == "한화 경기 · LIVE · 7회말 · 대전")
        #expect(snapshot.isFavoriteTeamGame == true)
        #expect(snapshot.fallbackKind == .none)
    }

    @Test func mapsFavoriteTeamNoGameWidgetFallback() throws {
        let response = try loadFixtureResponse()
        let game = GameDTOMapper.map(response.games[1])
        let snapshot = WidgetGameSnapshotMapper.map(
            game,
            favoriteTeamID: "LG",
            fallbackKind: .favoriteTeamNoGame
        )

        #expect(snapshot.headline == "응원팀 경기 없음")
        #expect(snapshot.contextText == "LG 오늘 경기 없음 · 대표 경기")
        #expect(snapshot.isFavoriteTeamGame == false)
        #expect(snapshot.fallbackKind == .favoriteTeamNoGame)
    }

    @Test func mapsNoFavoriteTeamSelectedWidgetFallback() throws {
        let response = try loadFixtureResponse()
        let game = GameDTOMapper.map(response.games[1])
        let snapshot = WidgetGameSnapshotMapper.map(game, fallbackKind: .favoriteTeamNotSelected)

        #expect(snapshot.headline == "응원팀을 선택하세요")
        #expect(snapshot.contextText == "대표 경기 · LIVE · 7회말 · 대전")
        #expect(snapshot.isFavoriteTeamGame == false)
        #expect(snapshot.fallbackKind == .favoriteTeamNotSelected)
    }

    @Test func mapsTodayGamesToFavoriteTeamWidgetSnapshot() throws {
        let response = try loadFixtureResponse()
        let todayGames = TodayGames(
            date: response.date,
            games: response.games.map { GameDTOMapper.map($0) }
        )

        let snapshot: WidgetGameSnapshot = try #require(
            WidgetGameSnapshotMapper.map(todayGames: todayGames, favoriteTeamID: "HH")
        )

        #expect(snapshot.gameId == "20260610HTHH0")
        #expect(snapshot.headline == "나의 팀 경기")
        #expect(snapshot.isFavoriteTeamGame == true)
    }

    @Test func mapsTodayGamesToNoFavoriteSelectedFallback() throws {
        let response = try loadFixtureResponse()
        let todayGames = TodayGames(
            date: response.date,
            games: response.games.map { GameDTOMapper.map($0) }
        )

        let snapshot: WidgetGameSnapshot = try #require(
            WidgetGameSnapshotMapper.map(todayGames: todayGames, favoriteTeamID: nil)
        )

        #expect(snapshot.headline == "응원팀을 선택하세요")
        #expect(snapshot.fallbackKind == .favoriteTeamNotSelected)
    }

    @Test func widgetSnapshotRoundTripsThroughJSON() throws {
        let response = try loadFixtureResponse()
        let game = GameDTOMapper.map(response.games[1])
        let snapshot = WidgetGameSnapshotMapper.map(game, favoriteTeamID: "HH")

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(WidgetGameSnapshot.self, from: data)

        #expect(decoded == snapshot)
    }

    @Test func mapsLiveGameToActivityState() throws {
        let response = try loadFixtureResponse()
        let game = GameDTOMapper.map(response.games[1])
        let state = ActivityGameStateMapper.map(game)

        #expect(state.awayScore == 3)
        #expect(state.homeScore == 2)
        #expect(state.status == .live)
        #expect(state.inningText == "7회말")
        #expect(state.outs == 2)
        #expect(state.hasRunnerOnFirst == true)
        #expect(state.hasRunnerOnSecond == false)
        #expect(state.hasRunnerOnThird == true)
        #expect(state.shortRecentPlay == "좌전 적시타")
    }

    @Test func mapsLiveGameToMenuBarSummary() throws {
        let response = try loadFixtureResponse()
        let game = GameDTOMapper.map(response.games[1])
        let summary = MenuBarGameSummaryMapper.map(game)

        #expect(summary.gameId == "20260610HTHH0")
        #expect(summary.status == .live)
        #expect(summary.isLive == true)
        #expect(summary.primaryText == "KIA 3:2 한화")
        #expect(summary.secondaryText == "LIVE · 7회말 · 2사")
        #expect(summary.recentPlay == "좌전 적시타")
    }

    @Test func formatsScheduledMenuBarTeamDetailsWithProbablePitchers() {
        let game = makeMenuBarTeamDetailGame(
            status: .scheduled,
            probablePitchers: ProbablePitchers(
                away: ProbablePitcher(name: "  네일  "),
                home: ProbablePitcher(name: "류현진")
            )
        )

        let details = GameProjectionFormatter.menuBarTeamDetails(for: game)

        #expect(details.away == "네일")
        #expect(details.home == "류현진")
    }

    @Test func formatsLiveTopMenuBarTeamDetailsWithAwayBatterAndHomePitcher() {
        let game = makeMenuBarTeamDetailGame(
            status: .live,
            score: Score(away: 2, home: 1),
            inning: InningState(number: 4, half: .top),
            current: CurrentMatchup(batter: "김도영", pitcher: "류현진"),
            probablePitchers: staleProbablePitchers()
        )

        let details = GameProjectionFormatter.menuBarTeamDetails(for: game)

        #expect(details.away == "타자 김도영")
        #expect(details.home == "P 류현진")
    }

    @Test func formatsLiveBottomMenuBarTeamDetailsWithAwayPitcherAndHomeBatter() {
        let game = makeMenuBarTeamDetailGame(
            status: .live,
            score: Score(away: 2, home: 1),
            inning: InningState(number: 4, half: .bottom),
            current: CurrentMatchup(batter: "노시환", pitcher: "네일"),
            probablePitchers: staleProbablePitchers()
        )

        let details = GameProjectionFormatter.menuBarTeamDetails(for: game)

        #expect(details.away == "P 네일")
        #expect(details.home == "타자 노시환")
    }

    @Test func formatsFinalHomeWinMenuBarTeamDetailsWithDecisions() {
        let game = makeMenuBarTeamDetailGame(
            status: .final,
            score: Score(away: 3, home: 5),
            pitcherDecisions: PitcherDecisions(win: "문동주", loss: "네일"),
            probablePitchers: staleProbablePitchers()
        )

        let details = GameProjectionFormatter.menuBarTeamDetails(for: game)

        #expect(details.away == "패 네일")
        #expect(details.home == "승 문동주")
    }

    @Test func formatsFinalAwayWinMenuBarTeamDetailsWithDecisions() {
        let game = makeMenuBarTeamDetailGame(
            status: .final,
            score: Score(away: 6, home: 2),
            pitcherDecisions: PitcherDecisions(win: "네일", loss: "문동주"),
            probablePitchers: staleProbablePitchers()
        )

        let details = GameProjectionFormatter.menuBarTeamDetails(for: game)

        #expect(details.away == "승 네일")
        #expect(details.home == "패 문동주")
    }

    @Test func suppressesMenuBarTeamDetailsForLiveAndFinalMissingData() {
        let liveGame = makeMenuBarTeamDetailGame(
            status: .live,
            score: Score(away: 2, home: 1),
            inning: InningState(number: 4, half: .top),
            current: CurrentMatchup(batter: " ", pitcher: nil),
            probablePitchers: staleProbablePitchers()
        )
        let finalGame = makeMenuBarTeamDetailGame(
            status: .final,
            score: Score(away: 3, home: 5),
            pitcherDecisions: nil,
            probablePitchers: staleProbablePitchers()
        )

        let liveDetails = GameProjectionFormatter.menuBarTeamDetails(for: liveGame)
        let finalDetails = GameProjectionFormatter.menuBarTeamDetails(for: finalGame)

        #expect(liveDetails.away == nil)
        #expect(liveDetails.home == nil)
        #expect(finalDetails.away == nil)
        #expect(finalDetails.home == nil)
    }

    @Test func truncatesLongRecentPlayForActivityState() {
        let game = makeGame(recentPlay: "오스틴의 좌중간 담장을 때리는 아주 긴 적시 2루타 설명")
        let state = ActivityGameStateMapper.map(game)

        #expect(state.shortRecentPlay == "오스틴의 좌중간 담장을 때리는 아주 긴 적…")
    }

    @Test func deduplicatesMenuBarStatusTokensWhenLiveHasNoInning() {
        let game = Game(
            id: "live-no-inning",
            date: "20260610",
            venue: "잠실",
            startTime: nil,
            status: .live,
            awayTeam: Team(id: "LG", name: "LG"),
            homeTeam: Team(id: "OB", name: "두산"),
            score: Score(away: 4, home: 3),
            inning: nil,
            count: CountState(balls: 1, strikes: 2, outs: 2),
            bases: BasesState(first: true, second: false, third: false),
            current: nil,
            probablePitchers: ProbablePitchers(away: ProbablePitcher(name: nil), home: ProbablePitcher(name: nil)),
            recentPlay: nil,
            sourceMeta: SourceMeta(rawStatusCode: nil, rawTopBottomCode: nil, fetchedAt: "2026-06-10T10:05:00.000Z")
        )

        #expect(GameProjectionFormatter.menuBarSecondaryText(for: game) == "LIVE · 2사")
    }

    @Test func deduplicatesMenuBarStatusTokensWhenDelayed() {
        let game = Game(
            id: "delayed",
            date: "20260610",
            venue: "잠실",
            startTime: nil,
            status: .delayed,
            awayTeam: Team(id: "LG", name: "LG"),
            homeTeam: Team(id: "OB", name: "두산"),
            score: Score(away: 0, home: 0),
            inning: nil,
            count: nil,
            bases: nil,
            current: nil,
            probablePitchers: ProbablePitchers(away: ProbablePitcher(name: nil), home: ProbablePitcher(name: nil)),
            recentPlay: nil,
            sourceMeta: SourceMeta(rawStatusCode: nil, rawTopBottomCode: nil, fetchedAt: "2026-06-10T10:05:00.000Z")
        )

        #expect(GameProjectionFormatter.menuBarSecondaryText(for: game) == "지연")
    }

    private func loadFixtureResponse() throws -> TodayGamesResponseDTO {
        let data = try FixtureLoader.loadData(named: "today-games-response")
        return try JSONDecoder().decode(TodayGamesResponseDTO.self, from: data)
    }

    private func makeGame(recentPlay: String?) -> Game {
        Game(
            id: "sample",
            date: "20260610",
            venue: "잠실",
            startTime: nil,
            status: .live,
            awayTeam: Team(id: "LG", name: "LG"),
            homeTeam: Team(id: "OB", name: "두산"),
            score: Score(away: 4, home: 3),
            inning: InningState(number: 9, half: .bottom),
            count: CountState(balls: 1, strikes: 2, outs: 2),
            bases: BasesState(first: true, second: true, third: false),
            current: CurrentMatchup(batter: "오스틴", pitcher: "박치국"),
            probablePitchers: ProbablePitchers(away: ProbablePitcher(name: nil), home: ProbablePitcher(name: nil)),
            recentPlay: recentPlay,
            sourceMeta: SourceMeta(rawStatusCode: nil, rawTopBottomCode: nil, fetchedAt: "2026-06-10T10:05:00.000Z")
        )
    }

    private func makeMenuBarTeamDetailGame(
        status: GameStatus,
        score: Score = Score(away: 0, home: 0),
        inning: InningState? = nil,
        current: CurrentMatchup? = nil,
        pitcherDecisions: PitcherDecisions? = nil,
        probablePitchers: ProbablePitchers = ProbablePitchers(
            away: ProbablePitcher(name: nil),
            home: ProbablePitcher(name: nil)
        )
    ) -> Game {
        Game(
            id: "menu-bar-team-detail",
            date: "20260610",
            venue: "잠실",
            startTime: nil,
            pitcherDecisions: pitcherDecisions,
            status: status,
            awayTeam: Team(id: "HT", name: "KIA"),
            homeTeam: Team(id: "HH", name: "한화"),
            score: score,
            inning: inning,
            count: nil,
            bases: nil,
            current: current,
            probablePitchers: probablePitchers,
            recentPlay: nil,
            sourceMeta: SourceMeta(rawStatusCode: nil, rawTopBottomCode: nil, fetchedAt: "2026-06-10T10:05:00.000Z")
        )
    }

    private func staleProbablePitchers() -> ProbablePitchers {
        ProbablePitchers(
            away: ProbablePitcher(name: "옛 원정 선발"),
            home: ProbablePitcher(name: "옛 홈 선발")
        )
    }
}
