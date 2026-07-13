# 개발 및 검증

이 문서는 Baseball LIVE KR을 직접 개발하거나 배포 준비를 확인할 때 필요한 명령만 모아둡니다. 앱을 실행해 보고 싶은 경우에는 README의 `./scripts/baseball-live-kr.sh run`을 먼저 사용하세요.

## 빠른 명령

```bash
./scripts/baseball-live-kr.sh run
./scripts/baseball-live-kr.sh live
./scripts/baseball-live-kr.sh open
./scripts/baseball-live-kr.sh verify
./scripts/baseball-live-kr.sh package
./scripts/baseball-live-kr.sh deploy-backend
```

## 전체 로컬 검증

```bash
./scripts/verify-local.sh
```

이 명령은 아래 항목을 순서대로 검증합니다.

- backend-spike: 테스트, TypeScript 타입 검사, production build
- BaseballLiveKRCore, BaseballLiveKRDesignSystem, BaseballLiveKRFeatures: Swift package 테스트
- macOS: Xcode 단위 테스트
- iOS와 Widget: iOS Simulator용 Xcode build

Xcode target build를 제외하고 빠르게 확인:

```bash
SKIP_XCODE=1 ./scripts/verify-local.sh
```

## Swift package

```bash
cd Packages/BaseballLiveKRCore
swift test
```

```bash
cd Packages/BaseballLiveKRFeatures
swift test
```

## Xcode project

프로젝트 파일은 `project.yml`에서 생성합니다.

```bash
/private/tmp/XcodeGen/.build/release/xcodegen generate
open BaseballLiveKR.xcodeproj
```

현재 포함 타깃:

- `BaseballLiveKRiOS`
- `BaseballLiveKRmacOS`
- `BaseballLiveKRWidgetExtension`

참고:

- 루트에 `BaseballLiveKR.xcworkspace`도 같이 두었지만, 현재 샌드박스의 `xcodebuild -workspace` 검증은 통과하지 못했습니다.
- 실제 빌드 검증은 `BaseballLiveKR.xcodeproj` 기준으로 수행했습니다.

로컬 검증에 사용한 Xcode 명령:

```bash
xcodebuild -scheme BaseballLiveKRmacOS -project BaseballLiveKR.xcodeproj -destination 'platform=macOS' -derivedDataPath .xcode/DerivedData build

xcodebuild -scheme BaseballLiveKRiOS -project BaseballLiveKR.xcodeproj -destination 'generic/platform=iOS Simulator' -derivedDataPath .xcode/DerivedData build
```

## 경기 데이터 설정

macOS 앱 기본 동작:

- `BASEBALL_LIVE_KR_BASE_URL`을 지정하지 않으면 `Production` preset의 경기 데이터를 사용합니다.
- 현재 내장 `Local`, `Staging` preset의 기본 URL은 `http://127.0.0.1:17361`입니다.
- 현재 내장 `Production` preset의 기본 URL은 `https://api.baseball-live.kro.kr`입니다.
- macOS 앱은 로컬 개발 backend 접속을 위해 HTTP loopback ATS 예외를 포함합니다.
- 앱은 기본적으로 최신 경기 정보용 주소를 호출합니다.
- iOS/macOS 앱의 설정 화면에서 `Local`, `Staging`, `Production` 데이터 주소를 선택하고 저장할 수 있습니다.
- `BASEBALL_LIVE_KR_BASE_URL` 환경변수는 `Local` preset 주소에만 사용됩니다.
- `BASEBALL_LIVE_KR_STAGING_BASE_URL`, `BASEBALL_LIVE_KR_PRODUCTION_BASE_URL`을 지정하면 설정 화면의 Staging/Production preset 초기 URL로 사용합니다.
- Production preset은 `https://api.baseball-live.kro.kr`를 기본 URL로 사용합니다.

## 데이터 서버만 실행

```bash
cd backend-spike
npm install
npm run dev
```

백그라운드 실행/종료:

```bash
./scripts/backend-start.sh
./scripts/backend-stop.sh
```

로그 확인:

```bash
tail -f backend-spike/logs/backend.log
```

Xcode 실행 전에 자동으로 백엔드를 켜고 싶으면 scheme의 `Run > Pre-actions`에 아래 스크립트를 넣습니다.

```bash
/Users/suhohan/Projects/baseball-live-kr/scripts/backend-start.sh
```

## 테스트용 경기 데이터 수집

경기 중 상황을 나중에 다시 확인할 수 있도록 저장:

```bash
./scripts/run-baseball-live-kr-fixture-capture.sh 20260616
```

저장 위치:

```text
backend-spike/logs/polling/<YYYYMMDD>/
backend-spike/fixtures/live-<YYYYMMDD>/
```

예정 경기 선발투수 시즌 기록만 수집해서 DB에 반영:

```bash
cd backend-spike
BASEBALL_LIVE_KR_DB_ENABLED=1 npm run collect:probable-pitchers -- --date 20260630 --write
```

## 배포 준비

macOS 배포와 원격 테스트 체크리스트는 `PROJECT_CONTEXT/macos-release-operations.md`를 기준으로 유지합니다.

Mac mini 테스트용 실행 파일 묶기:

```bash
./scripts/package-macmini-runtime.sh
```

Mac mini로 올리고 기본 실행 확인까지 진행:

```bash
SSH_TARGET=user@macmini.local REMOTE_DIR=/Users/suhohan/Projects/baseball-live-kr ./scripts/deploy-macmini-runtime.sh
```

외부 배포용 signed/notarized DMG 생성:

```bash
xcodebuild -project BaseballLiveKR.xcodeproj \
  -scheme BaseballLiveKRmacOS \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath .xcode/DerivedData \
  build

SIGN_IDENTITY='Developer ID Application: Your Name (TEAMID)' \
NOTARY_PROFILE=baseball-live-kr-notary \
./scripts/package-macos-dmg.sh
```

사전 요구사항은 Developer ID Application 인증서와 `xcrun notarytool store-credentials`로 저장한 keychain profile이다. `SIGN_IDENTITY`와 `NOTARY_PROFILE`을 지정하지 않으면 기존처럼 ad-hoc DMG를 만든다.

원격 backend 서버에 systemd user service로 자동 배포:

```bash
SSH_TARGET=user@backend.example.com \
REMOTE_DIR=/home/suhohan/baseball-live-kr-backend \
PORT=17361 \
./scripts/baseball-live-kr.sh deploy-backend
```

원격에 쓰기 전에 로컬에서 실행될 명령만 확인:

```bash
DRY_RUN=1 ./scripts/deploy-remote-backend.sh
```

GitHub Release를 기준으로 원격 backend 서버가 자동 배포하게 하려면 release asset workflow와 원격 polling timer를 같이 사용한다.

흐름:

1. GitHub Release를 publish한다.
2. `.github/workflows/backend-release.yml`이 `baseball-live-kr-backend-server.tar.gz` asset을 release에 업로드한다.
3. 원격 서버의 `systemd --user` timer가 GitHub latest release를 확인한다.
4. 새 tag가 있으면 asset을 내려받아 `current` symlink를 바꾸고 `baseball-live-kr-backend.service`를 재시작한다.
5. `HEALTH_URL` smoke가 통과하면 해당 tag를 배포 완료로 기록한다.

원격 서버 사전 요구사항:

```bash
node --version
npm --version
jq --version
curl --version
systemctl --user status
```

로컬에서 release용 backend archive만 만들기:

```bash
./scripts/baseball-live-kr.sh package-backend-release
```

원격 서버에 GitHub Release polling updater 설치:

```bash
SSH_TARGET=user@backend.example.com \
GITHUB_REPOSITORY=owner/baseball-live-kr \
REMOTE_INSTALL_ROOT=/home/suhohan/baseball-live-kr-backend \
PORT=17361 \
./scripts/baseball-live-kr.sh install-backend-release-updater
```

설치될 원격 파일:

```text
~/.local/bin/baseball-live-kr-backend-release-update
~/.config/baseball-live-kr/backend-release.env
~/.config/systemd/user/baseball-live-kr-backend.service
~/.config/systemd/user/baseball-live-kr-backend-release-update.service
~/.config/systemd/user/baseball-live-kr-backend-release-update.timer
```

저장소가 private이면 원격 서버의 `~/.config/baseball-live-kr/backend-release.env`에 GitHub contents read 권한 토큰을 추가한다.

```bash
GITHUB_TOKEN=...
```

timer 상태와 로그:

```bash
systemctl --user status baseball-live-kr-backend-release-update.timer
systemctl --user start baseball-live-kr-backend-release-update.service
journalctl --user -u baseball-live-kr-backend-release-update.service -u baseball-live-kr-backend.service -f
```

Production API 도메인을 backend로 연결하는 nginx proxy 설치:

```bash
sudo certbot certonly --nginx -d api.baseball-live.kro.kr

DOMAIN=api.baseball-live.kro.kr \
BACKEND_URL=http://127.0.0.1:17361 \
CERT_NAME=api.baseball-live.kro.kr \
./scripts/install-nginx-proxy.sh
```

로컬에서 원격 서버로 설정만 배포:

```bash
SSH_TARGET=user@backend.example.com \
DOMAIN=api.baseball-live.kro.kr \
BACKEND_URL=http://127.0.0.1:17361 \
CERT_NAME=api.baseball-live.kro.kr \
./scripts/deploy-nginx-proxy.sh
```

설치 후 확인:

```bash
curl -fsS https://api.baseball-live.kro.kr/v1/health
```

0.1.0 배포 준비 계획:

- 새 버전이 올라왔는지 앱에서 확인할 수 있게 하기
- 첫 배포 버전을 `0.1.0`으로 정리하기
- 버전별로 무엇이 좋아졌는지 기록하기
- macOS에서 내려받아 실행할 수 있는 파일 묶음 준비하기
- 정식 배포에 필요한 서명과 보안 확인은 다음 단계로 분리하기

## 참고 문서

- `PROJECT_CONTEXT/README.md`
- `PROJECT_CONTEXT/xcode-project-structure.md`
- `PROJECT_CONTEXT/forward-development-roadmap.md`
- `PROJECT_CONTEXT/backend-spike-results.md`
- `PROJECT_CONTEXT/production-backend-strategy.md`
- `PROJECT_CONTEXT/kbo-data-quality-regression-plan.md`
- `PROJECT_CONTEXT/kbo-data-validation-checklist.md`
- `PROJECT_CONTEXT/kbo-source-data-collection.md`
- `PROJECT_CONTEXT/app-productization-roadmap.md`
