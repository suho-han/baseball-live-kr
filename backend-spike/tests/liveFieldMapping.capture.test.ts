import { existsSync, readFileSync, readdirSync } from 'node:fs'
import path from 'node:path'
import { describe, expect, it } from 'vitest'
import { z } from 'zod'

import { rawKboGameListResponseSchema, type RawKboGame } from '../src/dto/kboGameList.dto.js'

const pollingGameSchema = z.object({
  gameId: z.string(),
  matchup: z.string(),
  status: z.string(),
  score: z.object({
    away: z.number(),
    home: z.number()
  }),
  inning: z.object({
    number: z.number(),
    half: z.enum(['top', 'bottom'])
  }).nullable(),
  count: z.object({
    balls: z.number(),
    strikes: z.number(),
    outs: z.number()
  }).nullable(),
  bases: z.object({
    first: z.boolean(),
    second: z.boolean(),
    third: z.boolean()
  }).nullable(),
  current: z.object({
    batter: z.string().nullable(),
    pitcher: z.string().nullable()
  }).nullable(),
  recentPlay: z.string().nullable()
})

const pollingSnapshotSchema = z.object({
  fetchedAt: z.string(),
  date: z.string(),
  gameCount: z.number(),
  changedGames: z.number(),
  changes: z.array(z.object({
    gameId: z.string(),
    matchup: z.string(),
    changes: z.array(z.string())
  })),
  games: z.array(pollingGameSchema)
})

const rawCaptureSchema = z.object({
  fetchedAt: z.string(),
  date: z.string(),
  gameList: rawKboGameListResponseSchema
}).passthrough()

type PollingGame = z.infer<typeof pollingGameSchema>

const fixtureRoot = path.resolve('fixtures/live-20260616')

function readFixture<T>(relativePath: string, schema: z.ZodType<T>): T {
  const parsed: unknown = JSON.parse(readFileSync(path.join(fixtureRoot, relativePath), 'utf8'))
  return schema.parse(parsed)
}

function toNumber(value: string | number | null | undefined): number {
  const numberValue = Number(value ?? 0)

  if (!Number.isFinite(numberValue)) {
    throw new Error(`Expected numeric KBO value, received ${String(value)}`)
  }

  return numberValue
}

function trimToNull(value: string | null | undefined): string | null {
  const trimmed = value?.trim()
  return trimmed ? trimmed : null
}

function expectedHalf(raw: RawKboGame): 'top' | 'bottom' {
  switch (raw.GAME_TB_SC) {
    case 'T':
      return 'top'
    case 'B':
      return 'bottom'
    default:
      throw new Error(`Expected KBO top/bottom code, received ${String(raw.GAME_TB_SC)}`)
  }
}

function occupied(value: string | number | null | undefined): boolean {
  return toNumber(value) > 0
}

function expectedCurrent(raw: RawKboGame): NonNullable<PollingGame['current']> {
  if (expectedHalf(raw) === 'bottom') {
    return {
      batter: trimToNull(raw.B_P_NM),
      pitcher: trimToNull(raw.T_P_NM)
    }
  }

  return {
    batter: trimToNull(raw.T_P_NM),
    pitcher: trimToNull(raw.B_P_NM)
  }
}

function expectedRecentPlay(raw: RawKboGame): string | null {
  const candidateFields = [
    'RECENT_PLAY_TEXT',
    'RECENT_PLAY',
    'LAST_PLAY_TEXT',
    'LAST_PLAY',
    'LIVE_TEXT',
    'GAME_TEXT'
  ] as const

  for (const field of candidateFields) {
    const value = trimToNull(raw[field])

    if (value !== null) {
      return value
    }
  }

  return null
}

function byGameId(games: readonly PollingGame[]): Map<string, PollingGame> {
  return new Map(games.map((game) => [game.gameId, game]))
}

function requirePollingGame(games: Map<string, PollingGame>, gameId: string): PollingGame {
  const game = games.get(gameId)

  if (game === undefined) {
    throw new Error(`Missing normalized polling game for ${gameId}`)
  }

  return game
}

function expectedLiveOnlyFields(raw: RawKboGame, status: string): Pick<PollingGame, 'inning' | 'count' | 'bases' | 'current'> {
  if (status !== 'live') {
    return {
      inning: null,
      count: null,
      bases: null,
      current: null
    }
  }

  return {
    inning: {
      number: toNumber(raw.GAME_INN_NO),
      half: expectedHalf(raw)
    },
    count: {
      balls: toNumber(raw.BALL_CN),
      strikes: toNumber(raw.STRIKE_CN),
      outs: toNumber(raw.OUT_CN)
    },
    bases: {
      first: occupied(raw.B1_BAT_ORDER_NO),
      second: occupied(raw.B2_BAT_ORDER_NO),
      third: occupied(raw.B3_BAT_ORDER_NO)
    },
    current: expectedCurrent(raw)
  }
}

describe('live capture field mapping fixtures', () => {
  it('compares final latest committed official raw fields to normalized polling output', () => {
    const rawCapture = readFixture('latest-raw.json', rawCaptureSchema)
    const normalizedCapture = readFixture('latest-normalized.json', pollingSnapshotSchema)
    const normalizedById = byGameId(normalizedCapture.games)

    expect(rawCapture.date).toBe('20260616')
    expect(normalizedCapture.date).toBe(rawCapture.date)
    expect(rawCapture.gameList.game).toHaveLength(5)
    expect(normalizedCapture.gameCount).toBe(rawCapture.gameList.game.length)

    for (const raw of rawCapture.gameList.game) {
      const normalized = requirePollingGame(normalizedById, raw.G_ID)
      const liveOnlyFields = expectedLiveOnlyFields(raw, normalized.status)

      expect(raw.GAME_STATE_SC).toBe('3')
      expect(normalized).toEqual({
        gameId: raw.G_ID,
        matchup: `${raw.AWAY_NM ?? ''} @ ${raw.HOME_NM ?? ''}`,
        status: 'final',
        score: {
          away: toNumber(raw.T_SCORE_CN),
          home: toNumber(raw.B_SCORE_CN)
        },
        inning: liveOnlyFields.inning,
        count: liveOnlyFields.count,
        bases: liveOnlyFields.bases,
        current: liveOnlyFields.current,
        recentPlay: expectedRecentPlay(raw)
      })
    }
  })

  it('replays the initial normalized live snapshot as legacy normalized-only evidence', () => {
    const normalizedChangePath = 'changes/2026-06-16T09-25-06-775Z.json'
    const initialCapture = readFixture(normalizedChangePath, pollingSnapshotSchema)
    const rawChangeFiles = readdirSync(path.join(fixtureRoot, 'changes')).filter((file) => file.endsWith('.raw.json'))

    expect(initialCapture.date).toBe('20260616')
    expect(initialCapture.changedGames).toBe(5)
    expect(existsSync(path.join(fixtureRoot, normalizedChangePath.replace(/\.json$/, '.raw.json')))).toBe(false)
    expect(rawChangeFiles).toEqual([])
    expect(initialCapture.games).toEqual([
      {
        gameId: '20260616KTOB0',
        matchup: 'KT @ 두산',
        status: 'live',
        score: { away: 0, home: 0 },
        inning: { number: 1, half: 'top' },
        count: { balls: 0, strikes: 0, outs: 0 },
        bases: { first: false, second: false, third: false },
        current: { batter: '최원준', pitcher: '최승용' },
        recentPlay: '1회초 최원준 타석, 투수 최승용, 카운트 0-0, 0아웃, 주자 없음'
      },
      {
        gameId: '20260616WOSS0',
        matchup: '키움 @ 삼성',
        status: 'live',
        score: { away: 0, home: 0 },
        inning: { number: 1, half: 'top' },
        count: { balls: 0, strikes: 0, outs: 0 },
        bases: { first: false, second: false, third: false },
        current: { batter: '서건창', pitcher: '원태인' },
        recentPlay: '1회초 서건창 타석, 투수 원태인, 카운트 0-0, 0아웃, 주자 없음'
      },
      {
        gameId: '20260616LTSK0',
        matchup: '롯데 @ SSG',
        status: 'live',
        score: { away: 0, home: 0 },
        inning: { number: 1, half: 'top' },
        count: { balls: 0, strikes: 0, outs: 0 },
        bases: { first: false, second: false, third: false },
        current: { batter: '황성빈', pitcher: '김민준' },
        recentPlay: '1회초 황성빈 타석, 투수 김민준, 카운트 0-0, 0아웃, 주자 없음'
      },
      {
        gameId: '20260616LGHT0',
        matchup: 'LG @ KIA',
        status: 'live',
        score: { away: 0, home: 0 },
        inning: { number: 1, half: 'top' },
        count: { balls: 0, strikes: 0, outs: 0 },
        bases: { first: false, second: false, third: false },
        current: { batter: '홍창기', pitcher: '시라카와' },
        recentPlay: '1회초 홍창기 타석, 투수 시라카와, 카운트 0-0, 0아웃, 주자 없음'
      },
      {
        gameId: '20260616HHNC0',
        matchup: '한화 @ NC',
        status: 'live',
        score: { away: 0, home: 0 },
        inning: { number: 1, half: 'top' },
        count: { balls: 0, strikes: 0, outs: 0 },
        bases: { first: false, second: false, third: false },
        current: { batter: '오재원', pitcher: '구창모' },
        recentPlay: '1회초 오재원 타석, 투수 구창모, 카운트 0-0, 0아웃, 주자 없음'
      }
    ])
  })
})
