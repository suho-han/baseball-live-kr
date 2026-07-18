import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify'

import { getMetricsSnapshot } from '../observability/metrics.js'

function metricsEnabled(): boolean {
  return process.env.NODE_ENV !== 'production' || process.env.BASEBALL_LIVE_KR_METRICS_ENABLED === '1'
}

function notFoundPayload() {
  return {
    error: {
      code: 'NOT_FOUND',
      message: 'Not found',
      statusCode: 404
    }
  }
}

export function registerMetricsRoutes(server: FastifyInstance): void {
  const metricsHandler = async (_request: FastifyRequest, reply: FastifyReply) => {
    if (!metricsEnabled()) {
      reply.status(404)
      return notFoundPayload()
    }

    return getMetricsSnapshot()
  }

  server.get('/metrics', metricsHandler)
  server.get('/v1/metrics', metricsHandler)
}
