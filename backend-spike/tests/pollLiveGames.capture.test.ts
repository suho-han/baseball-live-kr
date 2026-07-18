import { mkdtemp, readFile, readdir, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import path from 'node:path'
import { describe, expect, it } from 'vitest'
import { z } from 'zod'

import { runPollingTick } from '../scripts/poll-live-games.js'
import type { RawKboGameListResponse } from '../src/dto/kboGameList.dto.js'
import type { RawKboScheduleListResponse } from '../src/dto/kboScheduleList.dto.js'

const rawChangeCaptureSchema = z.object({
  fetchedAt: z.string(),
  date: z.string(),
  gameList: z.object({
    game: z.array(z.object({
      G_ID: z.string(),
      GAME_STATE_SC: z.string()
    }).passthrough())
  }).passthrough(),
  scheduleList: z.object({
    rows: z.array(z.unknown())
  }).passthrough()
}).passthrough()

describe('poll live games raw capture', () => {
  it('writes raw change snapshots when saveRaw and captureOnChange are enabled', async () => {
    const rootDir = await mkdtemp(path.join(tmpdir(), 'poll-live-games-'))
    const logsDir = path.join(rootDir, 'logs')
    const fixturesDir = path.join(rootDir, 'fixtures')
    const fetchedAt = new Date('2026-06-16T09:25:06.775Z')
    const rawGameList: RawKboGameListResponse = {
      game: [{
        G_ID: '20260616KTOB0',
        G_DT: '20260616',
        G_TM: '18:30',
        S_NM: '잠실',
        AWAY_ID: 'KT',
        HOME_ID: 'OB',
        AWAY_NM: 'KT',
        HOME_NM: '두산',
        GAME_STATE_SC: '1',
        GAME_INN_NO: '1',
        GAME_TB_SC: 'T',
        T_SCORE_CN: '0',
        B_SCORE_CN: '0',
        BALL_CN: '0',
        STRIKE_CN: '0',
        OUT_CN: '0',
        B1_BAT_ORDER_NO: '',
        B2_BAT_ORDER_NO: '',
        B3_BAT_ORDER_NO: '',
        T_P_NM: '최원준',
        B_P_NM: '최승용'
      }]
    }
    const scheduleList: RawKboScheduleListResponse = { rows: [] }

    try {
      await runPollingTick({
        captureOnChange: true,
        date: '20260616',
        fetchedAt,
        fixturesDir,
        logsDir,
        previousGames: [],
        rawGameList,
        saveRaw: true,
        saveSnapshots: true,
        scheduleList,
        writeStdout: false
      })

      const changeFiles = (await readdir(path.join(fixturesDir, 'changes'))).sort()
      expect(changeFiles).toEqual([
        '2026-06-16T09-25-06-775Z.json',
        '2026-06-16T09-25-06-775Z.raw.json'
      ])

      const rawText = await readFile(path.join(fixturesDir, 'changes', '2026-06-16T09-25-06-775Z.raw.json'), 'utf8')
      const rawJson: unknown = JSON.parse(rawText)
      const rawCapture = rawChangeCaptureSchema.parse(rawJson)

      expect(rawCapture.date).toBe('20260616')
      expect(rawCapture.gameList.game.map((game) => game.G_ID)).toEqual(['20260616KTOB0'])
      expect(rawCapture.gameList.game.map((game) => game.GAME_STATE_SC)).toEqual(['1'])
      expect(rawCapture.scheduleList.rows).toEqual([])
    } finally {
      await rm(rootDir, { force: true, recursive: true })
    }
  })
})
