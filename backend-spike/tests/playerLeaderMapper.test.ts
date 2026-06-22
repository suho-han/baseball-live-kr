import { describe, expect, it } from 'vitest'

import { parseBattingLeaders, parseKoreanPlayerNameMap, parsePitchingLeaders } from '../src/mappers/playerLeaderMapper.js'

describe('playerLeaderMapper', () => {
  it('parses batting leaders with player pcode as stable player id candidate', () => {
    const html = `
      <table summary="batting leaders">
        <tbody>
          <tr>
            <td title="RK">1</td>
            <td class="loop_l" title="PLAYER"><a href="/Teams/PlayerInfoHitter/Summary.aspx?pcode=66606" class="stats_player">CHOI Won Jun</a></td>
            <td title="TEAM">KT</td>
            <td title="AVG" class="on">0.381</td>
            <td title="G" class="">65</td>
            <td title="PA" class="">312</td>
            <td title="AB" class="">265</td>
            <td title="R" class="">59</td>
            <td title="H" class="">101</td>
            <td title="2B" class="">20</td>
            <td title="3B" class="">2</td>
            <td title="HR" class="">5</td>
            <td title="TB" class="">140</td>
            <td title="RBI" class="">37</td>
            <td title="SB" class="">15</td>
            <td title="CS" class="">6</td>
            <td title="SAC" class="">3</td>
            <td title="SF" class="">3</td>
          </tr>
        </tbody>
      </table>`

    expect(parseBattingLeaders(html)).toEqual([{
      playerId: '66606',
      playerName: 'CHOI Won Jun',
      teamId: 'KT',
      teamName: 'KT',
      rank: 1,
      games: 65,
      plateAppearances: 312,
      atBats: 265,
      runs: 59,
      hits: 101,
      doubles: 20,
      triples: 2,
      homeRuns: 5,
      totalBases: 140,
      rbi: 37,
      stolenBases: 15,
      caughtStealing: 6,
      sacrificeHits: 3,
      sacrificeFlies: 3,
      avg: 0.381
    }])
  })

  it('parses pitching leaders and converts innings pitched to outs', () => {
    const html = `
      <table summary="Pitching leaders">
        <tbody>
          <tr>
            <td title="RK">1</td>
            <td class="loop_l" title="PLAYER"><a href="/teams/playerinfopitcher/summary.aspx?pcode=55633" class="stats_player">OLLER Adam</a></td>
            <td title="TEAM">KIA</td>
            <td title="ERA" class="on">2.58</td>
            <td title="G" class="">14</td>
            <td title="CG" class="">1</td>
            <td title="SHO" class="">1</td>
            <td title="W" class="">7</td>
            <td title="L" class="">5</td>
            <td title="SV" class="">0</td>
            <td title="HLD" class="">0</td>
            <td title="PCT" class="">0.583</td>
            <td title="PA" class="">344</td>
            <td title="NP" class="">1314</td>
            <td title="IP" class="">87 1/3</td>
            <td title="H" class="">56</td>
            <td title="2B" class="">6</td>
            <td title="3B" class="">2</td>
            <td title="HR" class="">6</td>
          </tr>
        </tbody>
      </table>`

    expect(parsePitchingLeaders(html)).toEqual([{
      playerId: '55633',
      playerName: 'OLLER Adam',
      teamId: 'HT',
      teamName: 'KIA',
      rank: 1,
      games: 14,
      completeGames: 1,
      shutouts: 1,
      wins: 7,
      losses: 5,
      saves: 0,
      holds: 0,
      winningPercentage: 0.583,
      plateAppearances: 344,
      pitches: 1314,
      inningsPitchedOuts: 262,
      hitsAllowed: 56,
      doublesAllowed: 6,
      triplesAllowed: 2,
      homeRunsAllowed: 6,
      era: 2.58
    }])
  })

  it('parses Korean player names by player id from KBO Korean record links', () => {
    const html = `
      <table>
        <tbody>
          <tr><td><a href="/Record/Player/HitterDetail/Basic.aspx?playerId=66606">최원준</a></td></tr>
          <tr><td><a href="/Record/Player/PitcherDetail/Basic.aspx?playerId=55633">올러</a></td></tr>
          <tr><td><a href="/Teams/PlayerInfoHitter/Summary.aspx?pcode=54529">REYES Victor</a></td></tr>
        </tbody>
      </table>`

    expect(Object.fromEntries(parseKoreanPlayerNameMap(html))).toEqual({
      '66606': '최원준',
      '55633': '올러'
    })
  })
})

