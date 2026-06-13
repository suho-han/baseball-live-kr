import Foundation
import Testing
@testable import KboLiveCore

struct GameRepositoryTests {
    @Test func repositoryMapsTodayGamesIntoDomain() async throws {
        let dto = GameDTO(
            gameId: "20260610HTHH0",
            date: "20260610",
            venue: "대전",
            startTime: "2026-06-10T18:30:00+09:00",
            status: .live,
            awayTeam: TeamDTO(id: "HT", name: "KIA"),
            homeTeam: TeamDTO(id: "HH", name: "한화"),
            score: ScoreDTO(away: 3, home: 2),
            inning: InningDTO(number: 7, half: .bottom),
            count: CountDTO(balls: 1, strikes: 2, outs: 2),
            bases: BasesDTO(first: true, second: false, third: true),
            current: CurrentMatchupDTO(batter: "최원준", pitcher: "김서현"),
            probablePitchers: ProbablePitchersDTO(away: "네일", home: "문동주"),
            recentPlay: "좌전 적시타",
            sourceMeta: SourceMetaDTO(rawStatusCode: "2", rawTopBottomCode: "B", fetchedAt: "2026-06-10T10:05:00.000Z")
        )

        let repository = LiveGameRepository(
            apiClient: StubAPIClient(
                todayGames: TodayGamesResponseDTO(date: "20260610", games: [dto]),
                gameDetail: GameDetailResponseDTO(date: "20260610", game: dto)
            )
        )

        let result = try await repository.fetchTodayGames(date: "2026-06-10")

        #expect(result.date == "20260610")
        #expect(result.games.count == 1)
        #expect(result.games[0].status == .live)
        #expect(result.games[0].current?.batter == "최원준")
    }

    @Test func repositoryMapsOptionalGameDetail() async throws {
        let repository = LiveGameRepository(
            apiClient: StubAPIClient(
                todayGames: TodayGamesResponseDTO(date: "20260610", games: []),
                gameDetail: GameDetailResponseDTO(date: "20260610", game: nil)
            )
        )

        let result = try await repository.fetchGameDetail(gameId: "missing", date: "2026-06-10")

        #expect(result.date == "20260610")
        #expect(result.game == nil)
    }
}

private struct StubAPIClient: KboLiveAPIClient, Sendable {
    let todayGames: TodayGamesResponseDTO
    let gameDetail: GameDetailResponseDTO

    func fetchTodayGames(date: String?) async throws -> TodayGamesResponseDTO {
        todayGames
    }

    func fetchGameDetail(gameId: String, date: String?) async throws -> GameDetailResponseDTO {
        gameDetail
    }
}
