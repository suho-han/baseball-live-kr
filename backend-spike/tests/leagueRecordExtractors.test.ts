import { readFileSync } from 'node:fs'

import { describe, expect, it } from 'vitest'

import { parseTopFiveCategories } from '../src/records/leagueRecordExtractors.js'

describe('leagueRecordExtractors', () => {
  it('extracts TOP5 categories with Korean player names', () => {
    const html = readFileSync(new URL('./fixtures/league-top5-snippet.html', import.meta.url), 'utf8')

    expect(parseTopFiveCategories(html)).toEqual([
      {
        title: '타율 TOP5',
        leaders: [
          { rank: 1, playerId: '66606', playerName: '최원준', teamName: 'KT', value: '0.379' },
          { rank: 2, playerId: '54529', playerName: '레이예스', teamName: '롯데', value: '0.348' }
        ]
      },
      {
        title: '홈런 TOP5',
        leaders: [
          { rank: 1, playerId: '52156', playerName: '디아즈', teamName: '삼성', value: '25' }
        ]
      }
    ])
  })
})
