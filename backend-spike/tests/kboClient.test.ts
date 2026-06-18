import { mkdtempSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import { fetchKboGameDate, fetchKboGameList, KboSourceError } from '../src/clients/kboClient.js'
import { closeDatabase } from '../src/db/database.js'
import { countRawSources } from '../src/repositories/rawSourceRepository.js'
import { TEST_DATE } from './testConfig.js'

describe('kboClient', () => {
  const tempDirs: string[] = []

  beforeEach(() => {
    process.env.KBO_DB_DISABLED = '1'
  })

  afterEach(() => {
    vi.unstubAllGlobals()
    closeDatabase()
    for (const dir of tempDirs.splice(0)) {
      rmSync(dir, { recursive: true, force: true })
    }
    delete process.env.KBO_DB_DISABLED
    delete process.env.KBO_DB_ENABLED
    delete process.env.KBO_DB_PATH
  })

  it('posts form data and parses a valid game date response', async () => {
    const fetchMock = vi.fn(async (_url: string, init: RequestInit) => {
      expect(init.method).toBe('POST')
      expect(String(init.body)).toContain(`date=${TEST_DATE}`)

      return new Response(JSON.stringify({
        BEFORE_G_DT: '20260612',
        NOW_G_DT: TEST_DATE,
        NOW_G_DT_TEXT: '06.13(토)',
        AFTER_G_DT: '20260614',
        code: '100',
        msg: 'OK'
      }), { status: 200 })
    })
    vi.stubGlobal('fetch', fetchMock)

    const response = await fetchKboGameDate(TEST_DATE)

    expect(response.NOW_G_DT).toBe(TEST_DATE)
    expect(fetchMock).toHaveBeenCalledOnce()
  })

  it('stores successful source responses when DB persistence is enabled', async () => {
    delete process.env.KBO_DB_DISABLED
    process.env.KBO_DB_ENABLED = '1'
    const dir = mkdtempSync(join(tmpdir(), 'kbo-live-client-db-'))
    tempDirs.push(dir)
    process.env.KBO_DB_PATH = join(dir, 'test.sqlite')
    vi.stubGlobal('fetch', vi.fn(async () => new Response(JSON.stringify({
      BEFORE_G_DT: '20260612',
      NOW_G_DT: TEST_DATE,
      NOW_G_DT_TEXT: '06.13(토)',
      AFTER_G_DT: '20260614',
      code: '100',
      msg: 'OK'
    }), { status: 200 })))

    await fetchKboGameDate(TEST_DATE)

    expect(countRawSources()).toBe(1)
  })

  it('wraps non-2xx source responses with endpoint context', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => new Response('{}', { status: 503 })))

    await expect(fetchKboGameList(TEST_DATE)).rejects.toMatchObject({
      name: 'KboSourceError',
      endpoint: 'GetKboGameList',
      statusCode: 503,
      message: expect.stringContaining('HTTP 503')
    })
  })

  it('rejects HTML error pages before JSON parsing', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => new Response('<html><title>에러</title></html>', { status: 200 })))

    await expect(fetchKboGameList(TEST_DATE)).rejects.toThrow(KboSourceError)
    await expect(fetchKboGameList(TEST_DATE)).rejects.toThrow(/HTML error page/)
  })

  it('wraps malformed JSON responses', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => new Response('{not-json', { status: 200 })))

    await expect(fetchKboGameList(TEST_DATE)).rejects.toMatchObject({
      endpoint: 'GetKboGameList',
      message: expect.stringContaining('invalid JSON')
    })
  })

  it('wraps schema mismatches after parsing', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => new Response(JSON.stringify({ game: 'not-array' }), { status: 200 })))

    await expect(fetchKboGameList(TEST_DATE)).rejects.toMatchObject({
      endpoint: 'GetKboGameList',
      message: expect.stringContaining('expected schema')
    })
  })
})
