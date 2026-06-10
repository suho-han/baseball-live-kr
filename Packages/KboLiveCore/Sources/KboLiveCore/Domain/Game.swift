import Foundation

public struct Game: Identifiable, Sendable, Equatable {
    public let id: String
    public let date: String
    public let venue: String?
    public let startTime: Date?
    public let status: GameStatus
    public let awayTeam: Team
    public let homeTeam: Team
    public let score: Score
    public let inning: InningState?
    public let count: CountState?
    public let bases: BasesState?
    public let current: CurrentMatchup?
    public let probablePitchers: ProbablePitchers
    public let recentPlay: String?
    public let sourceMeta: SourceMeta

    public init(
        id: String,
        date: String,
        venue: String?,
        startTime: Date?,
        status: GameStatus,
        awayTeam: Team,
        homeTeam: Team,
        score: Score,
        inning: InningState?,
        count: CountState?,
        bases: BasesState?,
        current: CurrentMatchup?,
        probablePitchers: ProbablePitchers,
        recentPlay: String?,
        sourceMeta: SourceMeta
    ) {
        self.id = id
        self.date = date
        self.venue = venue
        self.startTime = startTime
        self.status = status
        self.awayTeam = awayTeam
        self.homeTeam = homeTeam
        self.score = score
        self.inning = inning
        self.count = count
        self.bases = bases
        self.current = current
        self.probablePitchers = probablePitchers
        self.recentPlay = recentPlay
        self.sourceMeta = sourceMeta
    }
}

public struct Team: Sendable, Equatable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct Score: Sendable, Equatable {
    public let away: Int
    public let home: Int

    public init(away: Int, home: Int) {
        self.away = away
        self.home = home
    }
}

public struct InningState: Sendable, Equatable {
    public let number: Int
    public let half: InningHalf

    public init(number: Int, half: InningHalf) {
        self.number = number
        self.half = half
    }
}

public struct CountState: Sendable, Equatable {
    public let balls: Int
    public let strikes: Int
    public let outs: Int

    public init(balls: Int, strikes: Int, outs: Int) {
        self.balls = balls
        self.strikes = strikes
        self.outs = outs
    }
}

public struct BasesState: Sendable, Equatable {
    public let first: Bool
    public let second: Bool
    public let third: Bool

    public init(first: Bool, second: Bool, third: Bool) {
        self.first = first
        self.second = second
        self.third = third
    }
}

public struct CurrentMatchup: Sendable, Equatable {
    public let batter: String?
    public let pitcher: String?

    public init(batter: String?, pitcher: String?) {
        self.batter = batter
        self.pitcher = pitcher
    }
}

public struct ProbablePitchers: Sendable, Equatable {
    public let away: String?
    public let home: String?

    public init(away: String?, home: String?) {
        self.away = away
        self.home = home
    }
}

public struct SourceMeta: Sendable, Equatable {
    public let rawStatusCode: String?
    public let rawTopBottomCode: String?
    public let fetchedAt: String

    public init(rawStatusCode: String?, rawTopBottomCode: String?, fetchedAt: String) {
        self.rawStatusCode = rawStatusCode
        self.rawTopBottomCode = rawTopBottomCode
        self.fetchedAt = fetchedAt
    }
}

public enum GameStatus: String, Sendable, Equatable {
    case scheduled
    case live
    case final
    case delayed
    case cancelled
    case unknown
}

public enum InningHalf: String, Sendable, Equatable {
    case top
    case bottom
}
