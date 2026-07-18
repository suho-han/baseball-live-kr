import Fastify from 'fastify'
import type { FastifyRequest } from 'fastify'

import { recordHttpRequest } from './observability/metrics.js'
import { registerGamesRoutes } from './routes/games.js'
import { registerHealthRoutes } from './routes/health.js'
import { registerMetricsRoutes } from './routes/metrics.js'
import { KboDateInputError } from './utils/date.js'

type ApiErrorCode = 'INVALID_DATE' | 'INTERNAL_ERROR'

function apiError(code: ApiErrorCode, message: string, statusCode: number) {
  return {
    error: {
      code,
      message,
      statusCode
    }
  }
}

export function buildServer() {
  const requestStartTimes = new WeakMap<FastifyRequest, bigint>()
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

  server.addHook('onRequest', async (request) => {
    requestStartTimes.set(request, process.hrtime.bigint())
  })

  server.addHook('onResponse', async (request, reply) => {
    const startedAt = requestStartTimes.get(request)
    const latencyMs = startedAt === undefined
      ? reply.elapsedTime
      : Number(process.hrtime.bigint() - startedAt) / 1_000_000
    const route = request.routeOptions.url ?? 'unmatched'

    recordHttpRequest({
      statusCode: reply.statusCode,
      latencyMs
    })
    request.log.info({
      request: {
        method: request.method,
        route,
        statusCode: reply.statusCode,
        latencyMs
      }
    }, 'request observability')
  })

  registerHealthRoutes(server)
  registerGamesRoutes(server)
  registerMetricsRoutes(server)

  server.setErrorHandler((error, request, reply) => {
    if (error instanceof KboDateInputError) {
      request.log.warn({ err: error }, 'invalid KBO date input')
      void reply.status(400).send(apiError('INVALID_DATE', error.message, 400))
      return
    }

    request.log.error({ err: error }, 'request failed')
    void reply.status(500).send(apiError(
      'INTERNAL_ERROR',
      'Internal server error',
      500
    ))
  })

  return server
}
