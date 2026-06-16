import { fetchKboGameDate, fetchKboGameList, fetchKboScheduleList, fetchKboTeamRankDailyPage } from '../clients/kboClient.js'
import { makeTestLiveGame } from '../fixtures/testLiveGame.js'
import { mapGame, mapScheduledGame } from '../mappers/gameMapper.js'
import { mapScheduleGames } from '../mappers/scheduleMapper.js'
import { parseKboTeamRankDaily } from '../mappers/teamRankMapper.js'
import { toKboDate } from '../utils/date.js'
import type { NormalizedGame, TeamRecordSummary } from '../models/normalizedGame.js'

interface TodayGamesResult {
  date: string
  games: NormalizedGame[]
}

interface TodayGamesCacheEntry {
  value: TodayGamesResult
  expiresAt: number
  staleUntil: number
}

const todayGamesCache = new Map<string, TodayGamesCacheEntry>()
const todayGamesInFlight = new Map<string, Promise<TodayGamesResult>>()
const teamRankCache = new Map<string, {
  value: Map<string, TeamRecordSummary>
  expiresAt: number
}>()

function envNumber(name: string, fallback: number): number {
  const value = process.env[name]
  if (value === undefined) {
    return fallback
  }

  const parsed = Number(value)
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : fallback
}

function gameCacheTtlSeconds(games: NormalizedGame[]): number {
  if (games.some((game) => game.status === 'live')) {
    return envNumber('KBO_CACHE_TTL_GAME_LIVE_SEC', 5)
  }

  return envNumber('KBO_CACHE_TTL_GAME_IDLE_SEC', 60)
}

function staleIfErrorSeconds(): number {
  return envNumber('KBO_CACHE_STALE_IF_ERROR_SEC', 600)
}

function teamRankCacheTtlSeconds(): number {
  return envNumber('KBO_CACHE_TTL_STANDINGS_SEC', 600)
}

async function loadTeamRecords(kboDate: string): Promise<Map<string, TeamRecordSummary>> {
  const cached = teamRankCache.get(kboDate)
  const now = Date.now()
  if (cached && cached.expiresAt > now) {
    return cached.value
  }

  try {
    const html = await fetchKboTeamRankDailyPage(kboDate)
    const records = new Map(
      parseKboTeamRankDaily(html).map((entry) => [
        entry.teamId,
        {
          wins: entry.wins,
          losses: entry.losses,
          draws: entry.draws,
          rank: entry.rank,
          streak: entry.streak
        }
      ])
    )

    teamRankCache.set(kboDate, {
      value: records,
      expiresAt: now + teamRankCacheTtlSeconds() * 1000
    })

    return records
  } catch {
    return cached?.value ?? new Map()
  }
}

function enrichTeamRecords(game: NormalizedGame, recordsByTeamId: Map<string, TeamRecordSummary>): NormalizedGame {
  const away = recordsByTeamId.get(game.awayTeam.id) ?? game.teamRecords?.away ?? null
  const home = recordsByTeamId.get(game.homeTeam.id) ?? game.teamRecords?.home ?? null

  if (!away && !home) {
    return game
  }

  return {
    ...game,
    teamRecords: {
      away,
      home
    }
  }
}

async function loadMonthGames(kboDate: string) {
  const [gameDate, scheduleList] = await Promise.all([
    fetchKboGameDate(kboDate),
    fetchKboScheduleList(kboDate.slice(0, 4), kboDate.slice(4, 6))
  ])
  const scheduleGames = mapScheduleGames(scheduleList)
    .filter((game) => game.date.startsWith(kboDate.slice(0, 6)))
  const scheduleByGameId = new Map(scheduleGames.map((game) => [game.gameId, game]))
  const dates = [...new Set([kboDate, ...scheduleGames.map((game) => game.date)])].sort()
  const gameLists = await Promise.all(
    dates.map(async (date) => ({
      date,
      gameList: await fetchKboGameList(date)
    }))
  )

  const gamesById = new Map<string, NormalizedGame>()
  for (const { gameList } of gameLists) {
    for (const game of gameList.game) {
      gamesById.set(game.G_ID, mapGame(game, scheduleByGameId.get(game.G_ID)))
    }
  }

  for (const scheduleGame of scheduleGames) {
    if (!gamesById.has(scheduleGame.gameId)) {
      gamesById.set(scheduleGame.gameId, mapScheduledGame(scheduleGame))
    }
  }

  const teamRecords = await loadTeamRecords(kboDate)
  const games = [...gamesById.values()]
    .map((game) => enrichTeamRecords(game, teamRecords))
    .sort((lhs, rhs) => {
      const lhsStart = lhs.startTime ?? lhs.date
      const rhsStart = rhs.startTime ?? rhs.date
      if (lhsStart !== rhsStart) {
        return lhsStart.localeCompare(rhsStart)
      }

      return lhs.gameId.localeCompare(rhs.gameId)
    })

  return {
    gameDate,
    scheduleList,
    scheduleGames,
    gameLists,
    games
  }
}

export async function getTodayGames(date?: string) {
  const kboDate = toKboDate(date)

  if (process.env.KBO_USE_TEST_LIVE_GAME === '1') {
    return {
      date: kboDate,
      games: [makeTestLiveGame(kboDate)]
    }
  }

  const now = Date.now()
  const cached = todayGamesCache.get(kboDate)
  if (cached && cached.expiresAt > now) {
    return cached.value
  }

  const inFlight = todayGamesInFlight.get(kboDate)
  if (inFlight) {
    return inFlight
  }

  const request = (async (): Promise<TodayGamesResult> => {
    try {
      const { games } = await loadMonthGames(kboDate)
      const value = {
        date: kboDate,
        games
      }
      const cacheTtlMs = gameCacheTtlSeconds(games) * 1000
      const staleTtlMs = staleIfErrorSeconds() * 1000
      const writtenAt = Date.now()

      todayGamesCache.set(kboDate, {
        value,
        expiresAt: writtenAt + cacheTtlMs,
        staleUntil: writtenAt + cacheTtlMs + staleTtlMs
      })

      return value
    } catch (error) {
      const stale = todayGamesCache.get(kboDate)
      if (stale && stale.staleUntil > Date.now()) {
        return stale.value
      }

      throw error
    } finally {
      todayGamesInFlight.delete(kboDate)
    }
  })()

  todayGamesInFlight.set(kboDate, request)
  return request
}

export async function getGameById(gameId: string, date?: string) {
  const result = await getTodayGames(date)
  return {
    date: result.date,
    game: result.games.find((game) => game.gameId === gameId) ?? null
  }
}

export async function getTodayGamesRaw(date?: string) {
  const kboDate = toKboDate(date)

  if (process.env.KBO_USE_TEST_LIVE_GAME === '1') {
    const game = makeTestLiveGame(kboDate)

    return {
      requestedDate: kboDate,
      gameDate: null,
      gameList: { game: [] },
      gameLists: [],
      scheduleList: { rows: [] },
      scheduleGames: [],
      normalizedGames: [game]
    }
  }

  const { gameDate, scheduleList, scheduleGames, gameLists, games } = await loadMonthGames(kboDate)
  const requestedGameList = gameLists.find((entry) => entry.date === kboDate)?.gameList ?? { game: [] }

  return {
    requestedDate: kboDate,
    gameDate,
    gameList: requestedGameList,
    gameLists,
    scheduleList,
    scheduleGames,
    normalizedGames: games
  }
}

export function clearGameServiceCacheForTests() {
  todayGamesCache.clear()
  todayGamesInFlight.clear()
  teamRankCache.clear()
}
