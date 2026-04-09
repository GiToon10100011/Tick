# Tick 개인 설치 가이드

> App Store 미등록. 본인 기기에 직접 빌드해서 사용하는 방법.
> 빌드 전 프로젝트 루트에 `.env` 파일이 있어야 합니다.

---

## .env 파일 형식

```
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=eyJxxx
GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=xxxx.apps.googleusercontent.com
```

---

## macOS

### 빌드

```bash
flutter build macos --dart-define-from-file=.env
```

### 설치

```bash
cp -R build/macos/Build/Products/Release/tick.app /Applications/
```

또는 Finder에서 `build/macos/Build/Products/Release/tick.app`을 `/Applications` 폴더로 드래그.

### 실행

- Spotlight (`Cmd+Space`) → `Tick` 검색
- Dock에 드래그해서 고정 가능
- 최초 실행 시 "개발자를 확인할 수 없음" 경고 → **오른쪽 클릭 → 열기 → 열기** 로 해결

### 업데이트 방법

```bash
flutter build macos --dart-define-from-file=.env
cp -R build/macos/Build/Products/Release/tick.app /Applications/
```

기존 앱에 덮어씌우면 됩니다.

---

## Windows

> Windows PC에서 직접 빌드하거나, macOS에서 크로스빌드는 불가. Windows PC에서 실행할 것.

### 빌드 (Windows PC에서)

```bash
flutter build windows --dart-define-from-file=.env
```

### 설치

1. 빌드 결과물 폴더 전체를 보관:
   ```
   build/windows/x64/runner/Release/
   ```
   > `tick.exe` 단독 복사 불가 — 옆의 DLL 파일들이 모두 필요합니다.

2. `Release` 폴더를 원하는 위치로 이동:
   ```
   C:\Program Files\Tick\
   ```

3. `tick.exe` 우클릭 → **바로가기 만들기** → 바탕화면 또는 시작 메뉴에 배치

### 실행

- 바탕화면 바로가기 더블클릭
- 최초 실행 시 Windows Defender SmartScreen 경고 → **추가 정보 → 실행** 클릭

### 업데이트 방법

1. 기존 `C:\Program Files\Tick\` 폴더 삭제
2. 새로 빌드한 `Release\` 폴더를 동일 위치에 복사
3. 바로가기 재생성 (경로가 바뀌었으면)

---

## iPhone

> MacBook + Xcode 필요. App Store 없이 직접 설치.

### 최초 설치

```bash
# iPhone 연결 후
flutter run --release --dart-define-from-file=.env
```

iPhone에서 최초 1회:
```
설정 → 일반 → VPN 및 기기 관리 → [Apple ID] → 신뢰
```

### 7일마다 재서명

무료 Apple ID는 인증서가 7일마다 만료됩니다.

```bash
# iPhone 연결 후 동일하게 실행
flutter run --release --dart-define-from-file=.env
```

코드 변경 없이 이것만 실행하면 자동 재서명됩니다.

---

## 플랫폼 비교

| 항목 | macOS | Windows | iPhone |
|------|-------|---------|--------|
| 빌드 환경 | MacBook | Windows PC | MacBook |
| 재설치 주기 | 없음 | 없음 | 7일마다 재서명 |
| 비용 | 무료 | 무료 | 무료 |
| 홈 화면 위젯 | - | - | ✅ (WidgetKit) |
| 실시간 동기화 | ✅ | ✅ | ✅ |
