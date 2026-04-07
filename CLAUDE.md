# Tick — CLAUDE.md

> 이 파일은 Claude Code가 프로젝트 컨텍스트를 즉시 파악하기 위한 문서입니다.

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
- 체크 시 200ms 페이드아웃 애니메이션
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
│   ├── supabase_todo_repo.dart        # Supabase 구현체 + 오프라인 큐 통합
│   └── local_queue_repo.dart          # Hive 기반 오프라인 작업 큐
├── providers/
│   ├── auth_provider.dart             # authStateProvider, currentUserProvider
│   ├── todo_provider.dart             # todoRepositoryProvider, activeTodosProvider, archivedTodosProvider
│   └── connectivity_provider.dart    # connectivityProvider, isOnlineProvider
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart          # 이메일 + Google 로그인
│   │   └── signup_screen.dart         # 이메일 회원가입
│   ├── main_screen.dart               # 미완료 Todo 목록 + 하단 추가 입력창
│   ├── archive_screen.dart            # 완료 목록, 롱프레스 복구/삭제
│   └── settings_screen.dart          # 계정 이메일, 로그아웃
└── widgets/
    └── todo_tile.dart                 # 체크박스 + 페이드아웃 애니메이션
supabase/
└── migrations/001_init.sql            # todos 테이블, RLS, Realtime 설정
```

---

## 아키텍처

```
UI (ConsumerWidget)
    ↓
Riverpod Providers
    ↓
SupabaseTodoRepository
    ├── 온라인 → Supabase 직접 호출
    └── 오프라인 → LocalQueueRepository (Hive)
                  → 온라인 복귀 시 _flush() 자동 실행
```

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
- [x] 이메일/비밀번호 로그인 · 회원가입
- [x] Google 소셜 로그인
- [x] ~~Apple 소셜 로그인~~ → 제외 (Apple Developer 결제 필요)
- [x] Todo 추가 / 체크(완료) / 아카이브 기본 기능
- [x] Realtime 구독으로 다기기 동기화

### ✅ Phase 2 — 오프라인 대응
- [x] 오프라인 큐 (Hive) + 온라인 복귀 시 자동 sync
- [x] connectivity_plus 네트워크 상태 감시
- [ ] ~~Swift WidgetKit Extension~~ → 제외 (iOS/macOS 위젯, Windows 개발 환경)

### ⬜ Phase 3 — 완성도 (미진행)
- [ ] Undo 스낵바 (체크 후 2초 이내 취소)
- [ ] 다크모드 완전 검증
- [ ] Empty State UI 고도화
- [ ] 앱 아이콘 / 스플래시 스크린
- [ ] TestFlight / macOS / Windows 배포 테스트

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
| `GOOGLE_IOS_CLIENT_ID` | Google OAuth iOS Client ID |

**실행 예시:**
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJxxx \
  --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com \
  --dart-define=GOOGLE_IOS_CLIENT_ID=xxxx.apps.googleusercontent.com
```

---

## Supabase 설정 체크리스트

- [ ] `supabase/migrations/001_init.sql` SQL Editor에서 실행
- [ ] Authentication → Providers → Email → **Confirm email OFF** (이메일 인증 비활성화)
- [ ] Authentication → Providers → Google → Client ID / Secret 등록
- [ ] Realtime → `todos` 테이블 활성화 확인

---

## 주요 결정사항

| 결정 | 이유 |
|------|------|
| Apple 로그인 제외 | Apple Developer Program 연회비 필요 |
| iOS 위젯 제외 | Windows 개발 환경, Phase 4 로드맵으로 이동 |
| 이메일 인증 비활성화 | 단독 사용자 앱, 불필요한 마찰 제거 |
| Last Write Wins 충돌 정책 | 단독 사용자 → 복잡한 충돌 해결 불필요 |

---

## 커밋 컨벤션

```bash
git acp "<타입>: <설명>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

`git acp` = add + commit + push (사용자 커스텀 alias)

---

## Flutter 실행 경로 (이 환경)

```
C:/Users/tyler/Downloads/flutter_windows_3.41.6-stable/flutter/bin/flutter
```
