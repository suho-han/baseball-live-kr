import { buildServer } from './server.js'

const port = Number(process.env.PORT ?? 3000)
const host = process.env.HOST ?? '0.0.0.0'

const server = buildServer()

try {
  await server.listen({ port, host })
  server.log.info({ port, host }, 'backend-spike server started')
} catch (error) {
  server.log.error(error, 'failed to start backend-spike server')
  process.exit(1)
}
