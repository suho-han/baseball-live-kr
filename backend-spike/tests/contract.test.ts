import { mkdtempSync, readFileSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import path, { join } from 'node:path'

import { z } from 'zod'
import { afterEach, describe, expect, it, vi } from 'vitest'

import { closeDatabase } from '../src/db/database.js'
import { makeTestLiveGame } from '../src/fixtures/testLiveGame.js'
import { upsertBattingSeasonRecords, upsertPitchingSeasonRecords } from '../src/repositories/playerRecordRepository.js'
import { getTeamStandings } from '../src/services/gameService.js'
import { buildServer } from '../src/server.js'

vi.mock('../src/services/gameService.js', () => ({
  getTodayGames: vi.fn(),
  getGameById: vi.fn(),
  getTeamStandings: vi.fn(),
  getTodayGamesRaw: vi.fn()
}))

const CONTRACT_DATE = '20260615'
const CONTRACT_FETCHED_AT = '2026-06-15T12:00:00.000Z'
const PLAYER_CONTRACT_DATE = '20260618'
const SWIFT_CONTRACT_FIXTURE = path.resolve(
  '..',
  'Packages/BaseballLiveKRCore/Tests/BaseballLiveKRCoreTests/Fixtures/live-test-game-response.json'
)

const nullableNumber = z.number().nullable()
const nullableString = z.string().nullable()
const nullableNumberFields = (fields: readonly string[]) => Object.fromEntries(
  fields.map((field) => [field, nullableNumber])
)

const teamStandingSchema = z.object({
  teamId: z.string(),
  teamName: z.string(),
  wins: z.number(),
  losses: z.number(),
  draws: z.number(),
  rank: nullableNumber,
  streak: nullableString,
  winRate: nullableString,
  recentTen: nullableString,
  gamesBack: nullableString
}).strict()

const playerSearchResultSchema = z.object({
  playerId: z.string(),
  playerName: z.string(),
  teamId: nullableString,
  season: nullableNumber,
  positionGroup: z.enum(['batter', 'pitcher', 'twoWay']).nullable()
}).strict()

const battingRecordSchema = z.object({
  season: z.number(),
  date: z.string(),
  player_id: z.string(),
  team_id: z.string(),
  ...nullableNumberFields([
    'rank', 'games', 'plate_appearances', 'at_bats', 'hits', 'doubles', 'triples',
    'home_runs', 'total_bases', 'rbi', 'runs', 'walks', 'strikeouts', 'stolen_bases',
    'caught_stealing', 'sacrifice_hits', 'sacrifice_flies', 'avg', 'obp', 'slg', 'ops'
  ]),
  source: z.string(),
  raw_source_id: nullableString,
  created_at: z.string(),
  updated_at: z.string()
}).strict()

const pitchingRecordSchema = z.object({
  season: z.number(),
  date: z.string(),
  player_id: z.string(),
  team_id: z.string(),
  ...nullableNumberFields([
    'rank', 'games', 'games_started', 'complete_games', 'shutouts', 'wins', 'losses',
    'saves', 'holds', 'winning_percentage', 'plate_appearances', 'pitches',
    'innings_pitched_outs', 'hits_allowed', 'doubles_allowed', 'triples_allowed',
    'home_runs_allowed', 'walks', 'strikeouts', 'earned_runs', 'era', 'whip'
  ]),
  source: z.string(),
  raw_source_id: nullableString,
  created_at: z.string(),
  updated_at: z.string(),
  ...nullableNumberFields([
    'strikeouts_per_nine', 'walks_per_nine', 'strikeout_walk_ratio',
    'opponent_obp', 'opponent_slg', 'opponent_ops'
  ])
}).strict()

const playerSeasonRecordSchema = z.object({
  playerId: z.string(),
  playerName: z.string(),
  season: z.number(),
  teamId: z.string(),
  batting: battingRecordSchema.nullable(),
  pitching: pitchingRecordSchema.nullable()
}).strict()

const standingsResponseSchema = z.object({
  date: z.string(),
  standings: z.array(teamStandingSchema)
}).strict()

const playerSearchResponseSchema = z.object({
  players: z.array(playerSearchResultSchema)
}).strict()

const playerSeasonResponseSchema = z.object({
  player: playerSeasonRecordSchema.nullable()
}).strict()

const mockTeamStandings = vi.mocked(getTeamStandings)

function responseJson(body: string): unknown {
  return JSON.parse(body)
}

describe('normalized API contract fixtures', () => {
  const tempDirs: string[] = []

  afterEach(() => {
    closeDatabase()
    for (const dir of tempDirs.splice(0)) {
      rmSync(dir, { recursive: true, force: true })
    }
    delete process.env.BASEBALL_LIVE_KR_DB_ENABLED
    delete process.env.BASEBALL_LIVE_KR_DB_PATH
    vi.clearAllMocks()
  })

  it('keeps the backend live test fixture in sync with the Swift DTO fixture', () => {
    const swiftFixture = JSON.parse(readFileSync(SWIFT_CONTRACT_FIXTURE, 'utf8'))
    const backendFixture = {
      date: CONTRACT_DATE,
      games: [makeTestLiveGame(CONTRACT_DATE, CONTRACT_FETCHED_AT)]
    }

    expect(backendFixture).toEqual(swiftFixture)
  })

  it('freezes the v1 standings response contract', async () => {
    mockTeamStandings.mockResolvedValue({
      date: CONTRACT_DATE,
      standings: [{
        teamId: 'LG',
        teamName: 'LG',
        wins: 41,
        losses: 28,
        draws: 2,
        rank: 1,
        streak: '2승',
        winRate: '0.594',
        recentTen: '6승0무4패',
        gamesBack: '0.0'
      }]
    })

    const server = buildServer()
    const standings = await server.inject(`/v1/standings?date=${CONTRACT_DATE}`)
    const teams = await server.inject(`/v1/teams/standings?date=${CONTRACT_DATE}`)

    expect(standings.statusCode).toBe(200)
    expect(standingsResponseSchema.parse(responseJson(standings.body))).toEqual({
      date: CONTRACT_DATE,
      standings: [{
        teamId: 'LG',
        teamName: 'LG',
        wins: 41,
        losses: 28,
        draws: 2,
        rank: 1,
        streak: '2승',
        winRate: '0.594',
        recentTen: '6승0무4패',
        gamesBack: '0.0'
      }]
    })
    expect(standingsResponseSchema.parse(responseJson(teams.body))).toEqual(
      standingsResponseSchema.parse(responseJson(standings.body))
    )
    await server.close()
  })

  it('freezes the v1 player search and season response contracts', async () => {
    process.env.BASEBALL_LIVE_KR_DB_ENABLED = '1'
    const dir = mkdtempSync(join(tmpdir(), 'baseball-live-kr-contract-players-'))
    tempDirs.push(dir)
    process.env.BASEBALL_LIVE_KR_DB_PATH = join(dir, 'contract.sqlite')
    upsertBattingSeasonRecords(PLAYER_CONTRACT_DATE, [{
      playerId: '66606', playerName: 'CHOI Won Jun', teamId: 'KT', teamName: 'KT',
      rank: 1, games: 65, plateAppearances: 312, atBats: 265,
      runs: 59, hits: 101, doubles: 20, triples: 2, homeRuns: 5, totalBases: 140, rbi: 37,
      stolenBases: 15, caughtStealing: 6, sacrificeHits: 3, sacrificeFlies: 3,
      avg: 0.381
    }])
    upsertPitchingSeasonRecords(PLAYER_CONTRACT_DATE, [{
      playerId: '55633', playerName: 'OLLER Adam', teamId: 'HT', teamName: 'KIA',
      rank: 1, games: 14, completeGames: 1, shutouts: 1,
      wins: 7, losses: 5, saves: 0, holds: 0, winningPercentage: 0.583,
      plateAppearances: 344, pitches: 1314, inningsPitchedOuts: 262,
      hitsAllowed: 56, doublesAllowed: 6, triplesAllowed: 2, homeRunsAllowed: 6,
      era: 2.58, walks: 27, strikeouts: 92, earnedRuns: 25, whip: 0.95,
      strikeoutsPerNine: 9.48, walksPerNine: 2.78, strikeoutWalkRatio: 3.41,
      opponentObp: 0.260, opponentSlg: 0.275,
      opponentOps: 0.535
    }])

    const server = buildServer()
    const search = await server.inject('/v1/players/search?q=won&season=2026')
    const batterSeason = await server.inject('/v1/players/66606/season?season=2026&date=20260618')
    const pitcherSeason = await server.inject('/v1/players/55633/season?season=2026&date=20260618')
    const missingSeason = await server.inject('/v1/players/99999/season?season=2026&date=20260618')

    expect(search.statusCode).toBe(200)
    expect(playerSearchResponseSchema.parse(responseJson(search.body))).toEqual({
      players: [{
        playerId: '66606',
        playerName: 'CHOI Won Jun',
        teamId: 'KT',
        season: 2026,
        positionGroup: 'batter'
      }]
    })
    expect(playerSeasonResponseSchema.parse(responseJson(batterSeason.body))).toMatchObject({
      player: {
        playerId: '66606',
        playerName: 'CHOI Won Jun',
        season: 2026,
        teamId: 'KT',
        batting: { hits: 101, avg: 0.381 },
        pitching: null
      }
    })
    expect(playerSeasonResponseSchema.parse(responseJson(pitcherSeason.body))).toMatchObject({
      player: {
        playerId: '55633',
        playerName: 'OLLER Adam',
        season: 2026,
        teamId: 'HT',
        batting: null,
        pitching: {
          era: 2.58,
          strikeouts_per_nine: 9.48,
          walks_per_nine: 2.78,
          strikeout_walk_ratio: 3.41,
          opponent_obp: 0.260,
          opponent_slg: 0.275,
          opponent_ops: 0.535
        }
      }
    })
    expect(playerSeasonResponseSchema.parse(responseJson(missingSeason.body))).toEqual({ player: null })
    await server.close()
  })
})
