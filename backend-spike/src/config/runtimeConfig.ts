export type RuntimeConfigError = {
  readonly key: string
  readonly message: string
}

export type RuntimeConfigValidation = {
  readonly ok: boolean
  readonly errors: readonly RuntimeConfigError[]
}

type RuntimeNumberCheck = {
  readonly value: number
  readonly error: RuntimeConfigError | null
}

const DEFAULT_KBO_SOURCE_TIMEOUT_MS = 5_000
const DEFAULT_KBO_CACHE_TTL_GAME_IDLE_SEC = 60
const DEFAULT_KBO_CACHE_TTL_GAME_LIVE_SEC = 5
const DEFAULT_KBO_CACHE_STALE_IF_ERROR_SEC = 600
const DEFAULT_KBO_CACHE_TTL_STANDINGS_SEC = 600

function readNonNegativeIntegerEnv(key: string, fallback: number): RuntimeNumberCheck {
  const rawValue = process.env[key]
  if (rawValue === undefined) {
    return { value: fallback, error: null }
  }

  if (!/^\d+$/.test(rawValue)) {
    return {
      value: fallback,
      error: { key, message: 'must be a non-negative integer' }
    }
  }

  const value = Number(rawValue)
  if (!Number.isSafeInteger(value)) {
    return {
      value: fallback,
      error: { key, message: 'must be a non-negative integer' }
    }
  }

  return { value, error: null }
}

function readRuntimeNumberChecks(): readonly RuntimeNumberCheck[] {
  return [
    readNonNegativeIntegerEnv('KBO_SOURCE_TIMEOUT_MS', DEFAULT_KBO_SOURCE_TIMEOUT_MS),
    readNonNegativeIntegerEnv('KBO_CACHE_TTL_GAME_IDLE_SEC', DEFAULT_KBO_CACHE_TTL_GAME_IDLE_SEC),
    readNonNegativeIntegerEnv('KBO_CACHE_TTL_GAME_LIVE_SEC', DEFAULT_KBO_CACHE_TTL_GAME_LIVE_SEC),
    readNonNegativeIntegerEnv('KBO_CACHE_STALE_IF_ERROR_SEC', DEFAULT_KBO_CACHE_STALE_IF_ERROR_SEC),
    readNonNegativeIntegerEnv('KBO_CACHE_TTL_STANDINGS_SEC', DEFAULT_KBO_CACHE_TTL_STANDINGS_SEC)
  ]
}

export function validateRuntimeConfig(): RuntimeConfigValidation {
  const errors = readRuntimeNumberChecks()
    .map((check) => check.error)
    .filter((error): error is RuntimeConfigError => error !== null)

  return {
    ok: errors.length === 0,
    errors
  }
}

export function kboSourceTimeoutMs(): number {
  return readNonNegativeIntegerEnv('KBO_SOURCE_TIMEOUT_MS', DEFAULT_KBO_SOURCE_TIMEOUT_MS).value
}

export function isProductionRuntime(): boolean {
  return process.env.NODE_ENV === 'production'
}

export function canExposeDebugSource(): boolean {
  return !isProductionRuntime() || process.env.BASEBALL_LIVE_KR_DEBUG_SOURCE_ENABLED === '1'
}

export function canUseTestLiveGame(): boolean {
  return !isProductionRuntime() && process.env.KBO_USE_TEST_LIVE_GAME === '1'
}
