import { createHash, randomUUID } from 'node:crypto'
import type { DatabaseSync } from 'node:sqlite'

import { getDatabase, isDatabaseDisabled } from '../db/database.js'

export interface RawSourceInput {
  source: string
  endpoint: string
  requestKey: string
  statusCode?: number
  body: string
  fetchedAt?: string
}

export interface RawSourceRecord {
  id: string
  source: string
  endpoint: string
  requestKey: string
  fetchedAt: string
  statusCode: number | null
  checksum: string
  body: string
}

export function checksumBody(body: string): string {
  return createHash('sha256').update(body).digest('hex')
}

export function saveRawSource(input: RawSourceInput, db?: DatabaseSync): RawSourceRecord | null {
  if (isDatabaseDisabled()) {
    return null
  }

  const database = db ?? getDatabase()
  const checksum = checksumBody(input.body)
  const fetchedAt = input.fetchedAt ?? new Date().toISOString()
  const statusCode = input.statusCode ?? null

  database.prepare(`
    insert or ignore into raw_sources (
      id,
      source,
      endpoint,
      request_key,
      fetched_at,
      status_code,
      checksum,
      body
    )
    values (?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    randomUUID(),
    input.source,
    input.endpoint,
    input.requestKey,
    fetchedAt,
    statusCode,
    checksum,
    input.body
  )

  return findRawSourceByChecksum({
    source: input.source,
    endpoint: input.endpoint,
    requestKey: input.requestKey,
    checksum
  }, database)
}

export function findRawSourceByChecksum(
  key: { source: string, endpoint: string, requestKey: string, checksum: string },
  db: DatabaseSync = getDatabase()
): RawSourceRecord | null {
  const row = db.prepare(`
    select
      id,
      source,
      endpoint,
      request_key as requestKey,
      fetched_at as fetchedAt,
      status_code as statusCode,
      checksum,
      body
    from raw_sources
    where source = ?
      and endpoint = ?
      and request_key = ?
      and checksum = ?
    limit 1
  `).get(key.source, key.endpoint, key.requestKey, key.checksum) as RawSourceRecord | undefined

  return row ?? null
}

export function countRawSources(db: DatabaseSync = getDatabase()): number {
  const row = db.prepare('select count(*) as count from raw_sources').get() as { count: number }
  return row.count
}
