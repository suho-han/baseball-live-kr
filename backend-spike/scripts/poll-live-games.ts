import { appendFile, mkdir, writeFile } from 'node:fs/promises'
import path from 'node:path'
import { pathToFileURL } from 'node:url'

import { fetchKboGameList, fetchKboScheduleList } from '../src/clients/kboClient.js'
import type { RawKboGameListResponse } from '../src/dto/kboGameList.dto.js'
import type { RawKboScheduleListResponse } from '../src/dto/kboScheduleList.dto.js'
import { mapGame } from '../src/mappers/gameMapper.js'
import { indexScheduleGames } from '../src/mappers/scheduleMapper.js'
import type { NormalizedGame } from '../src/models/normalizedGame.js'
import { summarizeGameChanges, toPollingView } from '../src/utils/gameSnapshot.js'
import { toKboDate } from '../src/utils/date.js'

type PollingGameView = ReturnType<typeof toPollingView>

interface PollingPayload {
  fetchedAt: string
  date: string
  gameCount: number
  changedGames: number
  changes: ReturnType<typeof summarizeGameChanges>
  games: PollingGameView[]
}

interface PollingTickInput {
  captureOnChange: boolean
  date: string
  fetchedAt: Date
  fixturesDir: string
  logsDir: string
  previousGames: NormalizedGame[]
  rawGameList: RawKboGameListResponse
  saveRaw: boolean
  saveSnapshots: boolean
  scheduleList: RawKboScheduleListResponse
  writeStdout: boolean
}

interface PollingTickResult {
  normalizedGames: NormalizedGame[]
  payload: PollingPayload
}

function readArg(name: string): string | undefined
function readArg(name: string, fallback: string): string
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

async function ensureDir(dirPath: string) {
  await mkdir(dirPath, { recursive: true })
}

async function writeJson(filePath: string, value: unknown) {
  await ensureDir(path.dirname(filePath))
  await writeFile(filePath, `${JSON.stringify(value, null, 2)}\n`, 'utf8')
}

export async function runPollingTick(input: PollingTickInput): Promise<PollingTickResult> {
  const scheduleByGameId = indexScheduleGames(input.scheduleList)
  const normalized = input.rawGameList.game.map((game) => mapGame(game, scheduleByGameId.get(game.G_ID)))
  const changes = summarizeGameChanges(input.previousGames, normalized)
  const timestamp = timestampForFile(input.fetchedAt)

  const payload = {
    fetchedAt: input.fetchedAt.toISOString(),
    date: input.date,
    gameCount: normalized.length,
    changedGames: changes.length,
    changes,
    games: normalized.map(toPollingView)
  } satisfies PollingPayload

  if (input.writeStdout) {
    console.log(JSON.stringify(payload, null, 2))
  }

  await ensureDir(input.logsDir)
  await appendFile(path.join(input.logsDir, 'events.ndjson'), `${JSON.stringify(payload)}\n`, 'utf8')

  if (input.saveSnapshots) {
    await writeJson(path.join(input.logsDir, 'snapshots', `${timestamp}.normalized.json`), payload)
  }

  if (input.saveRaw) {
    await writeJson(path.join(input.logsDir, 'snapshots', `${timestamp}.raw.json`), {
      fetchedAt: input.fetchedAt.toISOString(),
      date: input.date,
      gameList: input.rawGameList
    })
  }

  await writeJson(path.join(input.fixturesDir, 'latest-normalized.json'), payload)

  if (input.saveRaw) {
    await writeJson(path.join(input.fixturesDir, 'latest-raw.json'), {
      fetchedAt: input.fetchedAt.toISOString(),
      date: input.date,
      gameList: input.rawGameList,
      scheduleList: input.scheduleList
    })
  }

  if (input.captureOnChange && changes.length > 0) {
    await writeJson(path.join(input.fixturesDir, 'changes', `${timestamp}.json`), payload)

    if (input.saveRaw) {
      await writeJson(path.join(input.fixturesDir, 'changes', `${timestamp}.raw.json`), {
        fetchedAt: input.fetchedAt.toISOString(),
        date: input.date,
        gameList: input.rawGameList,
        scheduleList: input.scheduleList
      })
    }
  }

  return {
    normalizedGames: normalized,
    payload
  }
}

async function main(): Promise<void> {
  const date = toKboDate(readArg('date'))
  const intervalSeconds = Number(readArg('interval', '30'))
  const iterations = Number(readArg('iterations', '0'))
  const logsDir = readArg('logs-dir', path.resolve('logs/polling', date))
  const fixturesDir = readArg('fixtures-dir', path.resolve('fixtures', date))
  const saveRaw = readBooleanArg('save-raw')
  const saveSnapshots = !readBooleanArg('no-save-snapshots')
  const captureOnChange = !readBooleanArg('no-capture-on-change')
  const scheduleList = await fetchKboScheduleList(date.slice(0, 4), date.slice(4, 6))
  let previousGames: NormalizedGame[] = []
  let runCount = 0

  async function tick(): Promise<void> {
    const result = await runPollingTick({
      captureOnChange,
      date,
      fetchedAt: new Date(),
      fixturesDir,
      logsDir,
      previousGames,
      rawGameList: await fetchKboGameList(date),
      saveRaw,
      saveSnapshots,
      scheduleList,
      writeStdout: true
    })

    previousGames = result.normalizedGames
    runCount += 1
  }

  await tick()

  if (iterations > 0 && runCount >= iterations) {
    process.exit(0)
  }

  const timer = setInterval(() => {
    tick()
      .then(() => {
        if (iterations > 0 && runCount >= iterations) {
          clearInterval(timer)
          process.exit(0)
        }
      })
      .catch((error) => {
        console.error('[poll-live-games] tick failed', error)
      })
  }, intervalSeconds * 1000)
}

if (process.argv[1] !== undefined && import.meta.url === pathToFileURL(process.argv[1]).href) {
  await main()
}
