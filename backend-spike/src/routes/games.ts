import type { FastifyInstance } from 'fastify'

import { canExposeDebugSource } from '../config/runtimeConfig.js'
import { getPlayerSeasonRecord, searchPlayers } from '../repositories/playerRecordRepository.js'
import { getGameById, getTeamStandings, getTodayGames, getTodayGamesRaw } from '../services/gameService.js'

export function registerGamesRoutes(server: FastifyInstance) {
  const todayGamesHandler = async (request: { query: unknown }) => {
    const query = request.query as { date?: string }
    return getTodayGames(query.date)
  }

  const gameDetailHandler = async (request: { params: unknown, query: unknown }) => {
    const params = request.params as { gameId: string }
    const query = request.query as { date?: string }
    return getGameById(params.gameId, query.date)
  }

  server.get('/games/today', todayGamesHandler)
  server.get('/v1/games/today', todayGamesHandler)
  server.get('/games/:gameId', gameDetailHandler)
  server.get('/v1/games/:gameId', gameDetailHandler)

  const standingsHandler = async (request: { query: unknown }) => {
    const query = request.query as { date?: string }
    return getTeamStandings(query.date)
  }

  server.get('/standings', standingsHandler)
  server.get('/v1/standings', standingsHandler)
  server.get('/v1/teams/standings', standingsHandler)

  server.get('/debug/source/today', async (request, reply) => {
    if (!canExposeDebugSource()) {
      return reply.status(404).send({
        error: {
          code: 'NOT_FOUND',
          message: 'Not found',
          statusCode: 404
        }
      })
    }

    const query = request.query as { date?: string }
    return getTodayGamesRaw(query.date)
  })

  server.get('/v1/players/search', async (request) => {
    const query = request.query as { q?: string, season?: string }
    const q = query.q?.trim() ?? ''
    if (q.length === 0) {
      return { players: [] }
    }

    return {
      players: searchPlayers(q, query.season == null ? undefined : Number(query.season))
    }
  })

  server.get('/v1/players/:playerId/season', async (request) => {
    const params = request.params as { playerId: string }
    const query = request.query as { season?: string, date?: string }
    const season = query.season == null ? new Date().getFullYear() : Number(query.season)

    return {
      player: getPlayerSeasonRecord(params.playerId, season, query.date)
    }
  })
}
