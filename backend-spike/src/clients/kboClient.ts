import { buildKboHeaders } from '../config/kboHeaders.js'
import { rawKboGameDateResponseSchema } from '../dto/kboGameDate.dto.js'
import { rawKboGameListResponseSchema } from '../dto/kboGameList.dto.js'
import { rawKboScheduleListResponseSchema } from '../dto/kboScheduleList.dto.js'

type KboEndpoint = 'GetKboGameDate' | 'GetKboGameList' | 'GetScheduleList'

const BASE_URL = 'https://www.koreabaseball.com/ws'

async function postForm<T>(endpoint: KboEndpoint, path: string, payload: Record<string, string>, referer?: string): Promise<T> {
  const response = await fetch(`${BASE_URL}/${path}`, {
    method: 'POST',
    headers: buildKboHeaders(referer),
    body: new URLSearchParams(payload)
  })

  const text = await response.text()
  const trimmed = text.trim()

  if (trimmed.startsWith('<!DOCTYPE html') || trimmed.startsWith('<html') || trimmed.includes('<title>에러')) {
    throw new Error(`${endpoint} returned HTML error page`)
  }

  return JSON.parse(trimmed) as T
}

export async function fetchKboGameDate(date: string) {
  const json = await postForm('GetKboGameDate', 'Main.asmx/GetKboGameDate', {
    leId: '1',
    srId: '0,1,3,4,5,7,8,9',
    date
  })

  return rawKboGameDateResponseSchema.parse(json)
}

export async function fetchKboGameList(date: string) {
  const json = await postForm('GetKboGameList', 'Main.asmx/GetKboGameList', {
    leId: '1',
    srId: '0,1,3,4,5,7,8,9',
    date
  })

  return rawKboGameListResponseSchema.parse(json)
}

export async function fetchKboScheduleList(seasonId: string, gameMonth: string) {
  const json = await postForm('GetScheduleList', 'Schedule.asmx/GetScheduleList', {
    leId: '1',
    srIdList: '0,9,6',
    seasonId,
    gameMonth,
    teamId: ''
  }, 'https://www.koreabaseball.com/Schedule/Schedule.aspx')

  return rawKboScheduleListResponseSchema.parse(json)
}
