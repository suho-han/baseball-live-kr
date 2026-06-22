import { mkdir, writeFile } from 'node:fs/promises'
import path from 'node:path'

import { parseBattingLeaders, parsePitchingLeaders } from '../src/mappers/playerLeaderMapper.js'
import { upsertBattingSeasonRecords, upsertPitchingSeasonRecords } from '../src/repositories/playerRecordRepository.js'
import { saveRawSource } from '../src/repositories/rawSourceRepository.js'
import { getTeamStandings, getTodayGamesRaw } from '../src/services/gameService.js'
import { toKboDate } from '../src/utils/date.js'

type PlayerRecordKind = 'batting' | 'pitching'

interface CollectedDateSummary {
  date: string
  rawGames: number
  requestedScheduleGames: number
  normalizedGames: number
  requestedNormalizedGames: number
  standings: number
  statuses: Record<string, number>
  file?: string
  teamRecordsFile?: string
}

interface PlayerSourceSummary {
  kind: PlayerRecordKind
  url: string
  statusCode: number
  bodyLength: number
  parsedRecords: number
  htmlFile?: string
  metadataFile?: string
  recordsFile?: string
}

const PLAYER_URLS: Record<PlayerRecordKind, string> = {
  batting: 'https://eng.koreabaseball.com/stats/battingLeaders.aspx',
  pitching: 'https://eng.koreabaseball.com/stats/pitchingLeaders.aspx'
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

function todayKboDate(date = new Date()): string {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Seoul',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  }).format(date).replaceAll('-', '')
}

function parseDates(): string[] {
  const explicitDates = readArg('dates')
  const singleDate = readArg('date')

  if (explicitDates) {
    return [...new Set(explicitDates.split(',').map((date) => toKboDate(date.trim())).filter(Boolean))]
  }

  if (singleDate) {
    return [toKboDate(singleDate)]
  }

  return [todayKboDate()]
}

function countByStatus(games: Array<{ status: string }>): Record<string, number> {
  return games.reduce<Record<string, number>>((result, game) => {
    result[game.status] = (result[game.status] ?? 0) + 1
    return result
  }, {})
}

async function writeJson(filePath: string, value: unknown) {
  await mkdir(path.dirname(filePath), { recursive: true })
  await writeFile(filePath, `${JSON.stringify(value, null, 2)}\n`, 'utf8')
}

async function collectDate(date: string, outDir: string, shouldWrite: boolean): Promise<CollectedDateSummary> {
  const [raw, standings] = await Promise.all([
    getTodayGamesRaw(date),
    getTeamStandings(date)
  ])
  const requestedScheduleGames = raw.scheduleGames.filter((game) => game.date === date)
  const requestedNormalizedGames = raw.normalizedGames.filter((game) => game.date === date)
  const summary: CollectedDateSummary = {
    date,
    rawGames: raw.gameList.game.length,
    requestedScheduleGames: requestedScheduleGames.length,
    normalizedGames: raw.normalizedGames.length,
    requestedNormalizedGames: requestedNormalizedGames.length,
    standings: standings.standings.length,
    statuses: countByStatus(raw.normalizedGames)
  }

  if (shouldWrite) {
    const dateDir = path.join(outDir, 'dates', date)
    const file = path.join(dateDir, 'source-normalized.json')
    const teamRecordsFile = path.join(dateDir, 'team-records.json')
    await writeJson(file, {
      collectedAt: new Date().toISOString(),
      date,
      raw,
      standings
    })
    await writeJson(teamRecordsFile, {
      collectedAt: new Date().toISOString(),
      date,
      source: 'kbo-official-team-rank-daily',
      records: standings.standings
    })
    summary.file = path.relative(process.cwd(), file)
    summary.teamRecordsFile = path.relative(process.cwd(), teamRecordsFile)
  }

  return summary
}

async function fetchPlayerSource(kind: PlayerRecordKind) {
  const url = PLAYER_URLS[kind]
  const response = await fetch(url, {
    headers: {
      'User-Agent': 'Mozilla/5.0',
      Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      Referer: 'https://eng.koreabaseball.com/stats/'
    }
  })
  const body = await response.text()
  const fetchedAt = new Date().toISOString()

  saveRawSource({
    source: 'kbo-official-eng',
    endpoint: kind === 'batting' ? 'BattingLeaders' : 'PitchingLeaders',
    requestKey: `kind=${kind}`,
    statusCode: response.status,
    body,
    fetchedAt
  })

  if (!response.ok) {
    throw new Error(`${kind} source returned HTTP ${response.status}`)
  }

  return {
    kind,
    url,
    fetchedAt,
    statusCode: response.status,
    body
  }
}

async function collectPlayerSource(date: string, outDir: string, shouldWrite: boolean): Promise<PlayerSourceSummary[]> {
  const dumps = await Promise.all((['batting', 'pitching'] as PlayerRecordKind[]).map(fetchPlayerSource))
  const summaries: PlayerSourceSummary[] = []

  for (const dump of dumps) {
    let parsedRecords = 0
    let records: unknown[] = []

    if (dump.kind === 'batting') {
      const parsed = parseBattingLeaders(dump.body)
      upsertBattingSeasonRecords(date, parsed)
      parsedRecords = parsed.length
      records = parsed
    } else {
      const parsed = parsePitchingLeaders(dump.body)
      upsertPitchingSeasonRecords(date, parsed)
      parsedRecords = parsed.length
      records = parsed
    }

    const summary: PlayerSourceSummary = {
      kind: dump.kind,
      url: dump.url,
      statusCode: dump.statusCode,
      bodyLength: dump.body.length,
      parsedRecords
    }

    if (shouldWrite) {
      const baseDir = path.join(outDir, 'player-records')
      const htmlFile = path.join(baseDir, `${dump.kind}-latest.html`)
      const metadataFile = path.join(baseDir, `${dump.kind}-latest.json`)
      const recordsFile = path.join(baseDir, `${dump.kind}-records-latest.json`)
      await mkdir(baseDir, { recursive: true })
      await writeFile(htmlFile, dump.body, 'utf8')
      await writeJson(metadataFile, {
        kind: dump.kind,
        url: dump.url,
        fetchedAt: dump.fetchedAt,
        statusCode: dump.statusCode,
        bodyLength: dump.body.length,
        parsedRecords
      })
      await writeJson(recordsFile, {
        kind: dump.kind,
        url: dump.url,
        fetchedAt: dump.fetchedAt,
        source: dump.kind === 'batting' ? 'kbo-official-eng-batting-leaders' : 'kbo-official-eng-pitching-leaders',
        records
      })
      summary.htmlFile = path.relative(process.cwd(), htmlFile)
      summary.metadataFile = path.relative(process.cwd(), metadataFile)
      summary.recordsFile = path.relative(process.cwd(), recordsFile)
    }

    summaries.push(summary)
  }

  return summaries
}

async function main() {
  const dates = parseDates()
  const shouldWrite = readBooleanArg('write')
  const includePlayerRecords = readBooleanArg('include-player-records')
  const runId = readArg('run-id', timestampForFile())!
  const outDir = readArg('out-dir', path.resolve('artifacts', 'source-collection', runId))!
  const dateSummaries: CollectedDateSummary[] = []

  for (const date of dates) {
    dateSummaries.push(await collectDate(date, outDir, shouldWrite))
  }

  const playerSources = includePlayerRecords
    ? await collectPlayerSource(dates[0], outDir, shouldWrite)
    : []

  const manifest = {
    runId,
    collectedAt: new Date().toISOString(),
    dates,
    outDir: shouldWrite ? path.relative(process.cwd(), outDir) : null,
    gameSources: dateSummaries,
    playerSources
  }

  console.log(JSON.stringify(manifest, null, 2))

  if (shouldWrite) {
    await writeJson(path.join(outDir, 'manifest.json'), manifest)
  }
}

await main()
