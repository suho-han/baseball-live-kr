import Foundation

public struct MenuBarGameSummary: Sendable, Equatable {
    public let gameId: String
    public let status: GameStatus
    public let isLive: Bool
    public let primaryText: String
    public let secondaryText: String?

    public init(
        gameId: String,
        status: GameStatus,
        isLive: Bool,
        primaryText: String,
        secondaryText: String?
    ) {
        self.gameId = gameId
        self.status = status
        self.isLive = isLive
        self.primaryText = primaryText
        self.secondaryText = secondaryText
    }
}
