import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct GameFeedClient: Sendable {
    public let repository: any GameRepository
    public let pollingInterval: Duration

    public init(repository: any GameRepository, pollingInterval: Duration = .seconds(15)) {
        self.repository = repository
        self.pollingInterval = pollingInterval
    }

    public static func live(
        environment: KboLiveEnvironment,
        session: any HTTPSession = URLSession.shared
    ) -> GameFeedClient {
        let apiClient = URLSessionKboLiveAPIClient(
            baseURL: environment.baseURL,
            session: session
        )
        let repository = LiveGameRepository(apiClient: apiClient)
        return GameFeedClient(
            repository: repository,
            pollingInterval: environment.pollingInterval
        )
    }

    public static func live(
        baseURL: URL,
        pollingInterval: Duration = .seconds(15),
        session: any HTTPSession = URLSession.shared
    ) -> GameFeedClient {
        live(
            environment: KboLiveEnvironment(baseURL: baseURL, pollingInterval: pollingInterval),
            session: session
        )
    }

    public func fetchTodayGames(date: String? = nil) async throws -> TodayGames {
        try await repository.fetchTodayGames(date: date)
    }

    public func fetchGameDetail(gameId: String, date: String? = nil) async throws -> GameDetail {
        try await repository.fetchGameDetail(gameId: gameId, date: date)
    }

    public func streamTodayGames(date: String? = nil) -> AsyncThrowingStream<TodayGames, Error> {
        LiveGamePollingService(
            repository: repository,
            interval: pollingInterval
        ).streamTodayGames(date: date)
    }
}
