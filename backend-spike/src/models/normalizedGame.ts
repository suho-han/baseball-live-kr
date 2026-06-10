export interface NormalizedGame {
  gameId: string
  date: string
  venue: string | null
  startTime: string | null
  status: 'scheduled' | 'live' | 'final' | 'delayed' | 'cancelled' | 'unknown'
  awayTeam: {
    id: string
    name: string
  }
  homeTeam: {
    id: string
    name: string
  }
  score: {
    away: number
    home: number
  }
  inning: {
    number: number
    half: 'top' | 'bottom'
  } | null
  count: {
    balls: number
    strikes: number
    outs: number
  } | null
  bases: {
    first: boolean
    second: boolean
    third: boolean
  } | null
  current: {
    batter: string | null
    pitcher: string | null
  } | null
  probablePitchers: {
    away: string | null
    home: string | null
  }
  recentPlay: string | null
  sourceMeta: {
    rawStatusCode: string | null
    rawTopBottomCode: string | null
    fetchedAt: string
  }
}
