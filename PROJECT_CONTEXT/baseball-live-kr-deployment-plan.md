# Baseball LIVE KR 배포 방안

**배포명:** Baseball LIVE KR
**한국어 표시명:** 한국 야구 라이브
**현재 local backend URL:** http://127.0.0.1:17361
**현재 production backend URL:** http://140.245.66.62:17361
**향후 대표 도메인 계획:** 퍼블릭 도메인

---

## 1. 배포 원칙

`Baseball LIVE KR`은 한국 야구 경기 일정, 실시간 스코어, 순위, 경기 상세 정보를 제공하는 비공식 앱으로 배포한다.

핵심 원칙은 다음과 같다.

1. 앱명, 아이콘, 패키지명, 번들 ID, GitHub repo, MCP, Skill 이름에서 `KBO`를 사용하지 않는다.
2. `KBO`는 필요한 경우 설명 문구에서만 제한적으로 사용한다.
3. 공식 리그, 구단, 단체와 제휴 또는 보증 관계가 있는 것처럼 보이지 않게 한다.
4. 현재 production backend 기본 URL은 `http://140.245.66.62:17361`로 유지하고, `퍼블릭 도메인` 전환은 향후 배포 계획으로 둔다.
5. reverse-DNS 식별자는 `kr.suhohan...` 형태로 통일한다.
6. 출시 전 한국 상표, App Store, Google Play, GitHub, 패키지명, MCP, Skill 충돌 여부를 재확인한다.

---

## 2. 최종 네이밍 정책

| 영역 | 권장값 |
|---|---|
| 앱 브랜드명 | `Baseball LIVE KR` |
| 한국어 표시명 | `한국 야구 라이브` |
| App Store 영문명 | `Baseball LIVE KR` |
| App Store 한국어명 | `한국 야구 라이브` |
| Google Play 영문명 | `Baseball LIVE KR` |
| Google Play 한국어명 | `한국 야구 라이브` |
| 앱 내부 짧은 표시명 | `LIVE KR` 또는 `야구 라이브` |
| 설명 문구 | `Unofficial Korean baseball live scores and schedules.` |

### App Store 부제

기존 후보였던 `Korean Baseball Scores & Schedule`은 App Store 부제 30자 제한을 초과하므로 사용하지 않는다.

권장 부제는 다음과 같다.

| 언어 | 부제 |
|---|---|
| en-US | `Korean Scores & Schedule` |
| ko-KR | `한국 야구 스코어·일정` |

---

## 3. 향후 도메인 및 식별자 정책

`퍼블릭 도메인`은 향후 공개 배포 시 기준 도메인으로 삼는 계획이다. 현재 앱의 production backend 기본 URL은 `http://140.245.66.62:17361`을 유지한다.

| 대상 | 권장 식별자 |
|---|---|
| iOS Bundle ID | `kr.suhohan.baseballlivekr.ios` |
| macOS Bundle ID | `kr.suhohan.baseballlivekr.macos` |
| Widget Bundle ID | `kr.suhohan.baseballlivekr.widget` |
| Android applicationId | `kr.suhohan.baseballlivekr` |
| Backend package | `baseball-live-kr-backend` |
| MCP package | `baseball-live-kr-mcp` |
| Claude/Agent Skill | `baseball-live-kr` |
| GitHub repo | `baseball-live-kr` |
| SKU | `baseball-live-kr` |
| App Group | `group.kr.suhohan.baseballlivekr` |

---

## 4. Xcode 프로젝트 수정안

프로젝트와 배포 산출물은 `BaseballLiveKRApp`, `kr.suhohan.baseballlivekr...`, `BaseballLiveKRiOS`, `BaseballLiveKRmacOS`, `BaseballLiveKRWidgetExtension` 이름을 사용한다.

### `project.yml` 권장 수정

```yaml
name: BaseballLiveKRApp
options:
  bundleIdPrefix: kr.suhohan
```

### iOS target

```yaml
PRODUCT_BUNDLE_IDENTIFIER: kr.suhohan.baseballlivekr.ios
PRODUCT_NAME: BaseballLiveKR
```

### macOS target

```yaml
PRODUCT_BUNDLE_IDENTIFIER: kr.suhohan.baseballlivekr.macos
PRODUCT_NAME: BaseballLiveKR
```

### Widget target

```yaml
PRODUCT_BUNDLE_IDENTIFIER: kr.suhohan.baseballlivekr.widget
PRODUCT_NAME: BaseballLiveKRWidget
```

---

## 5. 앱 내부 표시명 수정

### iOS 표시명

target 이름처럼 보이는 내부 식별자는 사용자 표시명에 노출하지 않는다.

```xml
<key>CFBundleDisplayName</key>
<string>Baseball LIVE KR</string>
```

한국어 기기에서 자연스럽게 보이도록 `InfoPlist.strings`를 분리하는 방식을 권장한다.

`en.lproj/InfoPlist.strings`

```text
CFBundleDisplayName = "Baseball LIVE KR";
```

`ko.lproj/InfoPlist.strings`

```text
CFBundleDisplayName = "한국 야구 라이브";
```

### Widget 표시명

Widget은 공간이 제한되므로 짧은 이름을 사용한다.

```xml
<key>CFBundleDisplayName</key>
<string>LIVE KR</string>
```

또는 한국어 환경에서는 다음과 같이 localize한다.

```text
CFBundleDisplayName = "야구 라이브";
```

---

## 6. 향후 App Store 배포안

| 필드 | 값 |
|---|---|
| App Name, en-US | `Baseball LIVE KR` |
| Subtitle, en-US | `Korean Scores & Schedule` |
| App Name, ko-KR | `한국 야구 라이브` |
| Subtitle, ko-KR | `한국 야구 스코어·일정` |
| Category | Sports |
| 향후 Support URL | `https://퍼블릭 도메인/baseball-live-kr/support` |
| 향후 Privacy Policy URL | `https://퍼블릭 도메인/baseball-live-kr/privacy` |

### App Review Notes 초안

```text
Baseball LIVE KR is an unofficial app for Korean baseball live scores, schedules, standings, and game details. It is not affiliated with or endorsed by KBO, its clubs, or any official league organization. The app does not use official league logos or club marks unless separately licensed.
```

### 한국어 설명 초안

```text
Baseball LIVE KR은 한국 야구 경기 일정, 실시간 스코어, 순위, 경기 상세 정보를 확인할 수 있는 비공식 앱입니다. 특정 리그, 구단, 공식 기관과 제휴하거나 보증받은 앱이 아닙니다.
```

---

## 7. 향후 Google Play 배포안

| 필드 | 값 |
|---|---|
| App name, en-US | `Baseball LIVE KR` |
| App name, ko-KR | `한국 야구 라이브` |
| Short description, en-US | `Live Korean baseball scores, schedules, standings, and alerts.` |
| Short description, ko-KR | `한국 야구 실시간 스코어, 일정, 순위, 알림을 확인하세요.` |
| Full description 핵심 | 비공식 앱, 실시간 스코어, 일정, 순위, 경기 상세 |
| Category | Sports |
| 향후 Developer website | `https://퍼블릭 도메인` |
| 향후 Privacy policy | `https://퍼블릭 도메인/baseball-live-kr/privacy` |
| 향후 Contact email | `support@퍼블릭 도메인` 또는 별도 운영 메일 |

### Google Play 주의사항

Google Play는 앱 이름의 과도한 대문자 사용을 제한적으로 볼 수 있다. `LIVE`를 브랜드 스타일로 유지하려면 로고, 웹사이트, 스토어 설명에서 일관되게 사용한다.

리스크를 더 낮추려면 Google Play에서는 다음 표기를 대안으로 검토한다.

```text
Baseball Live KR
```

---

## 8. GitHub repo / package 배포안

### Repo 이름

repo 이름은 다음을 기준으로 유지한다.

```text
suho-han/baseball-live-kr
```

### README 첫 문장 수정안

```md
# Baseball LIVE KR

한국 야구 경기 일정, 실시간 스코어, 순위, 경기 상세 정보를 Apple 플랫폼에서 확인하기 위한 비공식 앱/백엔드 저장소입니다.
```

### Backend package name

기존 `baseball-live-kr-backend-spike` 같은 이름은 교체한다.

```json
{
  "name": "baseball-live-kr-backend",
  "version": "0.1.0",
  "private": true
}
```

### 환경변수 기준

새 설정은 `BASEBALL_LIVE_KR_*` 이름만 문서화한다.

---

## 9. 향후 도메인 / HTTPS / API 배포안

현재 local backend 기본 URL은 `http://127.0.0.1:17361`이고 production backend 기본 URL은 `http://140.245.66.62:17361`이다. 공개 배포 단계에서 IP 직접 접근과 HTTP 예외를 제거하고, Production은 HTTPS-only로 구성한다.

| 목적 | URL |
|---|---|
| 개인정보처리방침 | `https://퍼블릭 도메인/baseball-live-kr/privacy` |
| 이용약관 | `https://퍼블릭 도메인/baseball-live-kr/terms` |
| 지원 | `https://퍼블릭 도메인/baseball-live-kr/support` |
| Status | `https://status.퍼블릭 도메인` 또는 `https://퍼블릭 도메인/status` |

### API endpoint 구조

```text
GET /v1/health
GET /v1/games/today
GET /v1/games/{gameId}
GET /v1/standings
GET /v1/players/search
GET /v1/players/{playerId}/season
```

---

## 10. MCP 배포안

MCP는 모바일 앱 배포와 분리해 읽기 전용 데이터 제공 서버로 공개한다.

| 항목 | 값 |
|---|---|
| MCP package | `baseball-live-kr-mcp` |
| MCP server name | `baseball-live-kr` |
| 설명 | `Unofficial Korean baseball live scores, schedules, standings, and player records.` |

### 초기 노출 tool

```text
get_today_games
get_game_detail
get_standings
search_players
get_player_season
```

### MCP 보안 원칙

1. MVP에서는 읽기 전용 tool만 제공한다.
2. 쓰기 작업, 계정 연동, 개인정보 조회는 넣지 않는다.
3. API rate limit을 둔다.
4. tool response에는 출처, 갱신 시각, stale 여부를 포함한다.
5. 내부 운영용 endpoint는 공개 MCP에서 노출하지 않는다.

---

## 11. Skill 배포안

Skill은 repo 내부에 project skill로 추가한다.

```text
.claude/skills/baseball-live-kr/SKILL.md
```

### `SKILL.md` 초안

```md
---
name: baseball-live-kr
description: Use this skill when working on the Baseball LIVE KR app, backend, release metadata, store review preparation, or Korean baseball data integration.
---

## Product identity

Use the public brand name `Baseball LIVE KR`.
Use the Korean display name `한국 야구 라이브`.
Keep the current local backend default on `http://127.0.0.1:17361`.
Keep the current production backend default on `http://140.245.66.62:17361` until the production domain is ready.
Treat `퍼블릭 도메인` as the future canonical domain plan.
Use reverse-DNS identifiers under `kr.suhohan`.

## Naming restrictions

Do not use `KBO` in app names, bundle IDs, package names, repo names, icons, screenshots, or marketing headlines.
Use `KBO` only in limited explanatory text when necessary to describe compatible Korean baseball schedules or scores, and include unofficial-app wording.

## Release identifiers

- iOS: `kr.suhohan.baseballlivekr.ios`
- macOS: `kr.suhohan.baseballlivekr.macos`
- Widget: `kr.suhohan.baseballlivekr.widget`
- Android: `kr.suhohan.baseballlivekr`
- Current local backend: `http://127.0.0.1:17361`
- Current production backend: `http://140.245.66.62:17361`

## Release checks

Before release, verify:

1. App names and subtitles fit store character limits.
2. Future privacy/support/terms URLs are live under `퍼블릭 도메인` before public release.
3. App metadata says the app is unofficial.
4. No official league or club marks are used without permission.
5. Production backend is HTTPS-only.
6. Bundle IDs and Android applicationId are final before first upload.
```

---

## 12. 권리물 / 로고 / 데이터 사용 정책

출시 전 공식 로고, 워드마크, CI, 구단 엠블럼 사용 여부를 재검토한다.

MVP 배포 방침은 다음과 같다.

1. 공식 리그 로고 사용 금지.
2. 공식 구단 로고/워드마크 사용 금지.
3. 팀 표기는 텍스트명, 약칭, 자체 색상 토큰 정도로 제한.
4. 아이콘은 야구공, 다이아몬드, 스코어보드 등 자체 제작 그래픽 사용.
5. 앱 설명에 “비공식 앱” 명시.
6. 데이터 출처와 갱신 주기를 개인정보처리방침 또는 도움말에 명시.

---

## 13. 출시 순서

### 13.1 브랜드 정리 PR

목표는 외부 노출명을 `Baseball LIVE KR`와 `baseball-live-kr` 기준으로 통일하는 것이다.

변경 대상:

```text
README.md
project.yml
BaseballLiveKRApp/iOS/Info.plist
BaseballLiveKRApp/macOS/Info.plist
BaseballLiveKRApp/Widget/Info.plist
backend-spike/package.json
scripts/*
PROJECT_CONTEXT/*
```

우선순위:

1. `project.yml`의 Bundle ID를 `kr.suhohan...`로 변경.
2. iOS/macOS/Widget 표시명을 `Baseball LIVE KR` 또는 `한국 야구 라이브`로 변경.
3. README와 문서의 제품명을 `Baseball LIVE KR`로 변경.
4. backend package name을 `baseball-live-kr-backend`로 변경.
5. 환경변수 prefix를 `BASEBALL_LIVE_KR_`로 변경.

### 13.2 향후 도메인 / HTTPS PR

목표는 앱 심사 가능한 production URL을 만드는 것이다.

작업:

1. 랜딩 페이지 생성.
2. Privacy, Terms, Support 페이지 생성.
3. API health endpoint 공개.
4. iOS/macOS의 HTTP 예외 제거.
5. production preset을 공개 API URL로 전환.
6. staging preset을 공개 staging API URL로 분리.

### 13.3 권리물 정리 PR

목표는 심사 리스크를 줄이는 것이다.

작업:

1. 공식 로고/워드마크 asset 제거 또는 비활성화.
2. 자체 팀 컬러/약칭 매핑만 사용.
3. 앱 아이콘을 자체 제작 그래픽으로 교체.
4. 스크린샷에서 공식 로고 노출 제거.
5. 앱 설명과 리뷰 노트에 비공식 문구 추가.

### 13.4 TestFlight / Internal Test

목표는 실제 배포 전 동작 안정화다.

작업:

1. iOS TestFlight internal group 배포.
2. macOS notarization 또는 App Store 배포 경로 결정.
3. Google Play internal testing track 배포.
4. production backend 장애 시 stale cache fallback 확인.
5. 경기 없음, 우천 취소, 더블헤더, 연장, 종료, postponed 상태 확인.
6. Widget/Live Activity가 실제 경기 상태 변화에 맞게 갱신되는지 확인.

### 13.5 Public Launch

권장 출시 순서:

1. 웹 랜딩 페이지 공개.
2. GitHub repo rename.
3. iOS TestFlight 외부 테스트.
4. Google Play closed testing.
5. App Store 정식 심사 제출.
6. Google Play production staged rollout 10%.
7. 문제 없으면 50% → 100%.
8. MCP와 Skill은 앱 출시 후 별도 공개.

---

## 14. 최종 배포 매트릭스

| 영역 | 값 |
|---|---|
| 제품명 | `Baseball LIVE KR` |
| 한국어명 | `한국 야구 라이브` |
| 현재 local backend | `http://127.0.0.1:17361` |
| 현재 production backend | `http://140.245.66.62:17361` |
| 향후 도메인 | `퍼블릭 도메인` |
| Privacy | `https://퍼블릭 도메인/baseball-live-kr/privacy` |
| Support | `https://퍼블릭 도메인/baseball-live-kr/support` |
| Terms | `https://퍼블릭 도메인/baseball-live-kr/terms` |
| GitHub | `suho-han/baseball-live-kr` |
| iOS Bundle ID | `kr.suhohan.baseballlivekr.ios` |
| macOS Bundle ID | `kr.suhohan.baseballlivekr.macos` |
| Widget Bundle ID | `kr.suhohan.baseballlivekr.widget` |
| Android applicationId | `kr.suhohan.baseballlivekr` |
| Backend package | `baseball-live-kr-backend` |
| MCP package | `baseball-live-kr-mcp` |
| Skill | `.claude/skills/baseball-live-kr/SKILL.md` |

---

## 15. 출시 전 체크리스트

### 상표 / 명칭

- [ ] KIPRIS에서 `Baseball LIVE KR` 검색
- [ ] KIPRIS에서 `Baseball Live KR` 검색
- [ ] KIPRIS에서 `한국 야구 라이브` 검색
- [ ] App Store에서 정확일치 및 유사 앱명 검색
- [ ] Google Play에서 정확일치 및 유사 앱명 검색
- [ ] GitHub repo/package 이름 검색
- [ ] MCP registry 및 Skill registry 검색

### 스토어 메타데이터

- [ ] App Store 앱명 30자 이하 확인
- [ ] App Store 부제 30자 이하 확인
- [ ] Google Play 앱 이름 30자 이하 확인
- [ ] Google Play short description 80자 이하 확인
- [ ] 비공식 앱 문구 포함
- [ ] 공식 제휴처럼 보이는 표현 제거

### 기술 배포

- [ ] iOS Bundle ID 최종 확정
- [ ] macOS Bundle ID 최종 확정
- [ ] Widget Bundle ID 최종 확정
- [ ] Android applicationId 최종 확정
- [ ] Production API HTTPS-only 확인
- [ ] HTTP 예외 제거
- [ ] Privacy URL 공개
- [ ] Support URL 공개
- [ ] Terms URL 공개

### 권리물

- [ ] 공식 리그 로고 제거
- [ ] 공식 구단 로고/워드마크 제거
- [ ] 자체 앱 아이콘 적용
- [ ] 자체 팀 색상/약칭만 사용
- [ ] 스크린샷 권리물 노출 확인

### 운영

- [ ] Production health endpoint 확인
- [ ] Backend stale cache fallback 확인
- [ ] 경기 없음 상태 확인
- [ ] 우천 취소 상태 확인
- [ ] 더블헤더 상태 확인
- [ ] 연장전 상태 확인
- [ ] Widget 갱신 확인
- [ ] Live Activity 갱신 확인
- [ ] 장애 대응 문서 작성

---

## 16. 참고 링크

- Apple App Store Connect - App information: https://developer.apple.com/help/app-store-connect/reference/app-information
- Android Developers - Configure the app module: https://developer.android.com/build/configure-app-module
- Google Play Console Help - Create and set up your app: https://support.google.com/googleplay/android-developer/answer/9859152
- Google Play Console Help - Store listing and promotion policy: https://support.google.com/googleplay/android-developer/answer/13393723
- Model Context Protocol Introduction: https://modelcontextprotocol.io/introduction
- Model Context Protocol Specification: https://modelcontextprotocol.io/specification/2025-06-18
- Claude Code Skills: https://docs.anthropic.com/en/docs/claude-code/skills

---

## 17. 최종 판단

`Baseball LIVE KR`은 `KBO`를 직접 앱명에 쓰지 않으면서도 한국 야구, 실시간성, 지역성을 전달할 수 있는 이름이다. 현재 production backend URL은 `http://140.245.66.62:17361`로 유지하고, 공개 배포 전략에서는 `퍼블릭 도메인`을 기준으로 외부 식별자를 통일하는 방향이 적합하다.

가장 중요한 선행 작업은 다음 세 가지다.

1. Bundle ID와 Android applicationId를 `kr.suhohan...`으로 확정한다.
2. 향후 배포 단계에서 `퍼블릭 도메인` 하위의 privacy, support, terms, landing URL을 공개한다.
3. 공식 로고와 워드마크를 제거하고 자체 브랜딩으로 교체한다.
