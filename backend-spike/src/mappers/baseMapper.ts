import { RawKboGame } from '../dto/kboGameList.dto.js'

function toBool(value: unknown): boolean {
  if (value === null || value === undefined || value === '') return false
  const n = Number(value)
  return Number.isFinite(n) && n > 0
}

export function mapBases(raw: RawKboGame) {
  return {
    first: toBool(raw.B1_BAT_ORDER_NO),
    second: toBool(raw.B2_BAT_ORDER_NO),
    third: toBool(raw.B3_BAT_ORDER_NO)
  }
}
