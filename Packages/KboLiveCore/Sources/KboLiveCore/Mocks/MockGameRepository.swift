import Foundation

public struct MockGameRepository: GameRepository, Sendable {
    public let todayGames: TodayGames
    public let gameDetailsById: [String: GameDetail]

    public init(todayGames: TodayGames, gameDetailsById: [String: GameDetail] = [:]) {
        self.todayGames = todayGames
        self.gameDetailsById = gameDetailsById
    }

    public func fetchTodayGames(date: String? = nil) async throws -> TodayGames {
        todayGames
    }

    public func fetchGameDetail(gameId: String, date: String? = nil) async throws -> GameDetail {
        gameDetailsById[gameId] ?? GameDetail(date: todayGames.date, game: nil)
    }
}
