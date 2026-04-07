# 2026-04-07 — Phase 1 + Phase 2 초기 구현

## 추가된 파일

| 파일 | 역할 |
|------|------|
| `pubspec.yaml` | 패키지 의존성 정의 (supabase_flutter, flutter_riverpod, google_sign_in, hive_flutter 등) |
| `lib/main.dart` | 앱 진입점. Hive/Supabase 초기화, ProviderScope, AuthGate, AppShell(NavigationBar) |
| `lib/core/env.dart` | `--dart-define`으로 주입된 환경변수 상수 (SUPABASE_URL, SUPABASE_ANON_KEY) |
| `lib/core/supabase_client.dart` | `Supabase.instance.client` getter 단일 접근점 |
| `lib/core/theme.dart` | Material 3 테마, 강조색 kMint(`#5ECFB1`), 라이트/다크 대응 |
| `lib/models/todo_item.dart` | Todo 데이터 모델. fromMap/toMap, 날짜 포맷(`M월 D일`) |
| `lib/repositories/todo_repository.dart` | TodoRepository abstract interface |
| `lib/repositories/supabase_todo_repo.dart` | Supabase 구현체. CRUD + Realtime + 오프라인 큐 통합 |
| `lib/repositories/local_queue_repo.dart` | Hive 기반 오프라인 큐. 오프라인 작업 저장 → 온라인 복귀 시 flush |
| `lib/providers/auth_provider.dart` | authStateProvider(세션 스트림), currentUserProvider |
| `lib/providers/todo_provider.dart` | todoRepositoryProvider, activeTodosProvider, archivedTodosProvider |
| `lib/providers/connectivity_provider.dart` | connectivity_plus 기반 네트워크 상태 감시 |
| `lib/screens/auth/login_screen.dart` | 이메일/비밀번호 + Google OAuth 로그인 화면 |
| `lib/screens/auth/signup_screen.dart` | 이메일 회원가입 (이메일 인증 없음) |
| `lib/screens/main_screen.dart` | 미완료 Todo 목록 + 하단 플로팅 입력창 |
| `lib/screens/archive_screen.dart` | 완료된 Todo 목록. 롱프레스로 복구/영구 삭제 |
| `lib/screens/settings_screen.dart` | 계정 정보 표시, 로그아웃 |
| `lib/widgets/todo_tile.dart` | Todo 항목 위젯. 원형 체크박스 + 200ms 페이드아웃 애니메이션 |
| `supabase/migrations/001_init.sql` | todos 테이블 생성, RLS 정책, Realtime publication 설정 |
| `CLAUDE.md` | 프로젝트 컨텍스트 문서 (Claude Code용) |

## 변경된 파일

없음 (신규 프로젝트)

## 주요 결정
- Apple 로그인 제외 (Apple Developer 결제 필요)
- 이메일 인증 비활성화 (단독 사용자)
- iOS 위젯 제외 (Windows 개발 환경)
- 오프라인 충돌 정책: Last Write Wins
