import { mkdir, writeFile } from 'node:fs/promises'
import path from 'node:path'

import { loadKboMonthGameSource } from '../src/services/monthScheduleSource.js'
import { toPollingView } from '../src/utils/gameSnapshot.js'
import { toKboDate } from '../src/utils/date.js'

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

async function writeJson(filePath: string, value: unknown) {
  await mkdir(path.dirname(filePath), { recursive: true })
  await writeFile(filePath, `${JSON.stringify(value, null, 2)}\n`, 'utf8')
}

const date = toKboDate(readArg('date'))
const outDir = readArg('out-dir', path.resolve('fixtures', date, 'dump'))!
const shouldWrite = readBooleanArg('write')
const fetchedAt = new Date().toISOString()

const source = await loadKboMonthGameSource(date)
const requestedScheduleGames = source.scheduleGames.filter((game) => game.date === date)
const requestedNormalizedGames = source.normalizedGames.filter((game) => game.date === date)
const payload = {
  requestedDate: date,
  fetchedAt,
  gameDate: source.gameDate,
  gameList: source.requestedGameList,
  gameLists: source.gameLists,
  scheduleList: source.scheduleList,
  scheduleGames: source.scheduleGames,
  requestedScheduleGames,
  normalizedGames: source.normalizedGames,
  requestedNormalizedGames,
  pollingView: source.normalizedGames.map(toPollingView)
}

console.log(JSON.stringify(payload, null, 2))

if (shouldWrite) {
  const timestamp = timestampForFile()
  await writeJson(path.join(outDir, `${timestamp}.json`), payload)
  await writeJson(path.join(outDir, 'latest.json'), payload)
}
