import type { FastifyInstance } from 'fastify'

export function registerHealthRoutes(server: FastifyInstance) {
  server.get('/health', async () => {
    return {
      ok: true,
      source: 'kbo-official-spike',
      now: new Date().toISOString()
    }
  })
}
