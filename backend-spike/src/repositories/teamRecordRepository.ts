import type { DatabaseSync } from 'node:sqlite'

import { getDatabase, isDatabaseDisabled } from '../db/database.js'
import type { TeamRankEntry } from '../mappers/teamRankMapper.js'

export interface TeamSeasonRecord {
  season: number
  date: string
  teamId: string
  teamName: string
  rank: number | null
  games: number | null
  wins: number | null
  losses: number | null
  draws: number | null
  winningPercentage: number | null
  gamesBehind: string | null
  recent10: string | null
  streak: string | null
  homeRecord: string | null
  awayRecord: string | null
  runsScored: number | null
  runsAllowed: number | null
  source: string
  rawSourceId: string | null
  createdAt: string
  updatedAt: string
}

function parseWinRate(value: string | null): number | null {
  if (!value) {
    return null
  }

  const parsed = Number(value)
  return Number.isFinite(parsed) ? parsed : null
}

function seasonFromDate(date: string): number {
  return Number(date.slice(0, 4))
}

export function upsertTeamSeasonRecords(
  date: string,
  entries: TeamRankEntry[],
  db?: DatabaseSync
): void {
  if (isDatabaseDisabled() || entries.length === 0) {
    return
  }

  const database = db ?? getDatabase()
  const now = new Date().toISOString()
  const season = seasonFromDate(date)
  const upsertTeam = database.prepare(`
    insert into teams (
      id,
      short_name,
      full_name,
      normalized_name,
      created_at,
      updated_at
    )
    values (?, ?, ?, ?, ?, ?)
    on conflict(id) do update set
      short_name = excluded.short_name,
      full_name = excluded.full_name,
      normalized_name = excluded.normalized_name,
      updated_at = excluded.updated_at
  `)
  const upsertRecord = database.prepare(`
    insert into team_season_records (
      season,
      date,
      team_id,
      team_name,
      rank,
      games,
      wins,
      losses,
      draws,
      winning_percentage,
      games_behind,
      recent_10,
      streak,
      home_record,
      away_record,
      runs_scored,
      runs_allowed,
      source,
      raw_source_id,
      created_at,
      updated_at
    )
    values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    on conflict(season, date, team_id) do update set
      team_name = excluded.team_name,
      rank = excluded.rank,
      games = excluded.games,
      wins = excluded.wins,
      losses = excluded.losses,
      draws = excluded.draws,
      winning_percentage = excluded.winning_percentage,
      games_behind = excluded.games_behind,
      recent_10 = excluded.recent_10,
      streak = excluded.streak,
      home_record = excluded.home_record,
      away_record = excluded.away_record,
      runs_scored = excluded.runs_scored,
      runs_allowed = excluded.runs_allowed,
      source = excluded.source,
      raw_source_id = excluded.raw_source_id,
      updated_at = excluded.updated_at
  `)

  database.exec('begin')
  try {
    for (const entry of entries) {
      upsertTeam.run(entry.teamId, entry.teamName, entry.teamName, entry.teamName, now, now)
      upsertRecord.run(
        season,
        date,
        entry.teamId,
        entry.teamName,
        entry.rank,
        null,
        entry.wins,
        entry.losses,
        entry.draws,
        parseWinRate(entry.winRate),
        entry.gamesBack,
        entry.recentTen,
        entry.streak,
        null,
        null,
        null,
        null,
        'kbo-official-team-rank-daily',
        null,
        now,
        now
      )
    }

    database.exec('commit')
  } catch (error) {
    database.exec('rollback')
    throw error
  }
}

export function listTeamSeasonRecords(date: string, db: DatabaseSync = getDatabase()): TeamSeasonRecord[] {
  const season = seasonFromDate(date)
  return db.prepare(`
    select
      season,
      date,
      team_id as teamId,
      team_name as teamName,
      rank,
      games,
      wins,
      losses,
      draws,
      winning_percentage as winningPercentage,
      games_behind as gamesBehind,
      recent_10 as recent10,
      streak,
      home_record as homeRecord,
      away_record as awayRecord,
      runs_scored as runsScored,
      runs_allowed as runsAllowed,
      source,
      raw_source_id as rawSourceId,
      created_at as createdAt,
      updated_at as updatedAt
    from team_season_records
    where season = ? and date = ?
    order by rank is null, rank asc, team_name asc
  `).all(season, date) as unknown as TeamSeasonRecord[]
}
