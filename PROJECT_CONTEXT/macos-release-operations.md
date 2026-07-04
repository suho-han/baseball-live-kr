# macOS Release And Remote Test Operations

작성일: 2026-06-17

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
- `.background/dmg-background.png` Finder 배경 이미지

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
KBO_USE_TEST_LIVE_GAME=1 FORCE_RESTART=1 PORT=3000 ./scripts/run-macos-app-with-packaged-backend.sh
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

## 7. Signing And Notarization

현재 상태:

- Debug/local 검증은 Xcode `Sign to Run Locally` 기준이다.
- notarization은 아직 release 필수 경로가 아니다.
- 외부 사용자 테스트용 `.dmg`는 `scripts/package-macos-dmg.sh`로 생성한다.
- DMG 패키징 시 스테이징된 앱을 ad-hoc으로 재서명(`codesign --force --sign -`)하고 `codesign --verify --strict --deep`로 검증한다. 서명 seal이 깨진 채 배포되면 사용자 Mac에서 `Open Anyway` 경로가 없는 "손상됨" 오류가 나기 때문이다. ad-hoc 서명이므로 Gatekeeper "확인할 수 없음" 경고 자체는 notarization 전까지 계속 나온다.
- public distribution용 signed/notarized archive는 별도 후속 작업으로 둔다.

Release readiness procedure when Developer ID credentials are available:

```bash
APP_PRODUCT_NAME=BaseballLiveKR
APP_BUNDLE=".xcode/DerivedData/Build/Products/Release/${APP_PRODUCT_NAME}.app"
APP_ZIP=".build/transfer/${APP_PRODUCT_NAME}.zip"

xcodebuild -project BaseballLiveKR.xcodeproj \
  -scheme BaseballLiveKRmacOS \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath .xcode/DerivedData \
  CODE_SIGN_STYLE=Manual \
  OTHER_CODE_SIGN_FLAGS='--options runtime' \
  build

ditto -c -k --keepParent \
  "${APP_BUNDLE}" \
  "${APP_ZIP}"

xcrun notarytool submit "${APP_ZIP}" \
  --keychain-profile baseball-live-kr-notary \
  --wait

xcrun stapler staple "${APP_BUNDLE}"
xcrun stapler validate "${APP_BUNDLE}"
spctl --assess --type execute --verbose=4 "${APP_BUNDLE}"
```

Credentials required:

- Developer ID Application certificate in the build keychain
- `notarytool` keychain profile named `baseball-live-kr-notary`
- Hardened runtime enabled for release signing

후속 결정:

- Developer ID Application 인증서 사용 여부
- hardened runtime 설정
- notarization 자동화 위치
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
