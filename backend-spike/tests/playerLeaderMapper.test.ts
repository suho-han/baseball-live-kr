import { describe, expect, it } from 'vitest'

import { parseBattingLeaders, parseKoreanBattingDetailStats, parseKoreanPitchingBasicStats, parseKoreanPitchingDetailStats, parseKoreanPlayerNameMap, parsePitchingLeaders } from '../src/mappers/playerLeaderMapper.js'

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

  it('parses Korean batting detail stats by data-id from hitter basic2 pages', () => {
    const html = `
      <table><tbody><tr>
        <td>1</td>
        <td><a href="/Record/Player/HitterDetail/Basic.aspx?playerId=66606">최원준</a></td>
        <td>KT</td>
        <td data-id="HRA_RT">0.379</td>
        <td data-id="BB_CN">39</td>
        <td data-id="KK_CN">47</td>
        <td data-id="SLG_RT">0.529</td>
        <td data-id="OBP_RT">0.459</td>
        <td data-id="OPS_RT">0.988</td>
      </tr></tbody></table>`

    expect(parseKoreanBattingDetailStats(html)).toEqual(new Map([
      ['66606', {
        playerId: '66606',
        playerName: '최원준',
        teamId: 'KT',
        teamName: 'KT',
        walks: 39,
        strikeouts: 47,
        avg: 0.379,
        obp: 0.459,
        slg: 0.529,
        ops: 0.988
      }]
    ]))
  })

  it('parses Korean pitching basic counting stats by data-id from pitcher basic1 pages', () => {
    const html = `
      <table><tbody><tr>
        <td>1</td>
        <td><a href="/Record/Player/PitcherDetail/Basic.aspx?playerId=55633">올러</a></td>
        <td>KIA</td>
        <td data-id="ERA_RT">2.58</td>
        <td data-id="BB_CN">27</td>
        <td data-id="KK_CN">92</td>
        <td data-id="ER_CN">25</td>
        <td data-id="WHIP_RT">0.95</td>
      </tr></tbody></table>`

    expect(parseKoreanPitchingBasicStats(html)).toEqual(new Map([
      ['55633', {
        playerId: '55633',
        playerName: '올러',
        teamId: 'HT',
        teamName: 'KIA',
        era: 2.58,
        walks: 27,
        strikeouts: 92,
        earnedRuns: 25,
        whip: 0.95
      }]
    ]))
  })

  it('parses Korean pitching detail rates by data-id from pitcher detail2 pages', () => {
    const html = `
      <table><tbody><tr>
        <td>1</td>
        <td><a href="/Record/Player/PitcherDetail/Basic.aspx?playerId=55633">올러</a></td>
        <td>KIA</td>
        <td data-id="ERA_RT">2.58</td>
        <td data-id="GAME_KK_RT">9.48</td>
        <td data-id="GAME_BB_RT">2.78</td>
        <td data-id="BB_KK_RT">3.41</td>
        <td data-id="OOBP_RT">0.260</td>
        <td data-id="OSLG_RT">0.275</td>
        <td data-id="OOPS_RT">0.535</td>
      </tr></tbody></table>`

    expect(parseKoreanPitchingDetailStats(html)).toEqual(new Map([
      ['55633', {
        playerId: '55633',
        playerName: '올러',
        teamId: 'HT',
        teamName: 'KIA',
        era: 2.58,
        strikeoutsPerNine: 9.48,
        walksPerNine: 2.78,
        strikeoutWalkRatio: 3.41,
        opponentObp: 0.260,
        opponentSlg: 0.275,
        opponentOps: 0.535
      }]
    ]))
  })
})

