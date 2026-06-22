import { mkdir, writeFile } from 'node:fs/promises'
import path from 'node:path'

import { getGameById, getTeamStandings, getTodayGamesRaw } from '../src/services/gameService.js'
import { toKboDate } from '../src/utils/date.js'
import type { NormalizedGame } from '../src/models/normalizedGame.js'

interface ValidationCheck {
  id: string
  level: 'pass' | 'warn' | 'fail'
  message: string
  details?: unknown
}

interface ValidationReport {
  requestedDate: string
  fetchedAt: string
  summary: {
    status: 'pass' | 'warn' | 'fail'
    pass: number
    warn: number
    fail: number
  }
  counts: {
    requestedRawGames: number
    requestedScheduleGames: number
    normalizedMonthGames: number
    standings: number
    statuses: Record<string, number>
  }
  checks: ValidationCheck[]
}

function readArg(name: string, fallback?: string): string | undefined {
  const prefix = `--${name}`
  const args = process.argv.slice(2)

  for (let i = 0; i < args.length; i += 1) {
    if (args[i] === prefix) {
      return args[i + 1] ?? fallback
    }
  }

  return fallback
}

function readBooleanArg(name: string): boolean {
  return process.argv.slice(2).includes(`--${name}`)
}

function timestampForFile(date = new Date()): string {
  return date.toISOString().replaceAll(':', '-').replaceAll('.', '-')
}

function add(checks: ValidationCheck[], level: ValidationCheck['level'], id: string, message: string, details?: unknown) {
  checks.push(details === undefined ? { id, level, message } : { id, level, message, details })
}

function countByStatus(games: NormalizedGame[]): Record<string, number> {
  return games.reduce<Record<string, number>>((result, game) => {
    result[game.status] = (result[game.status] ?? 0) + 1
    return result
  }, {})
}

function requestedDateGames(games: NormalizedGame[], date: string): NormalizedGame[] {
  return games.filter((game) => game.date === date)
}

function validateGameShape(checks: ValidationCheck[], games: NormalizedGame[]) {
  const allowedStatuses = new Set(['scheduled', 'live', 'final', 'delayed', 'cancelled', 'unknown'])

  for (const game of games) {
    if (!allowedStatuses.has(game.status)) {
      add(checks, 'fail', 'game.status.allowed', `unexpected status for ${game.gameId}`, { status: game.status })
    }

    if (!Number.isInteger(game.score.away) || !Number.isInteger(game.score.home) || game.score.away < 0 || game.score.home < 0) {
      add(checks, 'fail', 'game.score.nonnegative', `invalid score for ${game.gameId}`, game.score)
    }

    if (game.status === 'live' && !game.inning && !game.count && !game.bases && !game.current && !game.recentPlay) {
      add(checks, 'warn', 'live.context.present', `live game has no live context fields: ${game.gameId}`)
    }

    if (game.status === 'scheduled' && (game.score.away !== 0 || game.score.home !== 0)) {
      add(checks, 'warn', 'scheduled.score.zero', `scheduled game has non-zero score: ${game.gameId}`, game.score)
    }

    if (game.status !== 'scheduled' && game.boxScore) {
      if (game.boxScore.away.runs !== game.score.away || game.boxScore.home.runs !== game.score.home) {
        add(checks, 'fail', 'boxscore.score.match', `box score runs do not match score: ${game.gameId}`, {
          score: game.score,
          boxScore: game.boxScore
        })
      }
    }
  }
}

async function main() {
  const requestedDate = toKboDate(readArg('date'))
  const shouldWrite = readBooleanArg('write')
  const outDir = readArg('out-dir', path.resolve('artifacts', 'data-validation', requestedDate))!
  const fetchedAt = new Date().toISOString()
  const checks: ValidationCheck[] = []

  const [raw, standingsResult] = await Promise.all([
    getTodayGamesRaw(requestedDate),
    getTeamStandings(requestedDate)
  ])

  const normalizedGames = raw.normalizedGames
  const requestedGames = requestedDateGames(normalizedGames, requestedDate)
  const requestedRawIds = new Set(raw.gameList.game.map((game) => game.G_ID))
  const requestedNormalizedIds = new Set(requestedGames.map((game) => game.gameId))
  const duplicateIds = normalizedGames
    .map((game) => game.gameId)
    .filter((gameId, index, all) => all.indexOf(gameId) !== index)
  const requestedScheduleGames = raw.scheduleGames.filter((game) => game.date === requestedDate)
  const missingNormalizedRawIds = [...requestedRawIds].filter((gameId) => !requestedNormalizedIds.has(gameId))
  const missingScheduleGameIds = requestedScheduleGames
    .map((game) => game.gameId)
    .filter((gameId) => !requestedNormalizedIds.has(gameId))

  add(checks, raw.requestedDate === requestedDate ? 'pass' : 'fail', 'date.normalized', 'requested date normalized consistently', {
    requestedDate,
    rawRequestedDate: raw.requestedDate,
    standingsDate: standingsResult.date
  })

  add(checks, duplicateIds.length === 0 ? 'pass' : 'fail', 'game.id.unique', 'normalized game IDs are unique', duplicateIds)
  add(checks, missingNormalizedRawIds.length === 0 ? 'pass' : 'fail', 'raw.normalized.coverage', 'requested raw games are present in normalized requested-date games', missingNormalizedRawIds)
  add(checks, missingScheduleGameIds.length === 0 ? 'pass' : 'warn', 'schedule.normalized.coverage', 'requested schedule games are present in normalized requested-date games', missingScheduleGameIds)
  add(checks, normalizedGames.length >= requestedGames.length ? 'pass' : 'fail', 'month.includes.requested', 'month-level normalized response includes requested-date games', {
    normalizedMonthGames: normalizedGames.length,
    requestedGames: requestedGames.length
  })

  validateGameShape(checks, normalizedGames)

  if (requestedGames.length > 0) {
    const detailGame = await getGameById(requestedGames[0].gameId, requestedDate)
    add(checks, detailGame.game?.gameId === requestedGames[0].gameId ? 'pass' : 'fail', 'detail.lookup.firstRequestedGame', 'detail lookup returns the requested game by ID', {
      expected: requestedGames[0].gameId,
      actual: detailGame.game?.gameId ?? null
    })
  } else {
    add(checks, 'warn', 'detail.lookup.firstRequestedGame', 'no requested-date game available for detail lookup')
  }

  const standings = standingsResult.standings
  const standingsTeamIds = standings.map((entry) => entry.teamId)
  const duplicateStandingTeamIds = standingsTeamIds.filter((teamId, index, all) => all.indexOf(teamId) !== index)
  add(checks, standings.length === 10 ? 'pass' : 'warn', 'standings.count', 'standings contains 10 KBO teams', { count: standings.length })
  add(checks, duplicateStandingTeamIds.length === 0 ? 'pass' : 'fail', 'standings.team.unique', 'standings team IDs are unique', duplicateStandingTeamIds)

  const knownStandingTeamIds = new Set(standingsTeamIds)
  const missingTeamRecords = requestedGames
    .flatMap((game) => [game.awayTeam.id, game.homeTeam.id])
    .filter((teamId) => knownStandingTeamIds.size > 0 && !knownStandingTeamIds.has(teamId))
  add(checks, missingTeamRecords.length === 0 ? 'pass' : 'warn', 'standings.gameTeam.coverage', 'standings cover requested-date game teams', [...new Set(missingTeamRecords)])

  const fail = checks.filter((check) => check.level === 'fail').length
  const warn = checks.filter((check) => check.level === 'warn').length
  const pass = checks.filter((check) => check.level === 'pass').length
  const report: ValidationReport = {
    requestedDate,
    fetchedAt,
    summary: {
      status: fail > 0 ? 'fail' : warn > 0 ? 'warn' : 'pass',
      pass,
      warn,
      fail
    },
    counts: {
      requestedRawGames: raw.gameList.game.length,
      requestedScheduleGames: requestedScheduleGames.length,
      normalizedMonthGames: normalizedGames.length,
      standings: standings.length,
      statuses: countByStatus(normalizedGames)
    },
    checks
  }

  console.log(JSON.stringify(report, null, 2))

  if (shouldWrite) {
    await mkdir(outDir, { recursive: true })
    const baseName = `data-validation-${requestedDate}-${timestampForFile()}`
    await writeFile(path.join(outDir, `${baseName}.json`), `${JSON.stringify(report, null, 2)}\n`, 'utf8')
    await writeFile(path.join(outDir, 'latest.json'), `${JSON.stringify(report, null, 2)}\n`, 'utf8')
  }

  if (fail > 0) {
    process.exitCode = 1
  }
}

await main()
