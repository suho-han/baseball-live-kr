import { createServer } from 'node:http'
import { writeFileSync } from 'node:fs'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('../src/clients/kboClient.js', () => ({
  fetchKboGameDate: vi.fn(),
  fetchKboGameList: vi.fn(),
  fetchKboLiveTextView: vi.fn(),
  fetchKboScheduleList: vi.fn(),
  fetchKboTeamRankDailyPage: vi.fn()
}))

import { getMetricsSnapshot, resetObservabilityForTests } from '../src/observability/metrics.js'
import { getTodayGames } from '../src/services/gameService.js'
import {
  cleanupGameServiceTestState,
  mockGameDate,
  resetGameServiceTestState,
  TEST_INPUT_DATE
} from './gameServiceTestSupport.js'

function listen(server: ReturnType<typeof createServer>): Promise<number> {
  return new Promise((resolve, reject) => {
    server.once('error', reject)
    server.listen(0, '127.0.0.1', () => {
      const address = server.address()
      if (typeof address === 'object' && address !== null) {
        resolve(address.port)
        return
      }

      reject(new Error('test server did not bind a TCP port'))
    })
  })
}

function close(server: ReturnType<typeof createServer>): Promise<void> {
  return new Promise((resolve, reject) => {
    server.close((error) => {
      if (error instanceof Error) {
        reject(error)
        return
      }

      resolve()
    })
  })
}

describe('observability alerts', () => {
  const tempDirs: string[] = []

  beforeEach(() => {
    resetGameServiceTestState()
    resetObservabilityForTests()
    process.env.KBO_CACHE_TTL_GAME_IDLE_SEC = '0'
    process.env.KBO_CACHE_STALE_IF_ERROR_SEC = '600'
    process.env.KBO_ALERT_SOURCE_FAILURE_THRESHOLD = '1'
    process.env.KBO_ALERT_COOLDOWN_SEC = '60'
  })

  afterEach(() => {
    cleanupGameServiceTestState(tempDirs)
    resetObservabilityForTests()
    delete process.env.KBO_ALERT_SOURCE_FAILURE_THRESHOLD
    delete process.env.KBO_ALERT_COOLDOWN_SEC
    delete process.env.KBO_ALERT_WEBHOOK_URL
    delete process.env.O1_ALERT_CAPTURE_PATH
  })

  it('records stale cache and source failure alerts without webhook secrets', async () => {
    const cached = await getTodayGames(TEST_INPUT_DATE)
    mockGameDate.mockRejectedValue(new Error('source down'))

    const stale = await getTodayGames(TEST_INPUT_DATE)
    const snapshot = getMetricsSnapshot()

    expect(stale).toEqual(cached)
    expect(snapshot.counters.source.failure).toBe(1)
    expect(snapshot.counters.cache.stale).toBe(1)
    expect(snapshot.counters.alerts.recorded).toBe(1)
    expect(snapshot.counters.alerts.sent).toBe(0)
    expect(snapshot.state.alerts.lastEvent).toMatchObject({
      kind: 'source_failure_threshold',
      delivery: 'recorded'
    })
  })

  it('suppresses duplicate alert storms during the cooldown window', async () => {
    await getTodayGames(TEST_INPUT_DATE)
    mockGameDate.mockRejectedValue(new Error('source down'))

    await getTodayGames(TEST_INPUT_DATE)
    await getTodayGames(TEST_INPUT_DATE)
    const snapshot = getMetricsSnapshot()

    expect(snapshot.counters.alerts.recorded).toBe(1)
    expect(snapshot.counters.alerts.suppressed).toBe(1)
  })

  it('sends a concise webhook payload when a local alert sink is configured', async () => {
    const payloads: string[] = []
    const sink = createServer((request, response) => {
      request.setEncoding('utf8')
      request.on('data', (chunk) => {
        payloads.push(chunk)
      })
      request.on('end', () => {
        response.writeHead(204)
        response.end()
      })
    })
    const port = await listen(sink)
    process.env.KBO_ALERT_WEBHOOK_URL = `http://127.0.0.1:${port}/alert`

    await getTodayGames(TEST_INPUT_DATE)
    mockGameDate.mockRejectedValue(new Error('source down'))
    await getTodayGames(TEST_INPUT_DATE)
    await close(sink)

    const body = payloads.join('')
    if (process.env.O1_ALERT_CAPTURE_PATH !== undefined) {
      writeFileSync(process.env.O1_ALERT_CAPTURE_PATH, `${body}\n`)
    }
    expect(JSON.parse(body)).toMatchObject({
      service: 'baseball-live-kr-backend-spike',
      kind: 'source_failure_threshold',
      severity: 'warning'
    })
    expect(body).not.toContain('KBO_ALERT_WEBHOOK_URL')
    expect(body).not.toContain(process.env.KBO_ALERT_WEBHOOK_URL)
  })
})
