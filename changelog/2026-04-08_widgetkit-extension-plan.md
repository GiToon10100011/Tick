# 2026-04-08 — iOS WidgetKit Extension 준비 계획

> Phase 2 보류 항목 (Windows 환경) → macOS 환경으로 전환되어 재개

---

## 아키텍처

```
Flutter App
    ↓ (todo 변경 시)
home_widget 패키지 → UserDefaults (App Group 공유 컨테이너)
                                    ↑
                            TickWidget (Swift)
                            TimelineProvider → UserDefaults 읽기
```

핵심 제약: Widget Extension은 별도 프로세스 → Flutter 앱 메모리 직접 접근 불가.
Flutter → 공유 컨테이너(UserDefaults) → Widget 단방향 데이터 흐름.

---

## 구현 체크리스트

### STEP 1 — Xcode: App Group 활성화
- [ ] `ios/Runner.xcworkspace` Xcode로 열기
- [ ] Runner 타겟 → Signing & Capabilities → `+` → App Groups
- [ ] 그룹 생성: `group.com.yourname.tick` (Bundle ID에 `group.` prefix)
- [ ] Team이 설정되어 있어야 Provisioning Profile 자동 갱신됨

### STEP 2 — Xcode: Widget Extension 타겟 추가
- [ ] File → New → Target → Widget Extension
- [ ] 설정:
  ```
  Product Name:                   TickWidget
  Bundle Identifier:              com.yourname.tick.TickWidget
  Include Configuration Intent:   체크 해제
  ```
- [ ] TickWidget 타겟 → Signing & Capabilities → App Groups → `group.com.yourname.tick` 체크

### STEP 3 — Flutter: `home_widget` 패키지 추가
- [ ] `pubspec.yaml`에 추가:
  ```yaml
  home_widget: ^0.7.0
  ```
- [ ] `flutter pub get`

### STEP 4 — Flutter 코드 수정

**`lib/main.dart`** — 앱 초기화 시:
```dart
import 'package:home_widget/home_widget.dart';

// Supabase 초기화 이후
HomeWidget.setAppGroupId('group.com.yourname.tick');
```

**`lib/repositories/supabase_todo_repo.dart`** 또는 **`lib/providers/todo_provider.dart`** — todo 변경 시:
```dart
Future<void> _syncWidgetData(List<TodoItem> activeTodos) async {
  final json = activeTodos.take(5).map((t) => t.text).toList();
  await HomeWidget.saveWidgetData('todos', jsonEncode(json));
  await HomeWidget.updateWidget(iOSName: 'TickWidgetExtension');
}
```
호출 위치: fetch 완료 후, Realtime 변경 수신 후, 오프라인 큐 flush 후.

### STEP 5 — Swift Widget 구현

Xcode 자동 생성 파일:
```
ios/TickWidget/
├── TickWidget.swift          # TimelineProvider + SwiftUI View
├── TickWidgetBundle.swift    # @main 진입점
├── Assets.xcassets/
└── Info.plist
```

**`TickWidget.swift`** 핵심 구조:
```swift
import WidgetKit
import SwiftUI

struct TodoEntry: TimelineEntry {
    let date: Date
    let todos: [String]
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(date: Date(), todos: ["할 일 로딩 중..."])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> ()) {
        completion(TodoEntry(date: Date(), todos: loadTodos()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoEntry>) -> ()) {
        let entry = TodoEntry(date: Date(), todos: loadTodos())
        completion(Timeline(entries: [entry], policy: .never))
    }

    private func loadTodos() -> [String] {
        let defaults = UserDefaults(suiteName: "group.com.yourname.tick")
        guard let json = defaults?.string(forKey: "todos"),
              let data = json.data(using: .utf8),
              let list = try? JSONDecoder().decode([String].self, from: data)
        else { return ["할 일이 없습니다"] }
        return list
    }
}
```

### STEP 6 — 테스트
- [ ] iPhone 연결 → Xcode에서 **Runner** scheme으로 Run
- [ ] 홈화면 길게 누르기 → 위젯 추가 → Tick 검색
- [ ] 앱에서 todo 추가/체크 → 위젯 갱신 확인

---

## 주의사항

| 항목 | 내용 |
|------|------|
| Bundle ID | Widget은 반드시 앱 Bundle ID의 하위 ID (`앱ID.TickWidget`) |
| App Group ID | Runner와 TickWidget 타겟 **모두** 동일한 그룹 체크 필수 |
| 데이터 크기 | UserDefaults 소량 권장 → 최대 5개 todo 텍스트만 전달 |
| 7일 재서명 | Widget도 앱과 함께 자동 재서명됨 |
| 환경변수 | Widget이 Supabase 직접 호출 안 하므로 dart-define 불필요 |
| `.never` 정책 | Flutter가 `updateWidget()` 호출할 때만 갱신 (배터리 절약) |

---

## 관련 파일 (수정 예정)

- `pubspec.yaml` — home_widget 의존성 추가
- `lib/main.dart` — setAppGroupId 초기화
- `lib/repositories/supabase_todo_repo.dart` — _syncWidgetData 호출
- `ios/TickWidget/TickWidget.swift` — 신규 생성
- `ios/TickWidget/TickWidgetBundle.swift` — 신규 생성
