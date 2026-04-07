# 2026-04-08 — Phase 3: Undo 스낵바 + Empty State 개선

## 변경된 파일

### `lib/screens/main_screen.dart`
**추가: Undo 스낵바**
- `_archiveTodo(id, text)` 메서드 신설
- Todo 체크 완료 시 2초짜리 SnackBar 표시
- "취소" 액션 탭 시 `restoreTodo(id)` 호출 → 메인 목록으로 복구
- `clearSnackBars()`로 연속 체크 시 이전 스낵바 즉시 제거

**개선: Empty State**
- 기존: 단순 아이콘 + 텍스트
- 변경: `TweenAnimationBuilder` (elasticOut 400ms 스케일 인) + 부제목 문구 추가
- `_EmptyState` 별도 위젯으로 분리

### `lib/screens/archive_screen.dart`
**개선: Empty State**
- main_screen과 동일한 애니메이션 패턴 적용
- 부제목: "할 일을 체크하면 여기에 쌓여요"
