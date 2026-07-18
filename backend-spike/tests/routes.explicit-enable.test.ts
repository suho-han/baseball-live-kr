import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import { getTodayGamesRaw } from '../src/services/gameService.js'
import { buildServer } from '../src/server.js'
import { backendVersion } from '../src/version.js'
import { TEST_DATE, TEST_INPUT_DATE } from './testConfig.js'

vi.mock('../src/services/gameService.js', () => ({
  getTodayGames: vi.fn(),
  getGameById: vi.fn(),
  getTeamStandings: vi.fn(),
  getTodayGamesRaw: vi.fn()
}))

const mockTodayGamesRaw = vi.mocked(getTodayGamesRaw)

describe('production route explicit enablement', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    const rawSourceFixture: Awaited<ReturnType<typeof getTodayGamesRaw>> = {
      requestedDate: TEST_DATE,
      gameDate: null,
      gameList: { game: [] },
      gameLists: [],
      scheduleList: { rows: [] },
      scheduleGames: [],
      normalizedGames: []
    }
    mockTodayGamesRaw.mockResolvedValue(rawSourceFixture)
  })

  afterEach(() => {
    delete process.env.BASEBALL_LIVE_KR_DEBUG_SOURCE_ENABLED
    delete process.env.BASEBALL_LIVE_KR_METRICS_ENABLED
    delete process.env.NODE_ENV
  })

  it('returns metrics in production when metrics are explicitly enabled', async () => {
    process.env.NODE_ENV = 'production'
    process.env.BASEBALL_LIVE_KR_METRICS_ENABLED = '1'
    const server = buildServer()

    try {
      const response = await server.inject('/metrics')

      expect(response.statusCode).toBe(200)
      expect(JSON.parse(response.body)).toMatchObject({
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
      })
    } finally {
      await server.close()
    }
  })

  it('returns debug source in production when debug source is explicitly enabled', async () => {
    process.env.NODE_ENV = 'production'
    process.env.BASEBALL_LIVE_KR_DEBUG_SOURCE_ENABLED = '1'
    const server = buildServer()

    try {
      const response = await server.inject(`/debug/source/today?date=${TEST_INPUT_DATE}`)

      expect(response.statusCode).toBe(200)
      expect(JSON.parse(response.body)).toMatchObject({
        requestedDate: TEST_DATE,
        normalizedGames: []
      })
      expect(mockTodayGamesRaw).toHaveBeenCalledWith(TEST_INPUT_DATE)
    } finally {
      await server.close()
    }
  })
})
