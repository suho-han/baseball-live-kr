import { buildKboHeaders } from '../config/kboHeaders.js'
import { rawKboGameDateResponseSchema } from '../dto/kboGameDate.dto.js'
import { rawKboGameListResponseSchema } from '../dto/kboGameList.dto.js'
import { rawKboScheduleListResponseSchema } from '../dto/kboScheduleList.dto.js'

type KboEndpoint = 'GetKboGameDate' | 'GetKboGameList' | 'GetScheduleList' | 'TeamRankDaily'

const BASE_URL = 'https://www.koreabaseball.com/ws'

export class KboSourceError extends Error {
  readonly endpoint: KboEndpoint
  readonly statusCode?: number

  constructor(endpoint: KboEndpoint, message: string, options: { statusCode?: number, cause?: unknown } = {}) {
    super(`${endpoint}: ${message}`, { cause: options.cause })
    this.name = 'KboSourceError'
    this.endpoint = endpoint
    this.statusCode = options.statusCode
  }
}

async function postForm<T>(endpoint: KboEndpoint, path: string, payload: Record<string, string>, referer?: string): Promise<T> {
  const response = await fetch(`${BASE_URL}/${path}`, {
    method: 'POST',
    headers: buildKboHeaders(referer),
    body: new URLSearchParams(payload)
  })

  const text = await response.text()
  const trimmed = text.trim()

  if (!response.ok) {
    throw new KboSourceError(endpoint, `HTTP ${response.status}`, {
      statusCode: response.status
    })
  }

  if (trimmed.startsWith('<!DOCTYPE html') || trimmed.startsWith('<html') || trimmed.includes('<title>에러')) {
    throw new KboSourceError(endpoint, 'returned HTML error page')
  }

  try {
    return JSON.parse(trimmed) as T
  } catch (error) {
    throw new KboSourceError(endpoint, 'returned invalid JSON', { cause: error })
  }
}

export async function fetchKboGameDate(date: string) {
  const json = await postForm('GetKboGameDate', 'Main.asmx/GetKboGameDate', {
    leId: '1',
    srId: '0,1,3,4,5,7,8,9',
    date
  })

  try {
    return rawKboGameDateResponseSchema.parse(json)
  } catch (error) {
    throw new KboSourceError('GetKboGameDate', 'response did not match expected schema', { cause: error })
  }
}

export async function fetchKboGameList(date: string) {
  const json = await postForm('GetKboGameList', 'Main.asmx/GetKboGameList', {
    leId: '1',
    srId: '0,1,3,4,5,7,8,9',
    date
  })

  try {
    return rawKboGameListResponseSchema.parse(json)
  } catch (error) {
    throw new KboSourceError('GetKboGameList', 'response did not match expected schema', { cause: error })
  }
}

export async function fetchKboScheduleList(seasonId: string, gameMonth: string) {
  const json = await postForm('GetScheduleList', 'Schedule.asmx/GetScheduleList', {
    leId: '1',
    srIdList: '0,9,6',
    seasonId,
    gameMonth,
    teamId: ''
  }, 'https://www.koreabaseball.com/Schedule/Schedule.aspx')

  try {
    return rawKboScheduleListResponseSchema.parse(json)
  } catch (error) {
    throw new KboSourceError('GetScheduleList', 'response did not match expected schema', { cause: error })
  }
}

export async function fetchKboTeamRankDailyPage(date: string) {
  const url = new URL('https://www.koreabaseball.com/Record/TeamRank/TeamRankDaily.aspx')
  url.searchParams.set('date', date)

  const response = await fetch(url, {
    headers: {
      'User-Agent': 'Mozilla/5.0',
      Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      Referer: 'https://www.koreabaseball.com/Record/TeamRank/TeamRankDaily.aspx'
    }
  })

  if (!response.ok) {
    throw new KboSourceError('TeamRankDaily', `HTTP ${response.status}`, {
      statusCode: response.status
    })
  }

  const text = await response.text()
  if (text.trim().length === 0 || text.includes('<title>에러')) {
    throw new KboSourceError('TeamRankDaily', 'returned invalid HTML')
  }

  return text
}
