export const DEFAULT_REFERER = 'https://www.koreabaseball.com/Schedule/GameCenter/Main.aspx'

export function buildKboHeaders(referer: string = DEFAULT_REFERER): Record<string, string> {
  return {
    'User-Agent': 'Mozilla/5.0',
    'X-Requested-With': 'XMLHttpRequest',
    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    Accept: 'application/json, text/javascript, */*; q=0.01',
    Origin: 'https://www.koreabaseball.com',
    Referer: referer
  }
}
