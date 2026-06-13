import Foundation

public protocol GameRepository: Sendable {
    func fetchTodayGames(date: String?) async throws -> TodayGames
    func fetchGameDetail(gameId: String, date: String?) async throws -> GameDetail
}

public struct LiveGameRepository: GameRepository, Sendable {
    private let apiClient: any KboLiveAPIClient

    public init(apiClient: any KboLiveAPIClient) {
        self.apiClient = apiClient
    }

    public func fetchTodayGames(date: String? = nil) async throws -> TodayGames {
        let response = try await apiClient.fetchTodayGames(date: date)
        return TodayGames(
            date: response.date,
            games: response.games.map(GameDTOMapper.map)
        )
    }

    public func fetchGameDetail(gameId: String, date: String? = nil) async throws -> GameDetail {
        let response = try await apiClient.fetchGameDetail(gameId: gameId, date: date)
        return GameDetail(
            date: response.date,
            game: response.game.map(GameDTOMapper.map)
        )
    }
}
