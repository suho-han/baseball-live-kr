import { backendVersion } from '../version.js'
import { getAlertSnapshot, recordAlert, resetAlertsForTests } from './alerts.js'
import type { AlertEvent, AlertKind } from './alerts.js'

type StatusClass = '1xx' | '2xx' | '3xx' | '4xx' | '5xx' | 'other'

type LatencyStats = {
  count: number
  maxMs: number
  totalMs: number
}

export type MetricsSnapshot = {
  readonly service: 'baseball-live-kr-backend-spike'
  readonly version: string
  readonly generatedAt: string
  readonly process: {
    readonly nodeVersion: string
    readonly pid: number
    readonly uptimeSeconds: number
  }
  readonly counters: {
    readonly requests: {
      readonly total: number
      readonly byStatus: Record<StatusClass, number>
      readonly latencyMs: LatencyStats
    }
    readonly source: {
      readonly success: number
      readonly failure: number
      readonly consecutiveFailures: number
      readonly latencyMs: LatencyStats
    }
    readonly cache: {
      readonly hit: number
      readonly miss: number
      readonly stale: number
    }
    readonly alerts: {
      readonly recorded: number
      readonly sent: number
      readonly failed: number
      readonly suppressed: number
    }
  }
  readonly state: {
    readonly cache: {
      readonly lastStaleAt: string | null
    }
    readonly source: {
      readonly lastFailureAt: string | null
      readonly lastSuccessAt: string | null
    }
    readonly alerts: {
      readonly lastEvent: AlertEvent | null
      readonly webhookConfigured: boolean
    }
  }
}

const SERVICE_NAME = 'baseball-live-kr-backend-spike'
const EMPTY_STATUS_COUNTS: Record<StatusClass, number> = {
  '1xx': 0,
  '2xx': 0,
  '3xx': 0,
  '4xx': 0,
  '5xx': 0,
  other: 0
}

const state = {
  requestTotal: 0,
  requestByStatus: { ...EMPTY_STATUS_COUNTS },
  requestLatency: emptyLatencyStats(),
  sourceSuccess: 0,
  sourceFailure: 0,
  sourceConsecutiveFailures: 0,
  sourceLatency: emptyLatencyStats(),
  cacheHit: 0,
  cacheMiss: 0,
  cacheStale: 0,
  lastStaleAt: null as string | null,
  lastSourceFailureAt: null as string | null,
  lastSourceSuccessAt: null as string | null
}

function emptyLatencyStats(): LatencyStats {
  return { count: 0, maxMs: 0, totalMs: 0 }
}

function recordLatency(stats: LatencyStats, latencyMs: number): void {
  stats.count += 1
  stats.totalMs += latencyMs
  stats.maxMs = Math.max(stats.maxMs, latencyMs)
}

function statusClass(statusCode: number): StatusClass {
  if (statusCode >= 100 && statusCode < 200) {
    return '1xx'
  }

  if (statusCode >= 200 && statusCode < 300) {
    return '2xx'
  }

  if (statusCode >= 300 && statusCode < 400) {
    return '3xx'
  }

  if (statusCode >= 400 && statusCode < 500) {
    return '4xx'
  }

  if (statusCode >= 500 && statusCode < 600) {
    return '5xx'
  }

  return 'other'
}

function envInteger(name: string, fallback: number): number {
  const rawValue = process.env[name]
  if (rawValue === undefined) {
    return fallback
  }

  const value = Number(rawValue)
  return Number.isSafeInteger(value) && value >= 0 ? value : fallback
}

function sourceFailureThreshold(): number {
  return envInteger('KBO_ALERT_SOURCE_FAILURE_THRESHOLD', 3)
}

function cacheStaleThreshold(): number {
  return envInteger('KBO_ALERT_STALE_THRESHOLD', 3)
}

function recordAlertSideEffect(input: {
  readonly kind: AlertKind
  readonly reason: string
  readonly value: number
}): void {
  void recordAlert(input).catch((error) => {
    console.warn(JSON.stringify({
      event: 'operational_alert_side_effect_failed',
      message: error instanceof Error ? error.message : 'unknown alert failure'
    }))
  })
}

export function recordHttpRequest(input: {
  readonly statusCode: number
  readonly latencyMs: number
}): void {
  state.requestTotal += 1
  state.requestByStatus[statusClass(input.statusCode)] += 1
  recordLatency(state.requestLatency, input.latencyMs)
}

export function recordCacheHit(): void {
  state.cacheHit += 1
}

export function recordCacheMiss(): void {
  state.cacheMiss += 1
}

export function recordCacheStale(): void {
  state.cacheStale += 1
  state.lastStaleAt = new Date().toISOString()
  if (state.cacheStale >= cacheStaleThreshold()) {
    recordAlertSideEffect({
      kind: 'cache_stale_threshold',
      reason: 'stale cache returned after source failure',
      value: state.cacheStale
    })
  }
}

export function recordSourceSuccess(latencyMs: number): void {
  state.sourceSuccess += 1
  state.sourceConsecutiveFailures = 0
  state.lastSourceSuccessAt = new Date().toISOString()
  recordLatency(state.sourceLatency, latencyMs)
}

export function recordSourceFailure(): void {
  state.sourceFailure += 1
  state.sourceConsecutiveFailures += 1
  state.lastSourceFailureAt = new Date().toISOString()
  if (state.sourceConsecutiveFailures >= sourceFailureThreshold()) {
    recordAlertSideEffect({
      kind: 'source_failure_threshold',
      reason: 'KBO source failure threshold reached',
      value: state.sourceConsecutiveFailures
    })
  }
}

export function getMetricsSnapshot(): MetricsSnapshot {
  const alerts = getAlertSnapshot()

  return {
    service: SERVICE_NAME,
    version: backendVersion,
    generatedAt: new Date().toISOString(),
    process: {
      nodeVersion: process.version,
      pid: process.pid,
      uptimeSeconds: process.uptime()
    },
    counters: {
      requests: {
        total: state.requestTotal,
        byStatus: { ...state.requestByStatus },
        latencyMs: { ...state.requestLatency }
      },
      source: {
        success: state.sourceSuccess,
        failure: state.sourceFailure,
        consecutiveFailures: state.sourceConsecutiveFailures,
        latencyMs: { ...state.sourceLatency }
      },
      cache: {
        hit: state.cacheHit,
        miss: state.cacheMiss,
        stale: state.cacheStale
      },
      alerts: {
        recorded: alerts.counters.recorded,
        sent: alerts.counters.sent,
        failed: alerts.counters.failed,
        suppressed: alerts.counters.suppressed
      }
    },
    state: {
      cache: {
        lastStaleAt: state.lastStaleAt
      },
      source: {
        lastFailureAt: state.lastSourceFailureAt,
        lastSuccessAt: state.lastSourceSuccessAt
      },
      alerts: {
        lastEvent: alerts.state.lastEvent,
        webhookConfigured: alerts.state.webhookConfigured
      }
    }
  }
}

export function resetObservabilityForTests(): void {
  state.requestTotal = 0
  state.requestByStatus = { ...EMPTY_STATUS_COUNTS }
  state.requestLatency = emptyLatencyStats()
  state.sourceSuccess = 0
  state.sourceFailure = 0
  state.sourceConsecutiveFailures = 0
  state.sourceLatency = emptyLatencyStats()
  state.cacheHit = 0
  state.cacheMiss = 0
  state.cacheStale = 0
  state.lastStaleAt = null
  state.lastSourceFailureAt = null
  state.lastSourceSuccessAt = null
  resetAlertsForTests()
}
