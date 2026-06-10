import Foundation

public struct WidgetGameSnapshot: Sendable, Equatable {
    public let gameId: String
    public let awayTeamName: String
    public let homeTeamName: String
    public let awayScore: Int
    public let homeScore: Int
    public let status: GameStatus
    public let inningText: String?
    public let baseState: BasesState?
    public let recentPlay: String?

    public init(
        gameId: String,
        awayTeamName: String,
        homeTeamName: String,
        awayScore: Int,
        homeScore: Int,
        status: GameStatus,
        inningText: String?,
        baseState: BasesState?,
        recentPlay: String?
    ) {
        self.gameId = gameId
        self.awayTeamName = awayTeamName
        self.homeTeamName = homeTeamName
        self.awayScore = awayScore
        self.homeScore = homeScore
        self.status = status
        self.inningText = inningText
        self.baseState = baseState
        self.recentPlay = recentPlay
    }
}
