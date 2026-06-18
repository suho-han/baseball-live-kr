import { mkdir, writeFile } from 'node:fs/promises'
import path from 'node:path'

import { parseBattingLeaders, parsePitchingLeaders } from '../src/mappers/playerLeaderMapper.js'
import { upsertBattingSeasonRecords, upsertPitchingSeasonRecords } from '../src/repositories/playerRecordRepository.js'
import { saveRawSource } from '../src/repositories/rawSourceRepository.js'

type PlayerRecordKind = 'batting' | 'pitching'

interface DumpedPlayerRecordSource {
  kind: PlayerRecordKind
  url: string
  fetchedAt: string
  statusCode: number
  body: string
}

const URLS: Record<PlayerRecordKind, string> = {
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

function selectedKinds(): PlayerRecordKind[] {
  const kind = readArg('kind', 'all')
  if (kind === 'all') {
    return ['batting', 'pitching']
  }

  if (kind === 'batting' || kind === 'pitching') {
    return [kind]
  }

  throw new Error(`invalid --kind: ${kind}`)
}

async function fetchPlayerRecordSource(kind: PlayerRecordKind): Promise<DumpedPlayerRecordSource> {
  const url = URLS[kind]
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

async function writeDump(outDir: string, dump: DumpedPlayerRecordSource) {
  await mkdir(outDir, { recursive: true })
  const baseName = `${dump.kind}-${timestampForFile()}`
  await writeFile(path.join(outDir, `${baseName}.html`), dump.body, 'utf8')
  await writeFile(path.join(outDir, `${baseName}.json`), `${JSON.stringify({
    kind: dump.kind,
    url: dump.url,
    fetchedAt: dump.fetchedAt,
    statusCode: dump.statusCode,
    bodyLength: dump.body.length
  }, null, 2)}\n`, 'utf8')
  await writeFile(path.join(outDir, `${dump.kind}-latest.html`), dump.body, 'utf8')
}

const outDir = readArg('out-dir', path.resolve('fixtures', 'player-records-source'))!
const shouldWrite = readBooleanArg('write')
const date = readArg('date', todayKboDate())!
const dumps = await Promise.all(selectedKinds().map(fetchPlayerRecordSource))
const parsed = {
  batting: dumps.find((dump) => dump.kind === 'batting') ? parseBattingLeaders(dumps.find((dump) => dump.kind === 'batting')!.body) : [],
  pitching: dumps.find((dump) => dump.kind === 'pitching') ? parsePitchingLeaders(dumps.find((dump) => dump.kind === 'pitching')!.body) : []
}

upsertBattingSeasonRecords(date, parsed.batting)
upsertPitchingSeasonRecords(date, parsed.pitching)

console.log(JSON.stringify({
  date,
  sources: dumps.map((dump) => ({
    kind: dump.kind,
    url: dump.url,
    fetchedAt: dump.fetchedAt,
    statusCode: dump.statusCode,
    bodyLength: dump.body.length
  })),
  parsed: {
    batting: parsed.batting.length,
    pitching: parsed.pitching.length
  }
}, null, 2))

if (shouldWrite) {
  for (const dump of dumps) {
    await writeDump(outDir, dump)
  }
}
