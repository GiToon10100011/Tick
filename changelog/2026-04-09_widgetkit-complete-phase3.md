# 2026-04-09 — WidgetKit Extension 완성 + Phase 3 완성도 작업

## Phase 2 완료: Swift WidgetKit Extension

### 구현 내용

**Flutter 측 (`lib/`)**
- `main.dart`: `HomeWidget.setAppGroupId('group.com.tick.tick')` 초기화
- `supabase_todo_repo.dart`: `_syncWidget()` 추가 — active todos fetch 후 자동으로 위젯 데이터 갱신
  - 최대 5개 todo 텍스트를 JSON으로 UserDefaults에 저장
  - `HomeWidget.updateWidget(iOSName: 'TickWidget')` 호출

**Swift 측 (`ios/TickWidget/TickWidget.swift`)**
- `group.com.tick.tick` App Group의 UserDefaults에서 todos 읽기
- Small(3개), Medium(5개) 위젯 크기 지원
- 민트 컬러(`#5ECFB1`) 테마, 빈 상태 UI 포함
- Timeline policy: `.never` (Flutter가 명시적으로 갱신할 때만)

### 빌드 환경 이슈 해결

| 이슈 | 해결 방법 |
|------|----------|
| CocoaPods `pod install` 실패 | xcodeproj `constants.rb`에 Xcode 26 object version 70 수동 패치 |
| Build cycle (Thin Binary ↔ Embed Extension) | Runner Build Phases에서 Thin Binary를 맨 아래로 이동 |
| 디버그 모드 연결 실패 | `Info.plist`에 `NSLocalNetworkUsageDescription`, `NSBonjourServices` 추가 |
| 릴리즈 모드에서 정상 동작 확인 | `flutter run --release --dart-define-from-file=.env` |

---

## Phase 3: 다크모드 검증 완료

`lib/core/theme.dart`의 `colorSchemeSeed: kMint` + Material 3 `useMaterial3: true` 조합이 라이트/다크 모드 색상 팔레트를 자동 생성. `main.dart`에 `theme:`/`darkTheme:` 모두 설정되어 있어 시스템 설정 따라 자동 전환됨. 별도 수정 불필요.

---

## 문서화

- `CLAUDE.md`: Phase 2 완료 표시, Phase 3 상태 갱신, 개발 환경 메모 업데이트
- `docs/install-guide.md`: macOS, Windows, iPhone 개인 설치 가이드 신규 작성

---

## 남은 항목

- `[ ]` 앱 아이콘 / 스플래시 스크린 — 이미지 에셋 필요 (사용자 제공 후 진행)
