# Live Activity MVP 검증 체크리스트

작성일: 2026-06-16

## 1. 목적

Baseball LIVE KR iOS app에서 진행 중 경기 Live Activity를 실제 기기 Lock Screen과 Dynamic Island에서 start/stop 할 수 있는지 검증한다.

## 2. 현재 구현 상태

- iOS app target은 `NSSupportsLiveActivities`를 켠다.
- Widget extension은 `LiveGameActivityWidget`을 포함한다.
- `LiveGameActivityController`가 진행 중 경기만 start 가능하게 제한한다.
- Today 화면의 진행 중 경기 카드에는 Live Activity 시작/종료 버튼이 표시된다.
- 앱 경기 목록이 갱신되면 active Live Activity content state도 갱신한다.
- 경기가 live가 아니게 되면 해당 activity를 종료한다.

## 3. 사전 조건

- 실제 iPhone 기기 필요. Dynamic Island 검증은 지원 기기에서만 가능하다.
- iOS 설정에서 Live Activities가 허용되어 있어야 한다.
- 앱은 backend에서 `status: live`인 경기를 받아야 한다.
- 로컬 fixture 검증 시 backend를 `NODE_ENV=development KBO_USE_TEST_LIVE_GAME=1`로 실행한다.

예시:

```bash
NODE_ENV=development KBO_USE_TEST_LIVE_GAME=1 FORCE_RESTART=1 PORT=3000 ./scripts/run-macos-app-with-packaged-backend.sh
```

iOS 실제 기기에서는 Mac host backend 접근을 위해 `BASEBALL_LIVE_KR_BASE_URL` 또는 앱 설정의 Custom URL을 Mac의 접근 가능한 IP로 맞춘다.

## 4. 검증 절차

1. iPhone에서 `BaseballLiveKRiOS` scheme을 실제 기기로 실행한다.
2. 설정에서 backend URL을 live fixture 또는 실제 live 경기 backend로 맞춘다.
3. 오늘 경기 화면에 live 경기 카드가 보이는지 확인한다.
4. live 경기 아래 `Live Activity 시작`을 누른다.
5. Lock Screen에서 점수, 이닝, 최근 플레이 문구가 표시되는지 확인한다.
6. Dynamic Island compact/minimal/expanded 영역에서 away/home score와 팀명이 깨지지 않는지 확인한다.
7. 앱으로 돌아와 `Live Activity 종료`를 누른다.
8. Lock Screen/Dynamic Island에서 activity가 제거되는지 확인한다.
9. backend 응답을 final/scheduled 상태로 바꾼 뒤 앱 목록 갱신 시 activity가 자동 종료되는지 확인한다.

## 5. 통과 기준

- live 경기에서만 start 버튼이 표시된다.
- activity 생성 실패 시 앱이 크래시하지 않는다.
- Lock Screen에서 점수와 이닝이 first fold 안에 표시된다.
- Dynamic Island compact/minimal/expanded layout에서 텍스트가 심하게 잘리지 않는다.
- stop 버튼으로 즉시 종료된다.
- 경기 상태가 live가 아니게 되면 update cycle에서 종료된다.

## 6. 남은 리스크

- 실제 기기에서 ActivityKit 권한/기기 설정에 따라 start가 거부될 수 있다.
- Dynamic Island 미지원 기기에서는 Lock Screen만 검증 가능하다.
- remote push update는 MVP 범위 밖이다. 현재 구현은 앱이 켜져 있고 목록이 갱신될 때 local update를 수행한다.
