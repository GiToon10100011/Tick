# Tick — CLAUDE.md

> 이 파일은 Claude Code가 프로젝트 컨텍스트를 즉시 파악하기 위한 문서입니다.
> **마지막 업데이트: 2026-04-09**

---

## 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 앱 이름 | **Tick** |
| 설명 | 경량 크로스플랫폼 Todo 앱 |
| 플랫폼 | iOS · macOS · Windows (Flutter 단일 코드베이스) |
| 백엔드 | Supabase (Auth + PostgreSQL + Realtime) |
| 상태관리 | flutter_riverpod ^2.6.1 |
| Flutter | 3.41.6 stable / Dart 3.11.4 |

**PRD 전문**: `docs/todo_app_plan_v2.md`

---

## 핵심 컨셉

- Todo 완료 시 메인 뷰에서 즉시 사라짐 → 아카이브로 이동 (삭제 아님)
- 날짜만 표시 (`M월 D일`, 올해 아니면 연도 포함)
- 체크 시 200ms 페이드아웃 + 2초 Undo 스낵바
- 강조색: `#5ECFB1` (파스텔 민트), Material 3

---

## 파일 구조

```
lib/
├── main.dart                          # 앱 진입점, Hive/Supabase 초기화, AuthGate, AppShell
├── core/
│   ├── env.dart                       # --dart-define 환경변수 (SUPABASE_URL, SUPABASE_ANON_KEY)
│   ├── supabase_client.dart           # supabase getter
│   └── theme.dart                     # kMint 테마, 라이트/다크
├── models/
│   └── todo_item.dart                 # TodoItem, fromMap/toMap, 날짜 포맷
├── repositories/
│   ├── todo_repository.dart           # abstract interface
│   ├── supabase_todo_repo.dart        # REST 초기 fetch + onPostgresChanges Realtime + 오프라인 큐
│   └── local_queue_repo.dart          # Hive 기반 오프라인 작업 큐
├── providers/
│   ├── auth_provider.dart             # authStateProvider, currentUserProvider
│   ├── todo_provider.dart             # todoRepositoryProvider, activeTodosProvider, archivedTodosProvider
│   └── connectivity_provider.dart    # connectivityProvider, isOnlineProvider
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart          # 이메일 + Google 로그인
│   │   └── signup_screen.dart         # 이메일 회원가입 (이메일 인증 없음)
│   ├── main_screen.dart               # 미완료 Todo 목록 + 하단 추가 입력창 + Undo 스낵바
│   ├── archive_screen.dart            # 완료 목록, 스와이프 삭제, trailing 복구 버튼
│   └── settings_screen.dart          # 계정 이메일, 로그아웃
└── widgets/
    └── todo_tile.dart                 # 체크박스 + 페이드아웃 애니메이션
ios/
├── scripts/decode_dart_defines.sh     # --dart-define → DartDefines.xcconfig 디코딩 스크립트
├── Flutter/
│   ├── Debug.xcconfig                 # DartDefines.xcconfig include 포함
│   ├── Release.xcconfig               # DartDefines.xcconfig include 포함
│   └── DartDefines.xcconfig           # 빌드 시 자동 생성 (gitignore됨)
├── Runner/Info.plist                  # $(GOOGLE_IOS_CLIENT_ID) 변수 참조
└── TickWidget/                        # WidgetKit Extension (Swift)
    ├── TickWidget.swift               # TimelineProvider + SwiftUI View (Small/Medium)
    ├── TickWidgetBundle.swift         # @main 진입점
    ├── TickWidgetControl.swift        # Control Widget (Xcode 자동생성 보일러플레이트)
    └── TickWidgetLiveActivity.swift   # Live Activity (Xcode 자동생성 보일러플레이트)
supabase/
└── migrations/001_init.sql            # todos 테이블, RLS, Realtime 설정
changelog/                             # 날짜별 작업 변경 내역
```

---

## 아키텍처

```
UI (ConsumerWidget)
    ↓
Riverpod Providers
    ↓
SupabaseTodoRepository
    ├── 온라인 → REST 초기 fetch + onPostgresChanges 구독 (변경 시 re-fetch)
    └── 오프라인 → LocalQueueRepository (Hive)
                  → 온라인 복귀 시 _flush() 자동 실행
```

**Realtime 전략:**
- `.stream()` 대신 REST 초기 fetch + `onPostgresChanges` 패턴
- 초기 데이터는 항상 REST로 표시, Realtime은 변경 알림 전용
- channel ID: `active_todos_{userId}`

**인증 플로우:**
```
앱 시작 → AuthGate (authStateProvider 감시)
  세션 있음 → AppShell (MainScreen + SettingsScreen NavigationBar)
  세션 없음 → LoginScreen
```

---

## 개발 마일스톤

### ✅ Phase 1 — 인증 + 기본 CRUD
- [x] Flutter 프로젝트 셋업 (iOS/macOS/Windows)
- [x] Supabase DB 스키마 + RLS 마이그레이션 스크립트
- [x] 이메일/비밀번호 로그인 · 회원가입 (이메일 인증 없음)
- [x] Google 소셜 로그인
- [x] ~~Apple 소셜 로그인~~ → 제외 (Apple Developer 결제 필요)
- [x] Todo 추가 / 체크(완료) / 아카이브 기본 기능
- [x] Realtime 구독으로 다기기 동기화

### ✅ Phase 2 — 오프라인 대응
- [x] 오프라인 큐 (Hive) + 온라인 복귀 시 자동 sync
- [x] connectivity_plus 네트워크 상태 감시
- [x] Realtime timeout 대응 (REST+onPostgresChanges 패턴)
- [x] iOS --dart-define → plist 환경변수 연동 (decode_dart_defines.sh)
- [x] 아카이브 스와이프 삭제 (Dismissible) + trailing 복구 버튼
- [x] Swift WidgetKit Extension (home_widget, App Group, Small/Medium 위젯)

### 🔄 Phase 3 — 완성도 (진행 중)
- [x] Undo 스낵바 (체크 후 2초, 취소 시 복구)
- [x] Empty State UI 고도화 (elasticOut 애니메이션, 부제목)
- [x] 다크모드 완전 검증 (Material 3 colorSchemeSeed가 라이트/다크 자동 처리)
- [x] 플랫폼별 개인 설치 가이드 완료 (`docs/install-guide.md`)
- [ ] 앱 아이콘 / 스플래시 스크린 (이미지 에셋 필요)

### ⬜ Phase 4 — 로드맵
- [ ] macOS 메뉴바 미니 위젯
- [ ] Windows 시스템 트레이 배지
- [ ] 계정 삭제 (GDPR)
- [ ] 태그 / 카테고리
- [ ] 반복 일정 Todo

---

## 환경변수 (--dart-define)

| 키 | 설명 |
|----|------|
| `SUPABASE_URL` | Supabase 프로젝트 URL |
| `SUPABASE_ANON_KEY` | Supabase anon public key |
| `GOOGLE_WEB_CLIENT_ID` | Google OAuth Web Client ID |
| `GOOGLE_IOS_CLIENT_ID` | Google OAuth iOS Client ID (reversed URL scheme) |

**실행 예시:**
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJxxx \
  --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com \
  --dart-define=GOOGLE_IOS_CLIENT_ID=xxxx.apps.googleusercontent.com

# 또는 .env 파일로 한 번에
flutter run --dart-define-from-file=.env
```

---

## 플랫폼별 빌드 및 설치 가이드

> App Store 등록 불필요. 개인 기기에 직접 설치해서 사용.

### Windows

```bash
flutter build windows \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJxxx \
  --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com

# 또는
flutter build windows --dart-define-from-file=.env
```

- 결과물: `build/windows/x64/runner/Release/`
- **`Release` 폴더 전체**를 유지해야 함 (`tick.exe`만 이동하면 실행 불가)
- 권장: 폴더를 `C:\Program Files\Tick\`으로 이동 후 `tick.exe` 바로가기를 바탕화면/시작메뉴에 배치

### macOS

```bash
flutter build macos \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJxxx \
  --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
```

- 결과물: `build/macos/Build/Products/Release/tick.app`
- `tick.app`을 `/Applications` 폴더에 드래그 → Spotlight 검색, Dock 등록 가능
- 본인 Mac에서 직접 실행 시 별도 서명 불필요

### iPhone (App Store 없이)

**최초 1회 설정 (MacBook + Xcode 필요):**

1. `ios/Runner.xcworkspace`를 Xcode로 열기
2. `Runner` → **Signing & Capabilities** 탭
3. **Team** → Add an Account → 본인 Apple ID 로그인 (무료 계정 OK)
4. Bundle Identifier 변경: `com.내이름.tick` (유니크하게)
5. iPhone 연결 → 상단에서 기기 선택 → **▶ Run**
6. iPhone에서 최초 1회: `설정 → 일반 → VPN 및 기기 관리 → Apple ID → 신뢰`

**iOS 빌드 시 Xcode Build Phase 설정 (최초 1회):**
- Runner Target → Build Phases → `+` → New Run Script Phase
- 내용: `"${SRCROOT}/scripts/decode_dart_defines.sh"`
- 위치: **Compile Sources 이전**으로 이동
- 이 스크립트가 `--dart-define` 값을 `DartDefines.xcconfig`로 디코딩 → `$(GOOGLE_IOS_CLIENT_ID)` plist 참조 동작

**7일 후 인증서 만료 시:**
- iPhone 연결 → Xcode에서 **▶ Run** 한 번 → 자동 재서명 (코드 변경 불필요)

---

## 플랫폼 비교

| 항목 | Windows | macOS | iPhone |
|------|---------|-------|--------|
| 빌드 환경 | Windows PC | MacBook | MacBook (Xcode) |
| 설치 방법 | Release 폴더 보관 + 바로가기 | `/Applications` 드래그 | Xcode Run |
| 재설치 주기 | 없음 | 없음 | 7일마다 재서명 |
| 비용 | 무료 | 무료 | 무료 (Apple ID만 있으면 됨) |
| 실시간 동기화 | ✅ | ✅ | ✅ |

---

## Supabase 설정 체크리스트

- [ ] `supabase/migrations/001_init.sql` SQL Editor에서 실행
- [ ] Authentication → Providers → Email → **Confirm email OFF**
- [ ] Authentication → Providers → Google → Client ID / Secret 등록
- [ ] Realtime → `todos` 테이블 활성화 확인

---

## 주요 결정사항

| 결정 | 이유 |
|------|------|
| Apple 로그인 제외 | Apple Developer Program 연회비 필요 |
| App Store 미등록 | 개인 단독 사용, Xcode 직접 설치로 충분 |
| iOS WidgetKit Extension 구현 | macOS 환경으로 전환 후 구현. home_widget + App Group (group.com.tick.tick) |
| 이메일 인증 비활성화 | 단독 사용자 앱, 불필요한 마찰 제거 |
| Last Write Wins 충돌 정책 | 단독 사용자 → 복잡한 충돌 해결 불필요 |
| Realtime에 `.stream()` 미사용 | timeout 시 데이터 미표시 → REST+onPostgresChanges 분리 |
| plist 환경변수 | --dart-define 값을 xcconfig로 디코딩해 $(VAR) 참조 |

---

## 커밋 컨벤션

```bash
git acp "<타입>: <설명>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

`git acp` = add + commit + push (사용자 커스텀 alias)

---

## 개발 환경 메모

- 현재 개발 환경: **macOS** (Homebrew Flutter: `/opt/homebrew/share/flutter`)
- iOS 빌드: `flutter run --release --dart-define-from-file=.env` (릴리즈 모드 권장)
- Xcode 26 + CocoaPods 호환: xcodeproj `constants.rb`에 object version 70 수동 패치 필요
  - 경로: `~/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/xcodeproj-1.27.0/lib/xcodeproj/constants.rb`
  - `77 => 'Xcode 16.0'` 아래에 `70 => 'Xcode 26.0'` 추가
