import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify'

import { validateRuntimeConfig } from '../config/runtimeConfig.js'
import { backendVersion } from '../version.js'

function healthPayload() {
  return {
    ok: true,
    source: 'kbo-official-spike',
    version: backendVersion,
    now: new Date().toISOString()
  }
}

function readinessPayload() {
  const config = validateRuntimeConfig()

  return {
    ok: config.ok,
    source: 'kbo-official-spike',
    version: backendVersion,
    checks: {
      config
    },
    now: new Date().toISOString()
  }
}

export function registerHealthRoutes(server: FastifyInstance) {
  server.get('/health', async () => {
    return healthPayload()
  })

  server.get('/v1/health', async () => {
    return healthPayload()
  })

  const readinessHandler = async (_request: FastifyRequest, reply: FastifyReply) => {
    const payload = readinessPayload()
    if (!payload.ok) {
      reply.status(503)
    }

    return payload
  }

  server.get('/ready', readinessHandler)
  server.get('/v1/ready', readinessHandler)
}
