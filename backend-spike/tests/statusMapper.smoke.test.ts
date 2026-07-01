import { describe, expect, it } from 'vitest'

import { mapBases } from '../src/mappers/baseMapper.js'
import { mapStatus } from '../src/mappers/statusMapper.js'
import { summarizeGameChanges } from '../src/utils/gameSnapshot.js'
import { toKboDate } from '../src/utils/date.js'
import type { NormalizedGame } from '../src/models/normalizedGame.js'
import { TEST_KOREA_ROLLOVER_INSTANT, TEST_NEXT_DATE } from './testConfig.js'

describe('status and date smoke', () => {
  it('maps bases from occupied runners', () => {
    expect(mapBases({ B1_BAT_ORDER_NO: 1, B2_BAT_ORDER_NO: null, B3_BAT_ORDER_NO: 9 } as never)).toEqual({
      first: true,
      second: false,
      third: true
    })
  })

  it('maps scheduled, live, cancelled, delayed, and final status cases', () => {
    expect(mapStatus({ GAME_STATE_SC: '1', GAME_INN_NO: null } as never)).toBe('scheduled')
    expect(mapStatus({
      GAME_STATE_SC: '1',
      GAME_INN_NO: '',
      GAME_TB_SC: '',
      T_SCORE_CN: '',
      B_SCORE_CN: '',
      BALL_CN: '',
      STRIKE_CN: '   ',
      OUT_CN: ''
    } as never)).toBe('scheduled')
    expect(mapStatus({
      G_DT: '20260618',
      G_TM: '18:30',
      GAME_STATE_SC: '1',
      GAME_INN_NO: 1,
      GAME_TB_SC: 'T',
      T_SCORE_CN: '0',
      B_SCORE_CN: '0',
      BALL_CN: 0,
      STRIKE_CN: 0,
      OUT_CN: 0
    } as never, { now: new Date('2026-06-18T08:34:55Z') })).toBe('scheduled')
    expect(mapStatus({
      G_DT: '20260618',
      G_TM: '18:30',
      GAME_STATE_SC: '1',
      GAME_INN_NO: null,
      GAME_TB_SC: 'T',
      T_SCORE_CN: 1,
      B_SCORE_CN: 0,
      BALL_CN: 0,
      STRIKE_CN: 0,
      OUT_CN: 0
    } as never, { now: new Date('2026-06-18T09:30:00Z') })).toBe('live')
    expect(mapStatus({ GAME_STATE_SC: '5' } as never)).toBe('cancelled')
    expect(mapStatus({ GAME_STATE_SC: '6' } as never)).toBe('delayed')
    expect(mapStatus({ GAME_STATE_SC: '7' } as never)).toBe('delayed')
    expect(mapStatus({
      GAME_STATE_SC: '4',
      GAME_INN_NO: 0,
      T_SCORE_CN: '0',
      B_SCORE_CN: '0',
      CANCEL_SC_ID: '1',
      CANCEL_SC_NM: '우천취소'
    } as never)).toBe('cancelled')
    expect(mapStatus({ GAME_STATE_SC: '4', CANCEL_SC_ID: 0, CANCEL_SC_NM: '' } as never)).toBe('final')
    expect(mapStatus({ GAME_STATE_SC: '3', CANCEL_SC_ID: 0, CANCEL_SC_NM: '정상경기' } as never)).toBe('final')
  })

  it('summarizes meaningful live changes between polling ticks', () => {
    const previous = [buildGame({ score: { away: 1, home: 0 }, inning: { number: 3, half: 'top' }, count: { balls: 1, strikes: 1, outs: 1 } })]
    const current = [buildGame({ score: { away: 2, home: 0 }, inning: { number: 3, half: 'top' }, count: { balls: 0, strikes: 0, outs: 2 } })]
    expect(summarizeGameChanges(previous, current)).toEqual([{
      gameId: '20260610SKLG0',
      matchup: 'SSG @ LG',
      changes: [
        'score SSG 1:0 LG -> SSG 2:0 LG',
        'count {"balls":1,"strikes":1,"outs":1} -> {"balls":0,"strikes":0,"outs":2}'
      ]
    }])
  })

  it('normalizes requested dates into KBO date format', () => {
    expect(toKboDate('2026-06-01')).toBe('20260601')
    expect(toKboDate('20260601')).toBe('20260601')
    expect(toKboDate(undefined, TEST_KOREA_ROLLOVER_INSTANT)).toBe(TEST_NEXT_DATE)
  })
})

function buildGame(overrides: Partial<NormalizedGame> = {}): NormalizedGame {
  return {
    gameId: '20260610SKLG0',
    date: '20260610',
    venue: '잠실',
    startTime: '2026-06-10T18:30:00+09:00',
    broadcastChannels: [],
    homepageLinks: { gameCenter: null, preview: null, review: null, highlight: null },
    pitcherDecisions: { win: null, loss: null, save: null },
    status: 'live',
    starterStatus: 'ready',
    awayTeam: { id: 'SK', name: 'SSG' },
    homeTeam: { id: 'LG', name: 'LG' },
    score: { away: 0, home: 0 },
    inning: { number: 1, half: 'top' },
    count: { balls: 0, strikes: 0, outs: 0 },
    bases: { first: false, second: false, third: false },
    current: { batter: null, pitcher: null },
    probablePitchers: {
      away: { name: null, record: null },
      home: { name: null, record: null }
    },
    recentPlay: null,
    teamRecords: null,
    boxScore: null,
    lineupPreview: null,
    analysis: null,
    sourceMeta: {
      rawStatusCode: '1',
      rawTopBottomCode: 'T',
      fetchedAt: '2026-06-10T09:00:00.000Z'
    },
    ...overrides
  }
}
