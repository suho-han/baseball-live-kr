import Fastify from 'fastify'

import { registerGamesRoutes } from './routes/games.js'
import { registerHealthRoutes } from './routes/health.js'

export function buildServer() {
  const server = Fastify({
    logger: {
      transport: process.env.NODE_ENV === 'production'
        ? undefined
        : {
            target: 'pino-pretty',
            options: {
              translateTime: 'SYS:standard',
              ignore: 'pid,hostname'
            }
          }
    }
  })

  registerHealthRoutes(server)
  registerGamesRoutes(server)

  return server
}
