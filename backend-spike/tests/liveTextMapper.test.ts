import { describe, expect, it } from 'vitest'

import { parsePreviousAtBatResult } from '../src/mappers/liveTextMapper.js'

describe('parsePreviousAtBatResult', () => {
  it('returns the newest completed at-bat result from KBO LiveText HTML', () => {
    const html = `
      <span class="normaiflTxt"> 한동희 : 좌익수 플라이 아웃<br /></span>
      <span class="normaiflTxt"> 레이예스 : 2루수 땅볼 아웃 (2루수-&gt;1루수 송구아웃)<br /></span>
      <span class="normaiflTxt"> 박찬호 : 3루수 땅볼 아웃 (3루수-&gt;1루수 송구아웃)<br /></span>
    `

    expect(parsePreviousAtBatResult(html)).toBe('박찬호 : 3루수 땅볼 아웃 (3루수->1루수 송구아웃)')
  })

  it('prefers the latest inning section when KBO lists newer innings before older innings', () => {
    const html = `
      <span class="normaiflTxt"> 6번타자 김선빈<br /></span>
      <span class="normaiflTxt"> 윤도현 : 3루수 땅볼 아웃 (3루수-&gt;1루수 송구아웃)<br /></span>
      <span class="normaiflTxt"> 5번타자 카스트로 : 대타 윤도현 (으)로 교체<br /></span>
      <span class="normaiflTxt"> 좌익수 김재환 : 좌익수 최준우 (으)로 교체<br /></span>
      <span class="normaiflTxt"> 투수 박시후 : 투수 서진용 (으)로 교체<br /></span>
      <span class="normaiflTxt"> 5번타자 카스트로<br /></span>
      <span class="normaiflTxt"> 8회말 KIA 공격<br /></span>
      <span class="normaiflTxt"> ---------------------------------------<br /></span>
      <span class="normaiflTxt"> 전의산 : 투수 땅볼 아웃 (투수-&gt;1루수 송구아웃)<br /></span>
      <span class="normaiflTxt"> 에레디아 : 1루수 땅볼 아웃 (1루수 태그아웃)<br /></span>
      <span class="normaiflTxt"> 김재환 : 1루수 땅볼 아웃 (1루수-&gt;투수 1루 터치아웃)<br /></span>
      <span class="normaiflTxt"> 투수 김범수 : 투수 한재승 (으)로 교체<br /></span>
      <span class="normaiflTxt"> 4번타자 김재환<br /></span>
      <span class="normaiflTxt"> 8회초 SSG 공격<br /></span>
    `

    expect(parsePreviousAtBatResult(html)).toBe('윤도현 : 3루수 땅볼 아웃 (3루수->1루수 송구아웃)')
  })

  it('ignores lineup, inning banner, count, and runner-only lines', () => {
    const html = `
      <span class="normaiflTxt"> 3회말 두산 공격<br /></span>
      <span class="normaiflTxt"> 9번타자 박찬호<br /></span>
      <span class="normaiflTxt"> 0-1 2out<br /></span>
      <span class="normaiflTxt"> 2루주자 황성빈 : 3루까지 진루<br /></span>
      <span class="normaiflTxt"> ball<br /></span>
    `

    expect(parsePreviousAtBatResult(html)).toBeNull()
  })

  it('returns null for blank or malformed HTML without a result line', () => {
    expect(parsePreviousAtBatResult('')).toBeNull()
    expect(parsePreviousAtBatResult('<div>현재 타석 박찬호</div>')).toBeNull()
  })
})
