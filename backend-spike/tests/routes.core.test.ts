import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import { getGameById, getTeamStandings, getTodayGames, getTodayGamesRaw } from '../src/services/gameService.js'
import { KboDateInputError } from '../src/utils/date.js'
import { buildServer } from '../src/server.js'
import { backendVersion } from '../src/version.js'
import { TEST_DATE, TEST_GAME_ID, TEST_INPUT_DATE } from './testConfig.js'

vi.mock('../src/services/gameService.js', () => ({
  getTodayGames: vi.fn(),
  getGameById: vi.fn(),
  getTeamStandings: vi.fn(),
  getTodayGamesRaw: vi.fn()
}))

const mockTodayGames = vi.mocked(getTodayGames)
const mockGameById = vi.mocked(getGameById)
const mockTeamStandings = vi.mocked(getTeamStandings)
const mockTodayGamesRaw = vi.mocked(getTodayGamesRaw)

describe('games routes core', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockTodayGames.mockResolvedValue({ date: TEST_DATE, games: [] })
    mockGameById.mockResolvedValue({ date: TEST_DATE, game: null })
    mockTeamStandings.mockResolvedValue({ date: TEST_DATE, standings: [] })
    mockTodayGamesRaw.mockResolvedValue({
      requestedDate: TEST_DATE,
      gameDate: {},
      gameList: { game: [] },
      scheduleList: { rows: [] },
      scheduleGames: [],
      normalizedGames: []
    } as never)
  })

  afterEach(async () => {
    delete process.env.BASEBALL_LIVE_KR_DB_ENABLED
    delete process.env.BASEBALL_LIVE_KR_DB_PATH
    delete process.env.BASEBALL_LIVE_KR_DEBUG_SOURCE_ENABLED
    delete process.env.KBO_SOURCE_TIMEOUT_MS
    delete process.env.NODE_ENV
  })

  it('returns today games through Fastify injection', async () => {
    const server = buildServer()
    const response = await server.inject(`/games/today?date=${TEST_INPUT_DATE}`)
    expect(response.statusCode).toBe(200)
    expect(JSON.parse(response.body)).toEqual({ date: TEST_DATE, games: [] })
    expect(mockTodayGames).toHaveBeenCalledWith(TEST_INPUT_DATE)
    await server.close()
  })

  it('returns today games through the v1 route', async () => {
    mockTodayGames.mockResolvedValue({
      date: TEST_DATE,
      games: [{
        gameId: TEST_GAME_ID,
        date: TEST_DATE,
        venue: '광주',
        startTime: '2026-06-30T18:30:00+09:00',
        broadcastChannels: ['MS-T'],
        homepageLinks: { gameCenter: null, preview: null, review: null, highlight: null },
        pitcherDecisions: { win: null, loss: null, save: null },
        status: 'scheduled',
        awayTeam: { id: 'SK', name: 'SSG' },
        homeTeam: { id: 'HT', name: 'KIA' },
        score: { away: 0, home: 0 },
        inning: null,
        count: null,
        bases: null,
        current: null,
        probablePitchers: {
          away: { name: '김건우', record: { wins: 3, losses: 2, era: 3.12, whip: 1.11 } },
          home: { name: '올러', record: null }
        },
        recentPlay: null,
        teamRecords: null,
        boxScore: null,
        lineupPreview: null,
        analysis: null,
        sourceMeta: {
          rawStatusCode: null,
          rawTopBottomCode: null,
          fetchedAt: '2026-06-29T00:00:00.000Z'
        }
      }]
    } as never)
    const server = buildServer()
    const response = await server.inject(`/v1/games/today?date=${TEST_INPUT_DATE}`)
    expect(response.statusCode).toBe(200)
    expect(JSON.parse(response.body)).toMatchObject({
      date: TEST_DATE,
      games: [{
        probablePitchers: {
          away: { name: '김건우', record: { wins: 3, losses: 2, era: 3.12, whip: 1.11 } },
          home: { name: '올러', record: null }
        }
      }]
    })
    expect(mockTodayGames).toHaveBeenCalledWith(TEST_INPUT_DATE)
    await server.close()
  })

  it('returns game detail routes', async () => {
    const server = buildServer()
    const response = await server.inject(`/games/${TEST_GAME_ID}?date=${TEST_INPUT_DATE}`)
    const v1Response = await server.inject(`/v1/games/${TEST_GAME_ID}?date=${TEST_INPUT_DATE}`)
    expect(response.statusCode).toBe(200)
    expect(v1Response.statusCode).toBe(200)
    expect(mockGameById).toHaveBeenCalledWith(TEST_GAME_ID, TEST_INPUT_DATE)
    await server.close()
  })

  it('returns team standings routes', async () => {
    const server = buildServer()
    const standings = await server.inject(`/v1/standings?date=${TEST_INPUT_DATE}`)
    const teams = await server.inject(`/v1/teams/standings?date=${TEST_INPUT_DATE}`)
    expect(standings.statusCode).toBe(200)
    expect(teams.statusCode).toBe(200)
    expect(mockTeamStandings).toHaveBeenCalledWith(TEST_INPUT_DATE)
    await server.close()
  })

  it('returns health and readiness payloads through v1 operational routes', async () => {
    const server = buildServer()
    const health = await server.inject('/v1/health')
    const readiness = await server.inject('/v1/ready')
    expect(JSON.parse(health.body)).toMatchObject({
      ok: true,
      source: 'kbo-official-spike',
      version: backendVersion
    })
    expect(JSON.parse(readiness.body)).toMatchObject({
      ok: true,
      source: 'kbo-official-spike',
      version: backendVersion,
      checks: {
        config: {
          ok: true,
          errors: []
        }
      }
    })
    await server.close()
  })

  it('returns metrics payloads through operational routes', async () => {
    const server = buildServer()

    const metrics = await server.inject('/metrics')
    const v1Metrics = await server.inject('/v1/metrics')

    expect(metrics.statusCode).toBe(200)
    expect(v1Metrics.statusCode).toBe(200)
    const expectedShape = {
      service: 'baseball-live-kr-backend-spike',
      version: backendVersion,
      counters: {
        requests: {
          total: expect.any(Number)
        },
        source: {
          success: expect.any(Number),
          failure: expect.any(Number)
        },
        cache: {
          hit: expect.any(Number),
          miss: expect.any(Number),
          stale: expect.any(Number)
        },
        alerts: {
          recorded: expect.any(Number),
          sent: expect.any(Number),
          suppressed: expect.any(Number)
        }
      },
      process: {
        nodeVersion: process.version,
        pid: process.pid,
        uptimeSeconds: expect.any(Number)
      }
    }
    expect(JSON.parse(metrics.body)).toMatchObject(expectedShape)
    expect(JSON.parse(v1Metrics.body)).toMatchObject(expectedShape)
    await server.close()
  })

  it('denies metrics in production without explicit enablement', async () => {
    process.env.NODE_ENV = 'production'
    const server = buildServer()

    const response = await server.inject('/metrics')

    expect(response.statusCode).toBe(404)
    expect(JSON.parse(response.body)).toMatchObject({
      error: {
        code: 'NOT_FOUND',
        message: 'Not found',
        statusCode: 404
      }
    })
    await server.close()
  })

  it('returns not ready when runtime config is invalid', async () => {
    process.env.KBO_SOURCE_TIMEOUT_MS = 'not-a-timeout'
    const server = buildServer()

    const readiness = await server.inject('/v1/ready')

    expect(readiness.statusCode).toBe(503)
    expect(JSON.parse(readiness.body)).toMatchObject({
      ok: false,
      source: 'kbo-official-spike',
      version: backendVersion,
      checks: {
        config: {
          ok: false,
          errors: [{
            key: 'KBO_SOURCE_TIMEOUT_MS',
            message: 'must be a non-negative integer'
          }]
        }
      }
    })
    await server.close()
  })

  it('returns debug source payloads', async () => {
    const server = buildServer()
    const response = await server.inject(`/debug/source/today?date=${TEST_INPUT_DATE}`)
    expect(response.statusCode).toBe(200)
    expect(JSON.parse(response.body).requestedDate).toBe(TEST_DATE)
    expect(mockTodayGamesRaw).toHaveBeenCalledWith(TEST_INPUT_DATE)
    await server.close()
  })

  it('denies debug source payloads in production without explicit enablement', async () => {
    process.env.NODE_ENV = 'production'
    const server = buildServer()

    const response = await server.inject(`/debug/source/today?date=${TEST_INPUT_DATE}`)

    expect(response.statusCode).toBe(404)
    expect(JSON.parse(response.body)).toMatchObject({
      error: {
        code: 'NOT_FOUND',
        message: 'Not found',
        statusCode: 404
      }
    })
    expect(mockTodayGamesRaw).not.toHaveBeenCalled()
    await server.close()
  })

  it('maps invalid and unexpected errors to normalized responses', async () => {
    mockTodayGames.mockRejectedValueOnce(new KboDateInputError('2026'))
    const server = buildServer()
    const invalid = await server.inject('/games/today?date=2026')
    mockTodayGames.mockRejectedValueOnce(new Error('source unavailable'))
    const unexpected = await server.inject('/games/today')
    expect(invalid.statusCode).toBe(400)
    expect(unexpected.statusCode).toBe(500)
    expect(JSON.parse(unexpected.body)).toEqual({
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Internal server error',
        statusCode: 500
      }
    })
    await server.close()
  })
})
