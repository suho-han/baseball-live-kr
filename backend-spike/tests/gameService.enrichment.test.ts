import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('../src/clients/kboClient.js', () => ({
  fetchKboGameDate: vi.fn(),
  fetchKboGameList: vi.fn(),
  fetchKboLiveTextView: vi.fn(),
  fetchKboScheduleList: vi.fn(),
  fetchKboTeamRankDailyPage: vi.fn()
}))

import { getTodayGames } from '../src/services/gameService.js'
import {
  buildStarterGameList,
  buildStarterScheduleList,
  cleanupGameServiceTestState,
  mockGameList,
  mockLiveTextView,
  mockScheduleList,
  resetGameServiceTestState,
  seedPitcherRecord,
  TEST_DATE,
  TEST_GAME_ID,
  TEST_INPUT_DATE,
  TEST_START_TIME
} from './gameServiceTestSupport.js'

describe('gameService enrichment', () => {
  const tempDirs: string[] = []

  beforeEach(() => {
    resetGameServiceTestState()
  })

  afterEach(() => {
    cleanupGameServiceTestState(tempDirs)
  })

  it('loads source endpoints in KBO date format and enriches games with schedule metadata', async () => {
    seedPitcherRecord(tempDirs, 'kbo-live-game-service-probable-')

    const result = await getTodayGames(TEST_INPUT_DATE)

    expect(result.date).toBe(TEST_DATE)
    expect(result.games).toHaveLength(1)
    expect(result.games[0].venue).toBe('잠실')
    expect(result.games[0].startTime).toBe(TEST_START_TIME)
    expect(result.games[0].broadcastChannels).toEqual(['SPO-2T'])
    expect(result.games[0].homepageLinks.review).toContain('section=REVIEW')
    expect(result.games[0].probablePitchers.away).toEqual({ name: null, record: null })
    expect(result.games[0].probablePitchers.home).toEqual({ name: null, record: null })
    expect(result.games[0].teamRecords?.away).toMatchObject({ wins: 24, losses: 39, draws: 1, rank: 10, streak: '2패' })
    expect(result.games[0].teamRecords?.home).toMatchObject({ wins: 41, losses: 24, draws: 0, rank: 1, streak: '2승' })
  })

  it('enriches probable starter records when the live source includes named starters', async () => {
    seedPitcherRecord(tempDirs, 'kbo-live-game-service-starters-', { teamId: 'HT', teamName: 'KIA' })
    mockGameList.mockResolvedValue(buildStarterGameList())
    mockScheduleList.mockResolvedValue(buildStarterScheduleList())

    const result = await getTodayGames(TEST_INPUT_DATE)

    expect(result.games[0].probablePitchers.away).toEqual({ name: '김건우', record: null })
    expect(result.games[0].probablePitchers.home).toEqual({
      name: '올러',
      record: { wins: 7, losses: 5, era: 2.58, whip: 0.95 }
    })
  })

  it('enriches requested-date live games with the previous at-bat result', async () => {
    mockGameList.mockResolvedValue({
      game: [{
        G_ID: '20260627HTOB0',
        G_DT: TEST_DATE,
        G_TM: '17:00',
        S_NM: '잠실',
        AWAY_ID: 'HT',
        HOME_ID: 'OB',
        AWAY_NM: 'KIA',
        HOME_NM: '두산',
        GAME_STATE_SC: '2',
        GAME_INN_NO: 3,
        GAME_TB_SC: 'B',
        T_SCORE_CN: 0,
        B_SCORE_CN: 0,
        BALL_CN: 2,
        STRIKE_CN: 2,
        OUT_CN: 0,
        T_P_NM: '시라카와',
        B_P_NM: '박찬호'
      }]
    })
    mockLiveTextView.mockResolvedValue(`
      <span class="normaiflTxt"> 9번타자 박찬호<br /></span>
      <span class="normaiflTxt"> 박찬호 : 3루수 땅볼 아웃 (3루수-&gt;1루수 송구아웃)<br /></span>
    `)

    const result = await getTodayGames(TEST_INPUT_DATE)

    expect(result.games.find((candidate) => candidate.gameId === '20260627HTOB0')).toMatchObject({
      recentPlay: '박찬호 : 3루수 땅볼 아웃 (3루수->1루수 송구아웃)',
      current: {
        batter: '박찬호',
        pitcher: '시라카와'
      }
    })
  })

  it('keeps games when schedule rows do not match a game id', async () => {
    mockScheduleList.mockResolvedValue({ rows: [] })

    const result = await getTodayGames(TEST_INPUT_DATE)

    expect(result.games).toHaveLength(1)
    expect(result.games[0].gameId).toBe(TEST_GAME_ID)
    expect(result.games[0].venue).toBeNull()
    expect(result.games[0].broadcastChannels).toEqual([])
  })
})
