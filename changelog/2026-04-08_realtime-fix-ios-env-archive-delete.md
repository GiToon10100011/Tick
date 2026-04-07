# 2026-04-08 — Realtime 수정 · iOS 환경변수 · 아카이브 삭제 UI

## 변경된 파일

### `lib/repositories/supabase_todo_repo.dart`
**변경 내용:** `watchActiveTodos()` 구현 방식 교체

| 이전 | 이후 |
|------|------|
| `.stream()` (Realtime 전용) | REST 초기 fetch + `onPostgresChanges` 구독 |

**이유:**
- `.stream()`은 Realtime 연결에 완전히 의존 → `RealtimeSubscribeException(timedOut)` 발생 시 데이터 미표시
- 새 패턴: 초기 데이터는 REST로 즉시 표시, Realtime은 변경 알림(re-fetch 트리거)에만 사용
- Realtime이 실패해도 앱 정상 동작 보장

### `lib/screens/archive_screen.dart`
**변경 내용:** 삭제/복구 UX 전면 개선

| 이전 | 이후 |
|------|------|
| 롱프레스 → 바텀시트 | 스와이프(←) 삭제 + trailing 복구 버튼 |

- `Dismissible` 위젯으로 왼쪽 스와이프 → 삭제 확인 다이얼로그 → 영구 삭제
- trailing `IconButton(Icons.undo)` → 복구 + 스낵바 피드백
- 롱프레스 제거 (바텀시트 불필요해짐)

### `ios/Runner/Info.plist`
**변경 내용:** Google Client ID 하드코딩 제거

| 이전 | 이후 |
|------|------|
| 실제 Client ID 문자열 하드코딩 | `$(GOOGLE_IOS_CLIENT_ID)` xcconfig 변수 참조 |

## 추가된 파일

| 파일 | 역할 |
|------|------|
| `ios/scripts/decode_dart_defines.sh` | 빌드 시 `--dart-define` 값을 base64 디코딩 → `DartDefines.xcconfig`로 출력. Xcode Build Phase에서 실행 |
| `ios/Flutter/DartDefines.xcconfig` | (gitignore됨) 빌드 시 자동 생성. `--dart-define` 키=값 목록 |

## 변경된 설정 파일

| 파일 | 변경 내용 |
|------|-----------|
| `ios/Flutter/Debug.xcconfig` | `#include? "DartDefines.xcconfig"` 추가 |
| `ios/Flutter/Release.xcconfig` | `#include? "DartDefines.xcconfig"` 추가 |
| `.gitignore` | `ios/Flutter/DartDefines.xcconfig` 추가 |
| `CLAUDE.md` | 아키텍처/마일스톤/결정사항 업데이트 |

## Xcode 수동 설정 필요
iOS 빌드 시 Xcode에서 한 번:
- Runner Target → Build Phases → `+` → New Run Script Phase
- 내용: `"${SRCROOT}/scripts/decode_dart_defines.sh"`
- 위치: Compile Sources **이전**으로 이동
