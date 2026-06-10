import type { FastifyInstance } from 'fastify'

import { getGameById, getTodayGames, getTodayGamesRaw } from '../services/gameService.js'

export function registerGamesRoutes(server: FastifyInstance) {
  server.get('/games/today', async (request) => {
    const query = request.query as { date?: string }
    return getTodayGames(query.date)
  })

  server.get('/games/:gameId', async (request) => {
    const params = request.params as { gameId: string }
    const query = request.query as { date?: string }
    return getGameById(params.gameId, query.date)
  })

  server.get('/debug/source/today', async (request) => {
    const query = request.query as { date?: string }
    return getTodayGamesRaw(query.date)
  })
}
