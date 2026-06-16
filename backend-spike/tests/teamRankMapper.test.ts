import { describe, expect, it } from 'vitest'

import { parseKboTeamRankDaily } from '../src/mappers/teamRankMapper.js'

describe('parseKboTeamRankDaily', () => {
  it('maps KBO standings rows into team record summaries', () => {
    const html = `
      <table summary="순위, 팀명,승,패,무,승률,승차,최근10경기,연속,홈,방문">
        <tbody>
          <tr><td>1</td><td>LG</td><td>65</td><td>41</td><td>24</td><td>0</td><td>0.631</td><td>0</td><td>7승0무3패</td><td>2승</td><td>24-0-11</td><td>17-0-13</td></tr>
          <tr><td>4</td><td>KIA</td><td>66</td><td>34</td><td>31</td><td>1</td><td>0.523</td><td>7</td><td>5승0무5패</td><td>1패</td><td>20-1-13</td><td>14-0-18</td></tr>
        </tbody>
      </table>`

    expect(parseKboTeamRankDaily(html)).toEqual([
      {
        teamId: 'LG',
        teamName: 'LG',
        wins: 41,
        losses: 24,
        draws: 0,
        rank: 1,
        streak: '2승',
        recentTen: '7승0무3패',
        gamesBack: '0'
      },
      {
        teamId: 'HT',
        teamName: 'KIA',
        wins: 34,
        losses: 31,
        draws: 1,
        rank: 4,
        streak: '1패',
        recentTen: '5승0무5패',
        gamesBack: '7'
      }
    ])
  })
})
