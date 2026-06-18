const TEAM_NAME_TO_ID: Record<string, string> = {
  LG: 'LG',
  KT: 'KT',
  SAMSUNG: 'SS',
  KIA: 'HT',
  DOOSAN: 'OB',
  HANWHA: 'HH',
  NC: 'NC',
  SSG: 'SK',
  KIWOOM: 'WO',
  LOTTE: 'LT',
  삼성: 'SS',
  두산: 'OB',
  한화: 'HH',
  키움: 'WO',
  롯데: 'LT'
}

export function mapTeamNameToId(teamName: string): string | null {
  return TEAM_NAME_TO_ID[teamName.trim().toUpperCase()] ?? TEAM_NAME_TO_ID[teamName.trim()] ?? null
}

