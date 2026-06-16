import Foundation

public enum GameDTOMapper {
    public static func map(_ dto: GameDTO) -> Game {
        Game(
            id: dto.gameId,
            date: dto.date,
            venue: nilIfBlank(dto.venue),
            startTime: parseStartTime(dto.startTime),
            broadcastChannels: (dto.broadcastChannels ?? []).compactMap(nilIfBlank),
            homepageLinks: mapHomepageLinks(dto.homepageLinks),
            pitcherDecisions: mapPitcherDecisions(dto.pitcherDecisions),
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
            teamRecords: mapTeamRecords(dto.teamRecords),
            boxScore: mapBoxScore(dto.boxScore),
            lineupPreview: mapLineupPreview(dto.lineupPreview),
            analysis: mapAnalysis(dto.analysis),
            sourceMeta: SourceMeta(
                rawStatusCode: dto.sourceMeta.rawStatusCode,
                rawTopBottomCode: dto.sourceMeta.rawTopBottomCode,
                fetchedAt: dto.sourceMeta.fetchedAt
            )
        )
    }

    static func mapTeamRecords(_ dto: TeamRecordsDTO?) -> TeamRecords? {
        guard let dto else { return nil }
        return TeamRecords(
            away: dto.away.map(mapTeamRecordSummary),
            home: dto.home.map(mapTeamRecordSummary)
        )
    }

    static func mapHomepageLinks(_ dto: HomepageLinksDTO?) -> HomepageLinks? {
        guard let dto else { return nil }
        let links = HomepageLinks(
            gameCenter: nilIfBlank(dto.gameCenter),
            preview: nilIfBlank(dto.preview),
            review: nilIfBlank(dto.review),
            highlight: nilIfBlank(dto.highlight)
        )
        guard links.gameCenter != nil || links.preview != nil || links.review != nil || links.highlight != nil else {
            return nil
        }
        return links
    }

    static func mapPitcherDecisions(_ dto: PitcherDecisionsDTO?) -> PitcherDecisions? {
        guard let dto else { return nil }
        let decisions = PitcherDecisions(
            win: nilIfBlank(dto.win),
            loss: nilIfBlank(dto.loss),
            save: nilIfBlank(dto.save)
        )
        guard decisions.win != nil || decisions.loss != nil || decisions.save != nil else {
            return nil
        }
        return decisions
    }

    static func mapTeamRecordSummary(_ dto: TeamRecordSummaryDTO) -> TeamRecordSummary {
        TeamRecordSummary(
            wins: dto.wins,
            losses: dto.losses,
            draws: dto.draws,
            rank: dto.rank,
            streak: nilIfBlank(dto.streak)
        )
    }

    static func mapBoxScore(_ dto: BoxScoreDTO?) -> BoxScore? {
        guard let dto else { return nil }
        return BoxScore(
            away: mapTeamBoxScore(dto.away),
            home: mapTeamBoxScore(dto.home),
            linescore: dto.linescore.map { InningScore(inning: $0.inning, away: $0.away, home: $0.home) }
        )
    }

    static func mapTeamBoxScore(_ dto: TeamBoxScoreDTO) -> TeamBoxScore {
        TeamBoxScore(runs: dto.runs, hits: dto.hits, errors: dto.errors, walks: dto.walks)
    }

    static func mapLineupPreview(_ dto: LineupPreviewDTO?) -> LineupPreview? {
        guard let dto else { return nil }
        let away = dto.away.compactMap(nilIfBlank)
        let home = dto.home.compactMap(nilIfBlank)
        guard !away.isEmpty || !home.isEmpty else { return nil }
        return LineupPreview(away: away, home: home)
    }

    static func mapAnalysis(_ dto: TeamAnalysisDTO?) -> TeamAnalysis? {
        guard let dto else { return nil }
        let keyPoints = dto.keyPoints.compactMap(nilIfBlank)
        let awaySummary = nilIfBlank(dto.awaySummary)
        let homeSummary = nilIfBlank(dto.homeSummary)
        guard awaySummary != nil || homeSummary != nil || !keyPoints.isEmpty else { return nil }
        return TeamAnalysis(awaySummary: awaySummary, homeSummary: homeSummary, keyPoints: keyPoints)
    }

    static func nilIfBlank(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func parseStartTime(_ value: String?) -> Date? {
        guard let value = nilIfBlank(value) else { return nil }
        return makeKboStartTimeDateFormatter().date(from: value)
            ?? makeKboBasicDateFormatter().date(from: value)
            ?? makeKboExtendedDateFormatter().date(from: value)
    }

    private static func makeKboStartTimeDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd'T'HH:mm:ssXXXXX"
        return formatter
    }

    private static func makeKboBasicDateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withTimeZone]
        return formatter
    }

    private static func makeKboExtendedDateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }
}
