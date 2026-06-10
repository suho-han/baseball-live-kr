import { RawKboGame } from '../dto/kboGameList.dto.js'

export function mapStatus(raw: RawKboGame): 'scheduled' | 'live' | 'final' | 'delayed' | 'cancelled' | 'unknown' {
  const state = String(raw.GAME_STATE_SC ?? '').trim()
  const inning = raw.GAME_INN_NO

  if (state === '1' && (inning === null || inning === undefined || inning === '')) {
    return 'scheduled'
  }

  if (state === '1' || state === '2') {
    return 'live'
  }

  if (state === '3' || state === '4') {
    return 'final'
  }

  if (state === '5') {
    return 'cancelled'
  }

  if (state === '6' || state === '7') {
    return 'delayed'
  }

  return 'unknown'
}
