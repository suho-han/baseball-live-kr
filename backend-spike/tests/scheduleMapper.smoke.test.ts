import { describe, expect, it } from 'vitest'

import { mapGame, mapScheduledGame } from '../src/mappers/gameMapper.js'
import { mapScheduleGames } from '../src/mappers/scheduleMapper.js'

describe('schedule and game mapping smoke', () => {
  it('extracts game center metadata from KBO schedule rows', () => {
    const games = mapScheduleGames({
      rows: [{
        row: [
          { Text: '06.10(수)', Class: 'day' },
          { Text: '<b>18:30</b>', Class: 'time' },
          { Text: '<span>SSG</span><em><span>vs</span></em><span>LG</span>', Class: 'play' },
          { Text: "<a href='/Schedule/GameCenter/Main.aspx?gameDate=20260610&gameId=20260610SKLG0&section=START_PIT'>프리뷰</a>", Class: 'relay' },
          { Text: '', Class: null },
          { Text: 'SPO-2T', Class: null },
          { Text: '', Class: null },
          { Text: '잠실', Class: null },
          { Text: '-', Class: null }
        ]
      }]
    })
    expect(games[0]).toMatchObject({
      gameId: '20260610SKLG0',
      date: '20260610',
      startTime: '20260610T18:30:00+09:00',
      venue: '잠실',
      broadcastChannels: ['SPO-2T']
    })
  })

  it('recovers cancelled and future linkless schedule rows', () => {
    const cancelledGames = mapScheduleGames({
      rows: [
        {
          row: [
            { Text: '06.14(일)', Class: 'day' },
            { Text: '<b>14:00</b>', Class: 'time' },
            { Text: '<span>한화</span><em><span class="lose">2</span><span>vs</span><span class="win">3</span></em><span>키움</span>', Class: 'play' },
            { Text: "<a href='/Schedule/GameCenter/Main.aspx?gameDate=20260614&gameId=20260614HHWO0&section=REVIEW'>리뷰</a>", Class: 'relay' },
            { Text: '', Class: null },
            { Text: 'S-T', Class: null },
            { Text: '', Class: null },
            { Text: '고척', Class: null },
            { Text: '-', Class: null }
          ]
        },
        {
          row: [
            { Text: '<b>17:00</b>', Class: 'time' },
            { Text: '<span>NC</span><em><span>vs</span></em><span>KT</span>', Class: 'play' },
            { Text: '', Class: 'relay' },
            { Text: '', Class: null },
            { Text: 'SPO-T<br />SS-T', Class: null },
            { Text: '', Class: null },
            { Text: '수원', Class: null },
            { Text: '우천취소', Class: null }
          ]
        }
      ]
    })
    expect(cancelledGames.at(-1)).toMatchObject({
      gameId: '20260614NCKT0',
      statusHint: 'cancelled',
      note: '우천취소'
    })
    expect(mapScheduledGame(cancelledGames.at(-1)!)).toMatchObject({ status: 'cancelled' })

    const futureGames = mapScheduleGames({
      rows: [
        {
          row: [
            { Text: '07.07(화)', Class: 'day' },
            { Text: '<b>18:30</b>', Class: 'time' },
            { Text: '<span>SSG</span><em><span>vs</span></em><span>두산</span>', Class: 'play' },
            { Text: '', Class: 'relay' },
            { Text: '', Class: null },
            { Text: '', Class: null },
            { Text: '', Class: null },
            { Text: '잠실', Class: null },
            { Text: '-', Class: null }
          ]
        },
        {
          row: [
            { Text: '07.08(수)', Class: 'day' },
            { Text: '<b>18:30</b>', Class: 'time' },
            { Text: '<span>LG</span><em><span>vs</span></em><span>삼성</span>', Class: 'play' },
            { Text: '', Class: 'relay' },
            { Text: '', Class: null },
            { Text: '', Class: null },
            { Text: '', Class: null },
            { Text: '대구', Class: null },
            { Text: '-', Class: null }
          ]
        }
      ]
    }, '2026')
    expect(futureGames.map((game) => game.date)).toEqual(['20260707', '20260708'])
    expect(futureGames.map((game) => game.gameId)).toEqual(['20260707SKOB0', '20260708LGSS0'])
  })

  it('enriches mapped games and recent play fields', () => {
    const game = mapGame({
      G_ID: '20260610SKLG0',
      G_DT: '20260610',
      G_TM: null,
      S_NM: null,
      AWAY_ID: 'SK',
      HOME_ID: 'LG',
      AWAY_NM: 'SSG',
      HOME_NM: 'LG',
      GAME_STATE_SC: '1'
    }, {
      gameId: '20260610SKLG0',
      date: '20260610',
      awayTeam: { id: 'SK', name: 'SSG' },
      homeTeam: { id: 'LG', name: 'LG' },
      startTime: '20260610T18:30:00+09:00',
      venue: '잠실',
      broadcastChannels: ['SPO-2T'],
      note: null,
      statusHint: null,
      links: {
        gameCenter: 'https://www.koreabaseball.com/Schedule/GameCenter/Main.aspx?gameDate=20260610&gameId=20260610SKLG0&section=START_PIT',
        preview: 'https://www.koreabaseball.com/Schedule/GameCenter/Main.aspx?gameDate=20260610&gameId=20260610SKLG0&section=START_PIT',
        review: null,
        highlight: null
      }
    })
    expect(game.startTime).toBe('20260610T18:30:00+09:00')
    expect(game.venue).toBe('잠실')
    expect(game.broadcastChannels).toEqual(['SPO-2T'])
    expect(game.homepageLinks.preview).toContain('section=START_PIT')

    expect(mapGame({
      G_ID: '20260610SKLG0',
      G_DT: '20260610',
      G_TM: '18:30',
      AWAY_ID: 'SK',
      HOME_ID: 'LG',
      AWAY_NM: 'SSG',
      HOME_NM: 'LG',
      GAME_STATE_SC: '2',
      RECENT_PLAY_TEXT: '문보경 좌전 적시타'
    }).recentPlay).toBe('문보경 좌전 적시타')

    const liveGame = mapGame({
      G_ID: '20260610SKLG0',
      G_DT: '20260610',
      G_TM: '18:30',
      AWAY_ID: 'SK',
      HOME_ID: 'LG',
      AWAY_NM: 'SSG',
      HOME_NM: 'LG',
      GAME_STATE_SC: '2',
      GAME_INN_NO: 5,
      GAME_TB_SC: 'T',
      BALL_CN: 1,
      STRIKE_CN: 2,
      OUT_CN: 1,
      B1_BAT_ORDER_NO: 4,
      B2_BAT_ORDER_NO: 0,
      B3_BAT_ORDER_NO: 7,
      T_P_NM: ' 최정 ',
      B_P_NM: ' 임찬규 '
    })
    expect(liveGame.current).toEqual({ batter: '최정', pitcher: '임찬규' })
    expect(liveGame.recentPlay).toBeNull()

    expect(mapGame({
      G_ID: '20260610SKLG0',
      G_DT: '20260610',
      G_TM: '18:30',
      AWAY_ID: 'SK',
      HOME_ID: 'LG',
      AWAY_NM: 'SSG',
      HOME_NM: 'LG',
      GAME_STATE_SC: '3',
      GAME_INN_NO: 9,
      GAME_TB_SC: 'B',
      T_P_NM: '오지환',
      B_P_NM: '김광현'
    }).recentPlay).toBeNull()
  })
})
