import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('../src/clients/kboClient.js', () => ({
  fetchKboGameDate: vi.fn(),
  fetchKboGameList: vi.fn(),
  fetchKboLiveTextView: vi.fn(),
  fetchKboScheduleList: vi.fn(),
  fetchKboTeamRankDailyPage: vi.fn()
}))

import { getGameById, getTodayGames, getTodayGamesRaw } from '../src/services/gameService.js'
import {
  cleanupGameServiceTestState,
  resetGameServiceTestState,
  TEST_DATE,
  TEST_INPUT_DATE
} from './gameServiceTestSupport.js'

describe('gameService misc flows', () => {
  const tempDirs: string[] = []

  beforeEach(() => {
    resetGameServiceTestState()
  })

  afterEach(() => {
    cleanupGameServiceTestState(tempDirs)
  })

  it('returns a single live fixture game when test live mode is enabled', async () => {
    process.env.KBO_USE_TEST_LIVE_GAME = '1'

    const result = await getTodayGames(TEST_INPUT_DATE)

    expect(result.date).toBe(TEST_DATE)
    expect(result.games).toHaveLength(1)
    expect(result.games[0]).toMatchObject({
      gameId: `${TEST_DATE}LTHH0`,
      status: 'live',
      score: { away: 12, home: 9 },
      inning: { number: 7, half: 'bottom' }
    })
  })

  it('returns null game detail when the requested game is missing', async () => {
    const result = await getGameById('missing', TEST_INPUT_DATE)

    expect(result).toEqual({
      date: TEST_DATE,
      game: null
    })
  })

  it('includes raw and normalized payloads for debug source output', async () => {
    const result = await getTodayGamesRaw(TEST_INPUT_DATE)

    expect(result.requestedDate).toBe(TEST_DATE)
    expect(result.gameList.game).toHaveLength(1)
    expect(result.scheduleGames).toHaveLength(1)
    expect(result.normalizedGames[0].venue).toBe('잠실')
  })
})
