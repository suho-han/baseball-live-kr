import Foundation
import Testing
@testable import KboLiveCore

struct TodayGamesResponseDTOTests {
    @Test func decodesTodayGamesFixture() throws {
        let data = try FixtureLoader.loadData(named: "today-games-response")
        let decoded = try JSONDecoder().decode(TodayGamesResponseDTO.self, from: data)

        #expect(decoded.date == "20260610")
        #expect(decoded.games.count == 2)
        #expect(decoded.games.first?.gameId == "20260610SKLG0")
        #expect(decoded.games.first?.awayTeam.name == "SSG")
        #expect(decoded.games.first?.homeTeam.name == "LG")
        #expect(decoded.games.first?.status == .scheduled)
    }

    @Test func mapsBlankStringsToNilInDomain() throws {
        let data = try FixtureLoader.loadData(named: "today-games-response")
        let decoded = try JSONDecoder().decode(TodayGamesResponseDTO.self, from: data)
        let game = try #require(decoded.games.first)
        let mapped = GameDTOMapper.map(game)

        #expect(mapped.current?.batter == nil)
        #expect(mapped.current?.pitcher == nil)
        #expect(mapped.probablePitchers.away == nil)
        #expect(mapped.probablePitchers.home == nil)
    }

    @Test func parsesIsoStartTimeIntoDate() throws {
        let data = try FixtureLoader.loadData(named: "today-games-response")
        let decoded = try JSONDecoder().decode(TodayGamesResponseDTO.self, from: data)
        let game = try #require(decoded.games[1])
        let mapped = GameDTOMapper.map(game)

        #expect(mapped.startTime != nil)
        #expect(mapped.status == .live)
        #expect(mapped.inning?.number == 7)
        #expect(mapped.inning?.half == .bottom)
    }
}
