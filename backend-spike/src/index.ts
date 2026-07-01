import { buildServer } from './server.js'
import { backendVersion } from './version.js'

const port = Number(process.env.PORT ?? 17361)
const host = process.env.HOST ?? '0.0.0.0'

const server = buildServer()

try {
  await server.listen({ port, host })
  server.log.info({ port, host, version: backendVersion }, 'backend-spike server started')
} catch (error) {
  const startError = error instanceof Error ? error : new Error(String(error))
  server.log.error(startError, 'failed to start backend-spike server')
  process.exit(1)
}
