import Foundation

public enum GameDTOMapper {
    public static func map(_ dto: GameDTO) -> Game {
        Game(
            id: dto.gameId,
            date: dto.date,
            venue: nilIfBlank(dto.venue),
            startTime: ISO8601DateFormatter.kbo.date(from: dto.startTime ?? ""),
            status: GameStatus(rawValue: dto.status.rawValue) ?? .unknown,
            awayTeam: Team(id: dto.awayTeam.id, name: dto.awayTeam.name),
            homeTeam: Team(id: dto.homeTeam.id, name: dto.homeTeam.name),
            score: Score(away: dto.score.away, home: dto.score.home),
            inning: dto.inning.map { InningState(number: $0.number, half: InningHalf(rawValue: $0.half.rawValue) ?? .top) },
            count: dto.count.map { CountState(balls: $0.balls, strikes: $0.strikes, outs: $0.outs) },
            bases: dto.bases.map { BasesState(first: $0.first, second: $0.second, third: $0.third) },
            current: dto.current.map { CurrentMatchup(batter: nilIfBlank($0.batter), pitcher: nilIfBlank($0.pitcher)) },
            probablePitchers: ProbablePitchers(
                away: nilIfBlank(dto.probablePitchers.away),
                home: nilIfBlank(dto.probablePitchers.home)
            ),
            recentPlay: nilIfBlank(dto.recentPlay),
            sourceMeta: SourceMeta(
                rawStatusCode: dto.sourceMeta.rawStatusCode,
                rawTopBottomCode: dto.sourceMeta.rawTopBottomCode,
                fetchedAt: dto.sourceMeta.fetchedAt
            )
        )
    }

    static func nilIfBlank(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension ISO8601DateFormatter {
    static let kbo: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
