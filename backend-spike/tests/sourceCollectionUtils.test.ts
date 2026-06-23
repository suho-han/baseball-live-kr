import { mkdirSync, mkdtempSync, symlinkSync } from 'node:fs'
import { tmpdir } from 'node:os'
import path from 'node:path'

import { describe, expect, it, vi } from 'vitest'

import { collectRecordTableMetadata, fetchTextWithTimeout, requireKoreanPlayerNames, resolveArtifactOutDir } from '../src/records/sourceCollectionUtils.js'

describe('sourceCollectionUtils', () => {
  it('passes an AbortSignal to fetch for timeout protection', async () => {
    let receivedSignal: AbortSignal | undefined
    const fetchImpl = async (_url: string | URL, init?: RequestInit) => {
      receivedSignal = init?.signal ?? undefined
      return new Response('ok', { status: 200 })
    }

    const body = await fetchTextWithTimeout('https://example.test/source', {}, 1000, fetchImpl)

    expect(body.statusCode).toBe(200)
    expect(body.body).toBe('ok')
    expect(receivedSignal).toBeInstanceOf(AbortSignal)
  })

  it('counts tables, rows, and header labels from a record table', () => {
    const metadata = collectRecordTableMetadata(`
      <table>
        <thead><tr><th>순위</th><th>팀명</th><th>AVG</th></tr></thead>
        <tbody><tr><td>1</td><td>LG</td><td>0.300</td></tr><tr><td>2</td><td>KT</td><td>0.290</td></tr></tbody>
      </table>`)

    expect(metadata).toEqual({
      tableCount: 1,
      rowCount: 2,
      columns: ['순위', '팀명', 'AVG']
    })
  })

  it('fails instead of falling back to English names when Korean names are missing', () => {
    expect(() => requireKoreanPlayerNames([
      { playerId: '66606', playerName: 'CHOI Won Jun' },
      { playerId: '54529', playerName: 'REYES Victor' }
    ], new Map([['66606', '최원준']]), 'batting')).toThrow(/Missing Korean player names for batting: 54529/)
  })

  it('retries transient fetch failures before succeeding', async () => {
    let attempts = 0
    const fetchImpl = async () => {
      attempts += 1
      if (attempts < 3) {
        throw new Error('temporary network failure')
      }
      return new Response('ok', { status: 200 })
    }

    const body = await fetchTextWithTimeout('https://example.test/retry', {}, { timeoutMs: 1000, retries: 2, retryDelayMs: 0 }, fetchImpl)

    expect(body.body).toBe('ok')
    expect(attempts).toBe(3)
  })

  it('aborts a hung fetch when the timeout elapses', async () => {
    vi.useFakeTimers()
    try {
      const promise = fetchTextWithTimeout('https://example.test/hung', {}, { timeoutMs: 10, retries: 0 }, (_url: string | URL, init?: RequestInit) => new Promise<Response>((_resolve, reject) => {
        init?.signal?.addEventListener('abort', () => reject(new Error('aborted')))
      }))
      const expectation = expect(promise).rejects.toThrow(/aborted/)

      await vi.advanceTimersByTimeAsync(10)
      await expectation
    } finally {
      vi.useRealTimers()
    }
  })

  it('rejects artifact output paths outside the artifact root', () => {
    expect(() => resolveArtifactOutDir('/repo/backend-spike/artifacts/source-collection', 'safe-run', '/tmp/outside')).toThrow(/outside artifact root/)
    expect(() => resolveArtifactOutDir('/repo/backend-spike/artifacts/source-collection', '../bad-run')).toThrow(/Invalid run id/)
    expect(resolveArtifactOutDir('/repo/backend-spike/artifacts/source-collection', 'safe-run')).toBe('/repo/backend-spike/artifacts/source-collection/safe-run')
  })

  it('rejects an artifact output directory that escapes through an existing symlink', () => {
    const temp = mkdtempSync(path.join(tmpdir(), 'kbo-artifact-root-'))
    const root = path.join(temp, 'artifacts')
    const outside = path.join(temp, 'outside')
    mkdirSync(root)
    mkdirSync(outside)
    symlinkSync(outside, path.join(root, 'escape'))

    expect(() => resolveArtifactOutDir(root, 'safe-run', path.join(root, 'escape', 'run'))).toThrow(/outside artifact root/)
  })

  it('retries transient HTTP status responses before returning success', async () => {
    let attempts = 0
    const fetchImpl = async () => {
      attempts += 1
      if (attempts < 3) {
        return new Response('busy', { status: 503 })
      }
      return new Response('ok', { status: 200 })
    }

    const body = await fetchTextWithTimeout('https://example.test/http-retry', {}, { timeoutMs: 1000, retries: 2, retryDelayMs: 0 }, fetchImpl)

    expect(body.body).toBe('ok')
    expect(body.statusCode).toBe(200)
    expect(attempts).toBe(3)
  })

  it('does not retry non-transient HTTP status responses', async () => {
    let attempts = 0
    const fetchImpl = async () => {
      attempts += 1
      return new Response('missing', { status: 404 })
    }

    const body = await fetchTextWithTimeout('https://example.test/not-found', {}, { timeoutMs: 1000, retries: 2, retryDelayMs: 0 }, fetchImpl)

    expect(body.statusCode).toBe(404)
    expect(attempts).toBe(1)
  })
})
