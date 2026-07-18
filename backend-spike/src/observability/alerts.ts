import { backendVersion } from '../version.js'

export type AlertKind = 'cache_stale_threshold' | 'source_failure_threshold'
export type AlertDelivery = 'failed' | 'recorded' | 'sent' | 'suppressed'
type AlertSeverity = 'warning'

export type AlertEvent = {
  readonly at: string
  readonly delivery: AlertDelivery
  readonly kind: AlertKind
  readonly reason: string
  readonly severity: AlertSeverity
  readonly value: number
}

export type AlertSnapshot = {
  readonly counters: {
    readonly recorded: number
    readonly sent: number
    readonly failed: number
    readonly suppressed: number
  }
  readonly state: {
    readonly lastEvent: AlertEvent | null
    readonly webhookConfigured: boolean
  }
}

const SERVICE_NAME = 'baseball-live-kr-backend-spike'

const state = {
  recorded: 0,
  sent: 0,
  failed: 0,
  suppressed: 0,
  lastEvent: null as AlertEvent | null,
  inFlightByKind: new Set<AlertKind>(),
  lastSentAtByKind: new Map<AlertKind, number>()
}

function envInteger(name: string, fallback: number): number {
  const rawValue = process.env[name]
  if (rawValue === undefined) {
    return fallback
  }

  const value = Number(rawValue)
  return Number.isSafeInteger(value) && value >= 0 ? value : fallback
}

function alertCooldownMs(): number {
  return envInteger('KBO_ALERT_COOLDOWN_SEC', 300) * 1000
}

function webhookUrl(): URL | null {
  const rawValue = process.env.KBO_ALERT_WEBHOOK_URL
  if (rawValue === undefined || rawValue.trim().length === 0) {
    return null
  }

  try {
    return new URL(rawValue)
  } catch (error) {
    if (error instanceof TypeError) {
      return null
    }

    throw error
  }
}

function shouldSuppress(kind: AlertKind, now: number): boolean {
  if (state.inFlightByKind.has(kind)) {
    return true
  }

  const lastSentAt = state.lastSentAtByKind.get(kind)
  return lastSentAt !== undefined && now - lastSentAt < alertCooldownMs()
}

async function deliverAlert(event: AlertEvent): Promise<AlertDelivery> {
  const url = webhookUrl()
  if (url === null) {
    console.warn(JSON.stringify({ event: 'operational_alert', ...event }))
    return 'recorded'
  }

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        service: SERVICE_NAME,
        version: backendVersion,
        kind: event.kind,
        severity: event.severity,
        reason: event.reason,
        value: event.value,
        at: event.at
      }),
      signal: AbortSignal.timeout(1_000)
    })

    return response.ok ? 'sent' : 'failed'
  } catch (error) {
    if (error instanceof Error) {
      console.warn(JSON.stringify({
        event: 'operational_alert_delivery_failed',
        kind: event.kind,
        message: error.message
      }))
      return 'failed'
    }

    throw error
  }
}

export async function recordAlert(input: {
  readonly kind: AlertKind
  readonly reason: string
  readonly value: number
}): Promise<void> {
  const now = Date.now()
  const at = new Date(now).toISOString()
  if (shouldSuppress(input.kind, now)) {
    state.suppressed += 1
    state.lastEvent = {
      at,
      delivery: 'suppressed',
      kind: input.kind,
      reason: input.reason,
      severity: 'warning',
      value: input.value
    }
    return
  }

  const pendingEvent: AlertEvent = {
    at,
    delivery: 'recorded',
    kind: input.kind,
    reason: input.reason,
    severity: 'warning',
    value: input.value
  }
  state.inFlightByKind.add(input.kind)
  let delivery: AlertDelivery
  try {
    delivery = await deliverAlert(pendingEvent)
  } finally {
    state.inFlightByKind.delete(input.kind)
  }
  const event = { ...pendingEvent, delivery }

  state.recorded += 1
  if (delivery === 'sent') {
    state.sent += 1
  }

  if (delivery === 'failed') {
    state.failed += 1
  }

  if (delivery !== 'failed') {
    state.lastSentAtByKind.set(input.kind, now)
  }
  state.lastEvent = event
}

export function getAlertSnapshot(): AlertSnapshot {
  return {
    counters: {
      recorded: state.recorded,
      sent: state.sent,
      failed: state.failed,
      suppressed: state.suppressed
    },
    state: {
      lastEvent: state.lastEvent,
      webhookConfigured: webhookUrl() !== null
    }
  }
}

export function resetAlertsForTests(): void {
  state.recorded = 0
  state.sent = 0
  state.failed = 0
  state.suppressed = 0
  state.lastEvent = null
  state.inFlightByKind.clear()
  state.lastSentAtByKind.clear()
}
