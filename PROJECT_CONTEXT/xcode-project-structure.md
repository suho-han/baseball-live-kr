# KBO Live Xcode Project Structure

작성일: 2026-06-10
상태: Draft v0.1
개발 환경: 로컬 Mac + Xcode

## 1. 목표

로컬 Mac에서 iPhone 앱, Widget, Live Activity, macOS 메뉴바 앱을 한 워크스페이스 안에서 함께 개발할 수 있는 멀티타깃 구조를 정의한다.

핵심 원칙:
- Apple 플랫폼 기능은 네이티브로 구현
- 공유 가능한 로직은 최대한 Core로 분리
- UI 타깃과 데이터/도메인 로직을 분리
- 초기 MVP에서 과도한 모듈 분할은 피함

---

## 2. 권장 워크스페이스 구성

```text
kbo-live/
├── KboLive.xcworkspace
├── KboLiveApp/
│   ├── KboLiveApp.xcodeproj
│   ├── KboLiveiOS/
│   ├── KboLivemacOS/
│   ├── KboLiveWidgetExtension/
│   └── KboLiveActivityExtension/
├── Packages/
│   ├── KboLiveCore/
│   ├── KboLiveDesignSystem/
│   └── KboLiveFeatureSupport/
└── PROJECT_CONTEXT/
```

### 판단
- 앱 타깃은 Xcode project에서 관리
- 공유 로직은 Swift Package로 분리
- 초기에는 package 수를 최소화
- 추후 복잡해지면 feature 단위 package 추가 가능

---

## 3. 타깃 구성

## 3.1 iOS App Target
이름 예시:
- `KboLiveiOS`

역할:
- 경기 리스트
- 경기 상세
- 즐겨찾기 관리
- Live Activity 시작/종료 진입점
- Widget 설정 진입
- 앱 foreground polling

포함 범위:
- SwiftUI App entry
- Navigation
- 화면 조립
- 상태 컨테이너
- App lifecycle

비포함 범위:
- 공통 모델 정의
- 공통 API 파싱 로직
- 점수 계산/표현 공통 로직

이런 것은 Core로 이동

---

## 3.2 Widget Extension Target
이름 예시:
- `KboLiveWidgets`

역할:
- Small widget
- Medium widget
- Timeline provider
- Widget configuration

의존성:
- `KboLiveCore`
- `KboLiveDesignSystem`

주의:
- widget은 제한된 실행 환경을 가짐
- 지나치게 복잡한 네트워크 로직을 넣지 않음
- 공통 snapshot/timeline 모델은 별도 mapper로 단순화

---

## 3.3 Live Activity Extension Target
이름 예시:
- `KboLiveLiveActivity`

역할:
- Lock Screen layout
- Dynamic Island compact/minimal/expanded layout
- Activity attributes 정의
- content state UI 정의

의존성:
- `KboLiveCore`
- `KboLiveDesignSystem`

주의:
- ActivityKit state는 매우 작고 명확해야 함
- 전체 Game 모델을 Activity state에 그대로 넣지 않음
- 표시 전용 경량 state 구조체를 별도로 둠

---

## 3.4 macOS App Target
이름 예시:
- `KboLivemacOS`

역할:
- MenuBarExtra
- 상단 바 ticker
- 드롭다운 경기 목록
- 즐겨찾기 경기 우선 표시
- 설정 진입

의존성:
- `KboLiveCore`
- `KboLiveDesignSystem`

주의:
- 메뉴바 텍스트는 매우 짧아야 함
- 상태 요약 포맷터를 별도로 두는 것이 좋음

---

## 4. Swift Package 구성

초기에는 아래 3개면 충분하다.

## 4.1 KboLiveCore
역할:
- 도메인 모델
- API 클라이언트
- DTO
- repository
- polling/service
- formatter
- 공통 유틸리티

권장 디렉터리:

```text
Packages/KboLiveCore/
├── Package.swift
├── Sources/
│   └── KboLiveCore/
│       ├── Domain/
│       ├── DTO/
│       ├── API/
│       ├── Repository/
│       ├── Services/
│       ├── Formatting/
│       └── Utils/
└── Tests/
    └── KboLiveCoreTests/
```

### 포함 예시
- `Game`
- `Team`
- `InningState`
- `BasesState`
- `GameStatus`
- `KboAPIClient`
- `GameRepository`
- `LiveGamePollingService`
- `ScoreboardFormatter`

---

## 4.2 KboLiveDesignSystem
역할:
- 컬러 토큰
- 타이포 토큰
- 공통 badge/button/card 스타일
- 팀 색상 매핑
- 공통 UI primitive

권장 디렉터리:

```text
Packages/KboLiveDesignSystem/
├── Package.swift
├── Sources/
│   └── KboLiveDesignSystem/
│       ├── Tokens/
│       ├── Theme/
│       ├── Components/
│       └── Helpers/
└── Tests/
    └── KboLiveDesignSystemTests/
```

### 포함 예시
- `KboColorToken`
- `TeamColorPalette`
- `LiveBadgeView`
- `ScoreDigitStyle`
- `BaseDiamondPrimitive`

---

## 4.3 KboLiveFeatureSupport
역할:
- 화면 공통 view model helper
- feature별 mapper
- widget/live activity 변환기
- 앱/타깃 사이 glue code

이 패키지는 선택이다.
초기에는 iOS/macOS target 내부에 둬도 되지만, 공통 화면 지원 로직이 늘어나면 분리하는 것이 좋다.

---

## 5. 권장 소스 구조

## 5.1 iOS App 내부

```text
KboLiveApp/KboLiveiOS/
├── App/
│   ├── KboLiveiOSApp.swift
│   ├── AppContainer.swift
│   └── AppRouter.swift
├── Features/
│   ├── Home/
│   ├── GameDetail/
│   ├── Favorites/
│   ├── Settings/
│   └── LiveActivityControl/
├── Shared/
│   ├── Components/
│   ├── Screens/
│   └── Extensions/
└── Resources/
```

### 화면 단위 구조 예시

```text
Features/Home/
├── HomeView.swift
├── HomeViewModel.swift
├── HomeSection.swift
├── HomeFilterBar.swift
└── Components/
    ├── HomeGameCardA.swift
    ├── HomeGameCardB.swift
    └── HomeStatusStrip.swift
```

---

## 5.2 macOS App 내부

```text
KboLiveApp/KboLivemacOS/
├── App/
├── MenuBar/
│   ├── MenuBarRoot.swift
│   ├── MenuBarLabelView.swift
│   ├── MenuBarDropdownView.swift
│   └── MenuBarGameRow.swift
├── Settings/
└── Resources/
```

---

## 5.3 Widget Extension 내부

```text
KboLiveApp/KboLiveWidgetExtension/
├── WidgetBundle.swift
├── Providers/
│   ├── FavoriteGameTimelineProvider.swift
│   └── TodayGamesTimelineProvider.swift
├── Models/
│   └── WidgetSnapshot.swift
└── Views/
    ├── SmallGameWidgetView.swift
    ├── MediumGameWidgetView.swift
    └── WidgetEmptyStateView.swift
```

---

## 5.4 Live Activity Extension 내부

```text
KboLiveApp/KboLiveActivityExtension/
├── KboLiveActivityAttributes.swift
├── KboLiveActivityWidget.swift
├── Models/
│   └── ActivityGameState.swift
└── Views/
    ├── LockScreenGameView.swift
    ├── DynamicIslandCompactView.swift
    ├── DynamicIslandMinimalView.swift
    └── DynamicIslandExpandedView.swift
```

---

## 6. 도메인 모델 위치 원칙

아래 모델은 `KboLiveCore`에 둔다.

- `Team`
- `Game`
- `Score`
- `GameStatus`
- `InningState`
- `BasesState`
- `OutState`
- `CurrentMatchup`
- `RecentPlay`
- `FavoriteTeam`

### 이유
- iOS/macOS/widget/live activity 모두 공유 가능
- formatter/test와 결합하기 좋음
- 타깃별 중복 모델 생성을 줄일 수 있음

---

## 7. 네트워크 계층 구조

권장 흐름:

```text
ViewModel
→ Repository
→ API Client
→ DTO Decode
→ Domain Mapper
→ Domain Model
```

예시 파일:

```text
KboLiveCore/API/KboAPIClient.swift
KboLiveCore/API/KboRequestBuilder.swift
KboLiveCore/DTO/KboGameListResponseDTO.swift
KboLiveCore/Repository/GameRepository.swift
KboLiveCore/Services/LiveGamePollingService.swift
```

### 원칙
- ViewModel이 직접 URLSession 호출하지 않음
- DTO와 Domain Model을 분리
- HTML scraping이 필요할 경우 parser 계층을 따로 둠

---

## 8. 환경/설정 분리

초기부터 설정값을 분리하는 것이 좋다.

예시:

```text
KboLiveCore/Config/
├── AppEnvironment.swift
├── APIEnvironment.swift
└── FeatureFlags.swift
```

포함 값:
- baseURL
- polling interval
- widget refresh policy
- live activity update policy
- data source provider type

이렇게 해두면:
- 공식 KBO source
- 대체 source
- mock source
를 바꾸기 쉬움

---

## 9. Preview / Mock 구조

로컬 Mac 개발에서 SwiftUI Preview 생산성이 중요하므로 mock 계층을 초기에 두는 것을 권장한다.

예시:

```text
KboLiveCore/Mocks/
├── MockGameFactory.swift
├── MockTeamFactory.swift
└── MockRecentPlayFactory.swift
```

용도:
- Home 카드 A/B 테스트
- Widget snapshot 확인
- Live Activity 레이아웃 확인
- macOS 메뉴바 드롭다운 미리보기

---

## 10. 테스트 구조

## 우선순위 높은 테스트
1. formatter 테스트
2. mapper 테스트
3. repository response parsing 테스트
4. widget snapshot mapping 테스트
5. live activity state mapping 테스트

권장 디렉터리:

```text
Packages/KboLiveCore/Tests/KboLiveCoreTests/
├── API/
├── DTO/
├── Repository/
├── Formatting/
└── Services/
```

---

## 11. 초기 생성 순서

로컬 Mac에서 Xcode 작업 시작 시 순서:

1. `KboLive.xcworkspace` 생성
2. iOS App target 생성
3. Widget Extension 추가
4. Live Activity Extension 추가
5. macOS App target 추가
6. `KboLiveCore` Swift Package 연결
7. `KboLiveDesignSystem` Swift Package 연결
8. Home mock 화면부터 Preview 확인

---

## 12. MVP 기준 최소 구조

복잡도를 낮춘다면 초기 MVP는 아래만 먼저 만든다.

```text
KboLive.xcworkspace
KboLiveApp.xcodeproj
Packages/KboLiveCore
Packages/KboLiveDesignSystem
```

그리고 타깃은:
- iOS App
- Widget Extension
- Live Activity Extension
- macOS App

이 정도면 충분하다.
`KboLiveFeatureSupport`는 필요해질 때 추가한다.

---

## 13. 현재 추천 결론

- Xcode project + Swift package 혼합 구조가 가장 적합
- 공유 로직은 `KboLiveCore`에 집중
- 디자인 토큰/primitive는 `KboLiveDesignSystem`으로 분리
- iOS/macOS/widget/live activity는 얇은 UI shell로 유지
- 로컬 Mac 개발에서는 Preview/mock 구조를 초기에 확보하는 것이 생산성에 중요함
