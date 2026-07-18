# macOS Release And Remote Test Operations

작성일: 2026-06-17
Updated: 2026-07-09

## 1. 목적

Xcode 없이 `BaseballLiveKRmacOS` 앱과 packaged backend companion을 앱 형태로 반복 테스트하기 위한 절차를 고정한다.

## 2. Local Build

macOS app build:

```bash
xcodebuild -project BaseballLiveKR.xcodeproj \
  -scheme BaseballLiveKRmacOS \
  -destination 'platform=macOS' \
  -derivedDataPath .xcode/DerivedData \
  build
```

backend 검증:

```bash
cd backend-spike
npm run typecheck
npm test
npm run build
```

## 3. Runtime Packaging

Mac mini 전송용 runtime archive 생성:

```bash
./scripts/package-macmini-runtime.sh
```

생성물:

```text
.build/transfer/baseball-live-kr-macmini-runtime.tar.gz
```

archive 포함 항목:

- `.xcode/DerivedData/Build/Products/Debug/BaseballLiveKR.app`
- `.build/baseball-live-kr-backend-macos`
- `scripts/run-macos-app-with-packaged-backend.sh`

사용자 배포용 DMG 생성:

```bash
./scripts/package-macos-dmg.sh
```

생성물:

```text
.build/transfer/BaseballLiveKR-0.1.0-macOS.dmg
.build/transfer/BaseballLiveKR-0.1.0-macOS.dmg.sha256
```

DMG 포함 항목:

- `BaseballLiveKR.app`
- `/Applications` symlink
- `.background/dmg-background.png` Finder 화살표 이미지

DMG Finder 레이아웃 기준:

- 왼쪽 `BaseballLiveKR.app`, 오른쪽 `Applications`, 중앙 오른쪽 화살표
- 배경색/그림자 없이 투명 PNG 위 단색 굵은 화살표와 128pt 아이콘 크기
- 같은 볼륨명이 이미 마운트된 상태에서도 `hdiutil attach`가 반환한 실제 mount path의 볼륨명에 레이아웃을 기록

사용자 설치 흐름:

1. DMG를 연다.
2. 왼쪽의 큰 `BaseballLiveKR.app` 아이콘을 오른쪽의 `Applications` 폴더로 드래그한다.
3. `Applications`에서 앱을 연다.
4. notarization 전 빌드에서는 첫 실행 시 Gatekeeper 경고가 나온다. 경고 창에서 `완료`를 누르고 `시스템 설정` > `개인정보 보호 및 보안` > `보안`에서 `그래도 열기`를 선택한 뒤 재확인 창에서 다시 `그래도 열기`를 누르고 관리자 인증을 한다. 터미널 대안: `xattr -d com.apple.quarantine /Applications/BaseballLiveKR.app`

## 4. Local App + Backend 실행

```bash
PORT=3000 ./scripts/run-macos-app-with-packaged-backend.sh
```

강제 재시작:

```bash
FORCE_RESTART=1 PORT=3000 ./scripts/run-macos-app-with-packaged-backend.sh
```

live fixture 실행:

```bash
NODE_ENV=development KBO_USE_TEST_LIVE_GAME=1 FORCE_RESTART=1 PORT=3000 ./scripts/run-macos-app-with-packaged-backend.sh
```

## 5. Remote Mac Mini Smoke

runtime archive를 Mac mini에 업로드하고 backend health smoke를 실행:

```bash
SSH_TARGET=user@macmini.local \
REMOTE_DIR=/Users/suhohan/Projects/baseball-live-kr \
PORT=3019 \
./scripts/deploy-macmini-runtime.sh
```

원격 실행:

```bash
cd /Users/suhohan/Projects/baseball-live-kr
PORT=3000 ./scripts/run-macos-app-with-packaged-backend.sh
```

## 6. Remote Backend Server Deploy

backend만 원격 서버에 올리고 `systemd --user` service로 자동 시작/재시작한다:

```bash
SSH_TARGET=user@backend.example.com \
REMOTE_DIR=/home/suhohan/baseball-live-kr-backend \
PORT=17361 \
./scripts/baseball-live-kr.sh deploy-backend
```

운영 접속 주의:
- Production backend 서버는 공개 IP 직접 SSH보다 Tailscale 경로를 우선 사용한다.
- 실제 Tailnet host, SSH port, remote dir, health URL 값은 tracked 문서에 쓰지 않고 local-only `.connect/backend-deploy.env`에 둔다.
- 복구/배포를 재시도하기 전에 `.connect/backend-deploy.env`의 `SSH_TARGET`이 Tailscale host를 가리키는지 확인한다.
- 인스턴스 reboot 후 user service가 SSH 세션 종료와 함께 내려가면 `sudo loginctl enable-linger ubuntu`를 적용하고 `systemctl --user enable --now baseball-live-kr-backend.service`로 상주시킨다.

배포 루틴:

- `backend-spike` 의존성이 없거나 오래됐으면 `npm ci` 실행
- `npm run build`로 `dist` 생성
- `dist`, `package.json`, `package-lock.json`, `run-backend.command`를 archive로 묶음
- 원격 서버에서 `npm ci --omit=dev` 실행
- `~/.config/systemd/user/baseball-live-kr-backend.service` 설치
- service restart 후 `http://127.0.0.1:17361/v1/health` smoke 실행

원격 서버에서 상태 확인:

```bash
systemctl --user status baseball-live-kr-backend.service
journalctl --user -u baseball-live-kr-backend.service -f
```

명령만 확인하는 dry run:

```bash
DRY_RUN=1 ./scripts/deploy-remote-backend.sh
```

GitHub Release 기반 자동 배포:

- `.github/workflows/backend-release.yml`은 release publish 또는 수동 workflow 실행 시 `backend-spike`를 typecheck/test/build하고 `baseball-live-kr-backend-server.tar.gz` asset을 release에 업로드한다.
- `scripts/install-backend-release-updater.sh`는 원격 서버에 `systemd --user` timer와 updater script를 설치한다.
- updater는 GitHub latest release API에서 동일 asset 이름을 찾고, 새 tag면 release directory에 압축을 푼 뒤 `current` symlink를 바꾸고 backend service를 재시작한다.
- private repository에서는 원격 `~/.config/baseball-live-kr/backend-release.env`에 contents read 권한의 `GITHUB_TOKEN`을 직접 둔다. 토큰 값은 tracked 문서나 repo 파일에 기록하지 않는다.

설치:

```bash
SSH_TARGET=user@backend.example.com \
GITHUB_REPOSITORY=owner/baseball-live-kr \
REMOTE_INSTALL_ROOT=/home/suhohan/baseball-live-kr-backend \
PORT=17361 \
./scripts/baseball-live-kr.sh install-backend-release-updater
```

운영 확인:

```bash
systemctl --user status baseball-live-kr-backend-release-update.timer
systemctl --user start baseball-live-kr-backend-release-update.service
journalctl --user -u baseball-live-kr-backend-release-update.service -u baseball-live-kr-backend.service -f
```

## 7. Signing And Notarization

현재 상태:

- Debug/local 검증은 Xcode `Sign to Run Locally` 기준이다.
- notarization은 아직 release 필수 경로가 아니다.
- 외부 사용자 테스트용 `.dmg`는 `scripts/package-macos-dmg.sh`로 생성한다.
- 기본 DMG 패키징은 스테이징된 앱을 ad-hoc으로 재서명(`codesign --force --sign -`)하고 `codesign --verify --strict --deep`로 검증한다. 서명 seal이 깨진 채 배포되면 사용자 Mac에서 `Open Anyway` 경로가 없는 "손상됨" 오류가 나기 때문이다. ad-hoc 서명이므로 Gatekeeper "확인할 수 없음" 경고 자체는 notarization 전까지 계속 나온다.
- `SIGN_IDENTITY`와 `NOTARY_PROFILE`을 지정하면 같은 패키징 스크립트가 Developer ID 서명, hardened runtime signing option, 앱 번들 zip notarization, 앱 staple/validate, DMG notarization, DMG staple/validate, `spctl` 검증을 수행한다.
- IINA처럼 "인터넷에서 다운로드한 앱이며 Apple이 악성 소프트웨어를 확인했다"는 첫 실행 경고를 얻으려면 Developer ID Application 인증서로 서명한 뒤 app/DMG를 notarize하고 staple한 DMG를 Safari/GitHub Releases 등 quarantine을 보존하는 경로로 배포해야 한다.

Release readiness procedure when Developer ID credentials are available:

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

Credentials required:

- Developer ID Application certificate in the build keychain
- `notarytool` keychain profile named `baseball-live-kr-notary`
- Hardened runtime signing option, applied by `scripts/package-macos-dmg.sh` when `SIGN_IDENTITY` is set

후속 결정:

- Developer ID Application 인증서 사용 여부
- Sparkle 또는 자체 업데이트 채널 도입 여부

## 8. Versioning And Changelog

현재 XcodeGen 기준:

- `MARKETING_VERSION`: `0.1.0`
- `CURRENT_PROJECT_VERSION`: `1`

권장 정책:

- 사용자 테스트 archive 생성 시 `CURRENT_PROJECT_VERSION`을 증가시킨다.
- 기능 변경은 `feat`, 버그 수정은 `fix`, 운영 스크립트 변경은 `chore` prefix로 changelog 후보를 남긴다.
- remote smoke를 통과한 archive만 공유 대상으로 삼는다.

## 9. Pre-release Checklist

- backend `npm run typecheck` 통과
- backend `npm test` 통과
- backend `npm run build` 통과
- `BaseballLiveKRmacOS` xcodebuild 통과
- `./scripts/package-macmini-runtime.sh` 통과
- `./scripts/package-macos-dmg.sh` 통과
- `./scripts/verify-release-assets.sh .xcode/DerivedData/Build/Products .build/macmini-runtime .build/transfer` 통과
- archive 안에 `BaseballLiveKR.app`, packaged backend, run script 포함
- DMG Finder 창에 왼쪽 `BaseballLiveKR.app`, 오른쪽 `/Applications` symlink, 드래그 화살표 배경 이미지 표시
- DMG 내 앱이 `codesign --verify --strict --deep` 통과
- local `PORT=3000 ./scripts/run-macos-app-with-packaged-backend.sh` 실행 가능
- remote `deploy-macmini-runtime.sh` health smoke 통과
- remote `deploy-remote-backend.sh` service restart와 health smoke 통과
- 실제 경기 데이터 또는 live fixture로 메뉴바/메인 화면 확인
- release 후보는 `TeamBrandAssets`, `TeamWordmarks`, `TeamLogos`, logo, wordmark, emblem, mascot, team-ID PNG 파일명을 포함하지 않음
