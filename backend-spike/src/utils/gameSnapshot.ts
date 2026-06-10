import type { NormalizedGame } from '../models/normalizedGame.js'

export interface GameChangeSummary {
  gameId: string
  matchup: string
  changes: string[]
}

function sameJson(a: unknown, b: unknown): boolean {
  return JSON.stringify(a) === JSON.stringify(b)
}

function matchup(game: NormalizedGame): string {
  return `${game.awayTeam.name} @ ${game.homeTeam.name}`
}

export function summarizeGameChanges(previousGames: NormalizedGame[], currentGames: NormalizedGame[]): GameChangeSummary[] {
  const previousById = new Map(previousGames.map((game) => [game.gameId, game]))

  return currentGames.flatMap((game) => {
    const previous = previousById.get(game.gameId)

    if (!previous) {
      return [{
        gameId: game.gameId,
        matchup: matchup(game),
        changes: ['initial snapshot']
      }]
    }

    const changes: string[] = []

    if (previous.status !== game.status) {
      changes.push(`status ${previous.status} -> ${game.status}`)
    }

    if (!sameJson(previous.score, game.score)) {
      changes.push(`score ${previous.awayTeam.name} ${previous.score.away}:${previous.score.home} ${previous.homeTeam.name} -> ${game.awayTeam.name} ${game.score.away}:${game.score.home} ${game.homeTeam.name}`)
    }

    if (!sameJson(previous.inning, game.inning)) {
      changes.push(`inning ${JSON.stringify(previous.inning)} -> ${JSON.stringify(game.inning)}`)
    }

    if (!sameJson(previous.count, game.count)) {
      changes.push(`count ${JSON.stringify(previous.count)} -> ${JSON.stringify(game.count)}`)
    }

    if (!sameJson(previous.bases, game.bases)) {
      changes.push(`bases ${JSON.stringify(previous.bases)} -> ${JSON.stringify(game.bases)}`)
    }

    if (!sameJson(previous.current, game.current)) {
      changes.push(`current ${JSON.stringify(previous.current)} -> ${JSON.stringify(game.current)}`)
    }

    if (!sameJson(previous.recentPlay, game.recentPlay)) {
      changes.push(`recentPlay ${JSON.stringify(previous.recentPlay)} -> ${JSON.stringify(game.recentPlay)}`)
    }

    if (changes.length === 0) {
      return []
    }

    return [{
      gameId: game.gameId,
      matchup: matchup(game),
      changes
    }]
  })
}

export function toPollingView(game: NormalizedGame) {
  return {
    gameId: game.gameId,
    matchup: matchup(game),
    status: game.status,
    score: game.score,
    inning: game.inning,
    count: game.count,
    bases: game.bases,
    current: game.current,
    recentPlay: game.recentPlay
  }
}
