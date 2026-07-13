import { randomUUID } from 'node:crypto'
import type { DatabaseSync } from 'node:sqlite'
import { z } from 'zod'

import { getDatabase, isDatabaseDisabled } from '../db/database.js'
import type { NormalizedGame } from '../models/normalizedGame.js'

const teamSchema = z.object({
  id: z.string(),
  name: z.string()
})

const pitcherRecordSchema = z.object({
  wins: z.number().nullable(),
  losses: z.number().nullable(),
  era: z.number().nullable(),
  whip: z.number().nullable()
})

const probablePitcherSchema = z.object({
  name: z.string().nullable(),
  record: pitcherRecordSchema.nullable()
})

const teamRecordSchema = z.object({
  wins: z.number(),
  losses: z.number(),
  draws: z.number(),
  rank: z.number().nullable(),
  streak: z.string().nullable()
})

const boxScoreTeamSchema = z.object({
  runs: z.number(),
  hits: z.number().nullable(),
  errors: z.number().nullable(),
  walks: z.number().nullable()
})

const normalizedGameSchema: z.ZodType<NormalizedGame> = z.object({
  gameId: z.string(),
  date: z.string(),
  venue: z.string().nullable(),
  startTime: z.string().nullable(),
  broadcastChannels: z.array(z.string()),
  homepageLinks: z.object({
    gameCenter: z.string().nullable(),
    preview: z.string().nullable(),
    review: z.string().nullable(),
    highlight: z.string().nullable()
  }),
  pitcherDecisions: z.object({
    win: z.string().nullable(),
    loss: z.string().nullable(),
    save: z.string().nullable()
  }),
  status: z.enum(['scheduled', 'live', 'final', 'delayed', 'cancelled', 'unknown']),
  starterStatus: z.enum(['ready', 'missing', 'notDue']),
  awayTeam: teamSchema,
  homeTeam: teamSchema,
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
  probablePitchers: z.object({
    away: probablePitcherSchema,
    home: probablePitcherSchema
  }),
  recentPlay: z.string().nullable(),
  teamRecords: z.object({
    away: teamRecordSchema.nullable(),
    home: teamRecordSchema.nullable()
  }).nullable(),
  boxScore: z.object({
    away: boxScoreTeamSchema,
    home: boxScoreTeamSchema,
    linescore: z.array(z.object({
      inning: z.number(),
      away: z.number().nullable(),
      home: z.number().nullable()
    }))
  }).nullable(),
  lineupPreview: z.object({
    away: z.array(z.string()),
    home: z.array(z.string())
  }).nullable(),
  analysis: z.object({
    awaySummary: z.string().nullable(),
    homeSummary: z.string().nullable(),
    keyPoints: z.array(z.string())
  }).nullable(),
  sourceMeta: z.object({
    rawStatusCode: z.string().nullable(),
    rawTopBottomCode: z.string().nullable(),
    fetchedAt: z.string()
  })
})

function seasonFromDate(date: string): number {
  return Number(date.slice(0, 4))
}

function textValue(row: Record<string, unknown>, key: string): string {
  const value = row[key]
  if (typeof value !== 'string') {
    throw new TypeError(`Expected ${key} to be a string`)
  }

  return value
}

export function upsertGameSnapshots(
  date: string,
  games: readonly NormalizedGame[],
  db?: DatabaseSync
): void {
  if (isDatabaseDisabled() || games.length === 0) {
    return
  }

  const database = db ?? getDatabase()
  const now = new Date().toISOString()
  const upsertGame = database.prepare(`
    insert into games (
      game_id,
      season,
      date,
      away_team_id,
      home_team_id,
      venue,
      start_time,
      status,
      created_at,
      updated_at
    )
    values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    on conflict(game_id) do update set
      season = excluded.season,
      date = excluded.date,
      away_team_id = excluded.away_team_id,
      home_team_id = excluded.home_team_id,
      venue = excluded.venue,
      start_time = excluded.start_time,
      status = excluded.status,
      updated_at = excluded.updated_at
  `)
  const insertSnapshot = database.prepare(`
    insert into game_snapshots (
      id,
      game_id,
      captured_at,
      status,
      inning_number,
      inning_half,
      away_score,
      home_score,
      raw_source_id,
      normalized_json
    )
    values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `)

  database.exec('begin')
  try {
    for (const game of games) {
      const capturedAt = game.sourceMeta.fetchedAt || now
      upsertGame.run(
        game.gameId,
        seasonFromDate(date),
        game.date,
        game.awayTeam.id,
        game.homeTeam.id,
        game.venue,
        game.startTime,
        game.status,
        now,
        now
      )
      insertSnapshot.run(
        randomUUID(),
        game.gameId,
        capturedAt,
        game.status,
        game.inning?.number ?? null,
        game.inning?.half ?? null,
        game.score.away,
        game.score.home,
        null,
        JSON.stringify(game)
      )
    }

    database.exec('commit')
  } catch (error) {
    database.exec('rollback')
    throw error
  }
}

export function listLatestGameSnapshots(date: string, db?: DatabaseSync): NormalizedGame[] {
  if (isDatabaseDisabled()) {
    return []
  }

  const database = db ?? getDatabase()
  const rows = database.prepare(`
    select normalized_json as normalizedJson
    from (
      select
        snapshots.normalized_json,
        row_number() over (
          partition by snapshots.game_id
          order by snapshots.captured_at desc, snapshots.id desc
        ) as snapshot_rank,
        games.start_time,
        games.game_id
      from game_snapshots snapshots
      inner join games on games.game_id = snapshots.game_id
      where games.date = ?
    )
    where snapshot_rank = 1
    order by start_time is null, start_time asc, game_id asc
  `).all(date)

  return rows.map((row) => normalizedGameSchema.parse(JSON.parse(textValue(row, 'normalizedJson'))))
}
