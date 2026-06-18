import { mapTeamNameToId } from './teamIdMapper.js'

export interface BattingLeaderEntry {
  playerId: string
  playerName: string
  teamId: string
  teamName: string
  rank: number | null
  games: number | null
  plateAppearances: number | null
  atBats: number | null
  runs: number | null
  hits: number | null
  doubles: number | null
  triples: number | null
  homeRuns: number | null
  totalBases: number | null
  rbi: number | null
  stolenBases: number | null
  caughtStealing: number | null
  sacrificeHits: number | null
  sacrificeFlies: number | null
  avg: number | null
}

export interface PitchingLeaderEntry {
  playerId: string
  playerName: string
  teamId: string
  teamName: string
  rank: number | null
  games: number | null
  completeGames: number | null
  shutouts: number | null
  wins: number | null
  losses: number | null
  saves: number | null
  holds: number | null
  winningPercentage: number | null
  plateAppearances: number | null
  pitches: number | null
  inningsPitchedOuts: number | null
  hitsAllowed: number | null
  doublesAllowed: number | null
  triplesAllowed: number | null
  homeRunsAllowed: number | null
  era: number | null
}

function decodeHtml(value: string): string {
  return value
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&#39;/g, "'")
    .replace(/&quot;/g, '"')
}

function stripTags(value: string): string {
  return decodeHtml(value.replace(/<br\s*\/?>/gi, '\n').replace(/<[^>]*>/g, '')).trim()
}

function toNumber(value: string | undefined): number | null {
  if (!value) {
    return null
  }

  const normalized = value.trim().replace(/,/g, '')
  if (normalized === '' || normalized === '-') {
    return null
  }

  const parsed = Number(normalized)
  return Number.isFinite(parsed) ? parsed : null
}

function inningsToOuts(value: string | undefined): number | null {
  if (!value) {
    return null
  }

  const [wholeText, fractionText] = value.trim().split(/\s+/)
  const whole = Number(wholeText)
  if (!Number.isFinite(whole)) {
    return null
  }

  if (!fractionText) {
    return whole * 3
  }

  const numerator = Number(fractionText.split('/')[0])
  return Number.isFinite(numerator) ? whole * 3 + numerator : whole * 3
}

function tableHtml(html: string, summaryPattern: RegExp): string | null {
  const match = html.match(/<table[^>]*summary="([^"]*)"[^>]*>[\s\S]*?<\/table>/gi)
    ?.find((table) => summaryPattern.test(table))
  return match ?? null
}

function rowCells(rowHtml: string): Map<string, string> {
  const cells = new Map<string, string>()
  for (const match of rowHtml.matchAll(/<td([^>]*)>([\s\S]*?)<\/td>/gi)) {
    const title = match[1].match(/title="([^"]*)"/i)?.[1]
    if (title) {
      cells.set(title.trim().toUpperCase(), match[2])
    }
  }
  return cells
}

function playerFromCell(cellHtml: string | undefined): { playerId: string, playerName: string } | null {
  if (!cellHtml) {
    return null
  }

  const playerId = cellHtml.match(/pcode=([0-9A-Za-z_-]+)/i)?.[1]
  const playerName = stripTags(cellHtml)
  if (!playerId || playerName === '') {
    return null
  }

  return { playerId, playerName }
}

function rowsForTable(html: string, summaryPattern: RegExp): Map<string, string>[] {
  const table = tableHtml(html, summaryPattern)
  if (!table) {
    return []
  }

  return [...table.matchAll(/<tr[^>]*>([\s\S]*?)<\/tr>/gi)]
    .map((row) => rowCells(row[1]))
    .filter((cells) => cells.size > 0)
}

export function parseBattingLeaders(html: string): BattingLeaderEntry[] {
  return rowsForTable(html, /batting leaders/i).flatMap((cells) => {
    const player = playerFromCell(cells.get('PLAYER'))
    const teamName = stripTags(cells.get('TEAM') ?? '')
    const teamId = mapTeamNameToId(teamName)
    if (!player || !teamId) {
      return []
    }

    return [{
      ...player,
      teamId,
      teamName,
      rank: toNumber(stripTags(cells.get('RK') ?? '')),
      games: toNumber(stripTags(cells.get('G') ?? '')),
      plateAppearances: toNumber(stripTags(cells.get('PA') ?? '')),
      atBats: toNumber(stripTags(cells.get('AB') ?? '')),
      runs: toNumber(stripTags(cells.get('R') ?? '')),
      hits: toNumber(stripTags(cells.get('H') ?? '')),
      doubles: toNumber(stripTags(cells.get('2B') ?? '')),
      triples: toNumber(stripTags(cells.get('3B') ?? '')),
      homeRuns: toNumber(stripTags(cells.get('HR') ?? '')),
      totalBases: toNumber(stripTags(cells.get('TB') ?? '')),
      rbi: toNumber(stripTags(cells.get('RBI') ?? '')),
      stolenBases: toNumber(stripTags(cells.get('SB') ?? '')),
      caughtStealing: toNumber(stripTags(cells.get('CS') ?? '')),
      sacrificeHits: toNumber(stripTags(cells.get('SAC') ?? '')),
      sacrificeFlies: toNumber(stripTags(cells.get('SF') ?? '')),
      avg: toNumber(stripTags(cells.get('AVG') ?? ''))
    }]
  })
}

export function parsePitchingLeaders(html: string): PitchingLeaderEntry[] {
  return rowsForTable(html, /pitching leaders/i).flatMap((cells) => {
    const player = playerFromCell(cells.get('PLAYER'))
    const teamName = stripTags(cells.get('TEAM') ?? '')
    const teamId = mapTeamNameToId(teamName)
    if (!player || !teamId) {
      return []
    }

    return [{
      ...player,
      teamId,
      teamName,
      rank: toNumber(stripTags(cells.get('RK') ?? '')),
      games: toNumber(stripTags(cells.get('G') ?? '')),
      completeGames: toNumber(stripTags(cells.get('CG') ?? '')),
      shutouts: toNumber(stripTags(cells.get('SHO') ?? '')),
      wins: toNumber(stripTags(cells.get('W') ?? '')),
      losses: toNumber(stripTags(cells.get('L') ?? '')),
      saves: toNumber(stripTags(cells.get('SV') ?? '')),
      holds: toNumber(stripTags(cells.get('HLD') ?? '')),
      winningPercentage: toNumber(stripTags(cells.get('PCT') ?? '')),
      plateAppearances: toNumber(stripTags(cells.get('PA') ?? '')),
      pitches: toNumber(stripTags(cells.get('NP') ?? '')),
      inningsPitchedOuts: inningsToOuts(stripTags(cells.get('IP') ?? '')),
      hitsAllowed: toNumber(stripTags(cells.get('H') ?? '')),
      doublesAllowed: toNumber(stripTags(cells.get('2B') ?? '')),
      triplesAllowed: toNumber(stripTags(cells.get('3B') ?? '')),
      homeRunsAllowed: toNumber(stripTags(cells.get('HR') ?? '')),
      era: toNumber(stripTags(cells.get('ERA') ?? ''))
    }]
  })
}

