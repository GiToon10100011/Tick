# Todo 앱 기획안 — *Tick* (v2.0)

> 경량·크로스플랫폼 Todo 앱 | Supabase 기반 계정 동기화 | iOS 위젯 지원

---

## 1. 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 앱 이름 (가칭) | **Tick** |
| 플랫폼 | iOS, macOS, Windows |
| 핵심 가치 | 극도의 경량성 · 빠른 입력 · 기기 간 완벽 동기화 |
| 프론트엔드 | Flutter (iOS/macOS/Windows 단일 코드베이스) |
| 백엔드 | Supabase (Auth + PostgreSQL + Realtime) |
| iOS 위젯 | Swift + WidgetKit |

---

## 2. 핵심 컨셉

- Todo 추가 시 **날짜(일 단위)**만 표시 — 시간 불필요
- 체크 완료 시 **메인 뷰에서 즉시 사라짐** (삭제 아님, 아카이브로 이동)
- 아카이브는 별도 탭/뷰에서 조회 가능
- **계정 기반 동기화** — iOS / macOS / Windows 어디서나 동일한 데이터
- 위젯에서는 **미완료 항목 목록만** 표시, 탭 시 앱 실행

---

## 3. 플랫폼별 지원 현황

| 기능 | iOS | macOS | Windows |
|------|:---:|:-----:|:-------:|
| Todo 추가/완료/아카이브 | ✅ | ✅ | ✅ |
| 아카이브 조회 | ✅ | ✅ | ✅ |
| 계정 로그인 / 동기화 | ✅ | ✅ | ✅ |
| 실시간 동기화 (Realtime) | ✅ | ✅ | ✅ |
| 홈화면 위젯 | ✅ | ❌ | ❌ |
| 오프라인 임시 저장 | ✅ | ✅ | ✅ |
| 다크모드 | ✅ | ✅ | ✅ |

---

## 4. 정보 구조 (IA)

```
Tick
├── 인증 플로우
│   ├── 로그인 화면
│   └── 회원가입 화면
└── 메인 앱 (로그인 후)
    ├── 메인 뷰 (미완료 Todo 목록)
    │   ├── Todo 항목 (텍스트 + 추가일)
    │   └── + 추가 버튼
    ├── 아카이브 뷰
    │   └── 완료된 Todo (완료일 포함)
    └── 설정 뷰
        ├── 계정 정보
        └── 로그아웃
```

화면 수: **5개** (로그인, 회원가입, 메인, 아카이브, 설정)

---

## 5. 인증 명세

### 5-1. 지원 로그인 방식

| 방식 | 제공자 | 비고 |
|------|--------|------|
| 이메일 / 비밀번호 | Supabase Auth | 이메일 인증 링크 발송 |
| Google 소셜 로그인 | Google OAuth 2.0 | 모든 플랫폼 지원 |
| Apple 소셜 로그인 | Sign in with Apple | iOS/macOS 필수 제공 (Apple 정책) |

### 5-2. 인증 플로우

```
앱 실행
    │
    ├─ 세션 있음 → 메인 뷰로 바로 이동
    │
    └─ 세션 없음 → 로그인 화면
            ├─ 이메일/비밀번호 입력 → Supabase signInWithPassword
            ├─ Google 로그인 → OAuth → Supabase 세션 발급
            └─ Apple 로그인 → Sign in with Apple → Supabase 세션 발급
```

### 5-3. 세션 관리

- Supabase Flutter SDK가 세션 자동 갱신 (refresh token)
- 앱 재시작 시 저장된 세션으로 자동 로그인
- 로그아웃 시 로컬 캐시 전체 초기화

---

## 6. 기능 명세

### 6-1. Todo 추가

- 하단 플로팅 입력창으로 텍스트 입력
- 확인 시 즉시 **Supabase DB에 INSERT** + 로컬 상태 반영
- 추가된 항목에 **오늘 날짜 자동 태그** (예: `4월 7일`)
- 날짜 포맷: `M월 D일` (연도는 올해가 아닌 경우에만 표시)

### 6-2. Todo 완료 (체크)

- 좌측 원형 체크박스 탭/클릭
- 즉시 메인 목록에서 **페이드아웃 후 아카이브 이동**
- Supabase DB: `is_archived = true`, `done_at = now()` 업데이트
- 완료 후 **2초 이내 Undo 스낵바** 제공 (DB 롤백)

### 6-3. 아카이브 뷰

- 완료된 항목을 완료일 역순으로 표시
- 각 항목: 텍스트 + 추가일 + 완료일
- 롱프레스: **완료 취소(복구)** 또는 **영구 삭제**

### 6-4. 실시간 동기화

- Supabase Realtime으로 다른 기기 변경사항 즉시 반영
- iOS에서 추가한 항목이 macOS/Windows에 실시간으로 나타남
- 네트워크 끊김 시: 로컬 상태 유지 → 재연결 시 자동 동기화

### 6-5. 오프라인 대응

- 오프라인 상태에서도 Todo 추가/체크 가능 (로컬 큐에 임시 저장)
- 온라인 복귀 시 큐에 쌓인 작업을 순서대로 Supabase에 반영
- 충돌 정책: **Last Write Wins** (마지막 변경 우선)

---

## 7. Supabase 설계

### 7-1. DB 스키마

```sql
-- 사용자 테이블은 Supabase Auth 기본 제공 (auth.users)

create table public.todos (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  text        text not null,
  is_archived boolean not null default false,
  created_at  timestamptz not null default now(),
  done_at     timestamptz
);

-- 인덱스
create index on public.todos (user_id, is_archived, created_at desc);
```

### 7-2. Row Level Security (RLS)

```sql
-- RLS 활성화
alter table public.todos enable row level security;

-- 본인 데이터만 읽기/쓰기/수정/삭제 가능
create policy "todos: 본인만 접근"
  on public.todos
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
```

> RLS로 서버 없이도 사용자 간 데이터 완전 격리

### 7-3. Realtime 설정

```sql
-- Realtime 활성화
alter publication supabase_realtime add table public.todos;
```

Flutter에서 구독:

```dart
supabase.from('todos')
  .stream(primaryKey: ['id'])
  .eq('user_id', userId)
  .eq('is_archived', false)
  .order('created_at')
  .listen((data) {
    // 실시간 UI 업데이트
  });
```

### 7-4. Supabase Auth 설정

| 제공자 | 설정 항목 |
|--------|----------|
| 이메일/비밀번호 | 이메일 인증 활성화, 인증 후 앱으로 딥링크 리다이렉트 |
| Google | Google Cloud Console OAuth 클라이언트 ID/Secret 등록 |
| Apple | Apple Developer 계정 Services ID, Key 등록 |

**딥링크 설정 (이메일 인증 리다이렉트):**
```
tick://auth/callback
```

---

## 8. iOS 위젯 명세

### 8-1. 지원 크기

| 위젯 크기 | 표시 항목 수 | 비고 |
|-----------|:-----------:|------|
| Small (2×2) | 최대 3개 | 항목명만 표시 |
| Medium (4×2) | 최대 5개 | 항목명 + 추가일 |
| Large (4×4) | 최대 10개 | 항목명 + 추가일 |
| Extra Large | 최대 14개 | iPad 전용 |

### 8-2. 위젯 데이터 흐름

```
Supabase DB
    │ (앱 포그라운드 시 fetch)
    ▼
Flutter App
    │ (App Group UserDefaults에 JSON 저장)
    ▼
Swift Widget Extension
    │ (TimelineProvider가 JSON 읽기)
    ▼
iOS 홈화면 위젯 렌더링
```

- 위젯은 **앱을 통해서만** 데이터를 받음 (위젯이 직접 Supabase 호출 안 함)
- 앱이 포그라운드로 올 때마다 App Group 갱신 + `WidgetCenter.reloadAllTimelines()`
- 주기적 갱신: WidgetKit TimelineProvider 15분 간격

### 8-3. 위젯 UI 구성

```
┌──────────────────────────────┐
│  Tick                        │
├──────────────────────────────┤
│  ○ 마트 장보기         4월 7일 │
│  ○ 보고서 제출         4월 6일 │
│  ○ 운동하기            4월 5일 │
│  ・・・ 외 3개                │
└──────────────────────────────┘
```

- 위젯 탭 → 앱 메인 뷰로 딥링크 (`tick://home`)
- 미로그인 상태면 위젯에 "로그인이 필요해요" 안내

---

## 9. UI/UX 설계

### 9-1. 디자인 원칙

1. **여백 중심** — 충분한 줄 간격, 눈이 편한 레이아웃
2. **컬러 미니멀** — 흑백 + 강조색 하나 (파스텔 민트 `#5ECFB1`)
3. **애니메이션 경량** — 체크 시 페이드아웃, 추가 시 슬라이드인 (100~200ms)
4. **로그인 마찰 최소화** — 소셜 로그인 버튼 우선 배치

### 9-2. 로그인 화면

```
┌─────────────────────────────┐
│                             │
│         ✓  Tick             │  ← 앱 로고
│                             │
│  [  Google로 계속하기      ] │
│  [  Apple로 계속하기       ] │
│  ─────────── 또는 ──────────│
│  이메일 ___________________  │
│  비밀번호 _________________  │
│  [        로그인           ] │
│                             │
│       계정이 없으신가요? 가입  │
└─────────────────────────────┘
```

### 9-3. 메인 뷰

```
┌─────────────────────────────┐
│  Tick              [아카이브] │
├─────────────────────────────┤
│  ○  마트 장보기      4월 7일  │
│  ○  보고서 초안 작성  4월 6일  │
│  ○  운동 30분        4월 5일  │
│                             │
└──────────────[  + 추가  ]───┘
```

---

## 10. 기술 스택 상세

### 10-1. Flutter 주요 패키지

| 패키지 | 용도 |
|--------|------|
| `supabase_flutter` | Supabase Auth + DB + Realtime |
| `google_sign_in` | Google OAuth |
| `sign_in_with_apple` | Apple Sign In |
| `home_widget` | Flutter ↔ iOS Widget 브릿지 |
| `flutter_riverpod` | 상태 관리 |
| `connectivity_plus` | 네트워크 상태 감지 |
| `hive_flutter` | 오프라인 로컬 큐 |

### 10-2. 아키텍처 패턴

```
UI Layer (Flutter Widgets)
    │
    ▼
ViewModel Layer (Riverpod Providers)
    │
    ▼
Repository Layer
    ├─ SupabaseTodoRepository  (온라인)
    └─ LocalQueueRepository    (오프라인 큐, Hive)
```

### 10-3. 환경변수 관리

```dart
// lib/core/env.dart
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
```

빌드 시:
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJxxx
```

---

## 11. 데이터 흐름

```
[사용자 Todo 추가]
    │
    ├─ 온라인 → Supabase INSERT → Realtime으로 다른 기기에 즉시 반영
    │                          → App Group 갱신 → 위젯 리로드
    │
    └─ 오프라인 → 로컬 Hive 큐에 저장
                → 온라인 복귀 시 큐 flush → Supabase INSERT

[사용자 Todo 체크]
    │
    ├─ 온라인 → Supabase UPDATE (is_archived=true) → 메인 뷰에서 제거
    │                                              → 아카이브 뷰에 추가
    │                                              → App Group 갱신 → 위젯 리로드
    │
    └─ 오프라인 → 동일하게 큐 처리
```

---

## 12. 보안 고려사항

| 항목 | 대책 |
|------|------|
| API 키 노출 | `--dart-define`으로 빌드 시 주입, 코드에 하드코딩 금지 |
| 데이터 접근 제어 | Supabase RLS로 본인 데이터만 접근 가능 |
| 토큰 저장 | Supabase SDK가 Secure Storage에 자동 저장 |
| Apple 로그인 | `nonce` 검증 필수 (Supabase 자동 처리) |

---

## 13. 개발 마일스톤

### Phase 1 — 인증 + 기본 CRUD (3주)

- [ ] Flutter 프로젝트 셋업 (iOS/macOS/Windows)
- [ ] Supabase 프로젝트 생성 + DB 스키마 + RLS 설정
- [ ] 이메일/비밀번호 로그인 · 회원가입
- [ ] Google / Apple 소셜 로그인
- [ ] Todo 추가 / 체크 / 아카이브 기본 기능
- [ ] Realtime 구독으로 다기기 동기화

### Phase 2 — 오프라인 + iOS 위젯 (3주)

- [ ] 오프라인 큐 (Hive) + 온라인 복귀 시 sync
- [ ] Swift WidgetKit Extension
- [ ] App Group 브릿지 (`home_widget`)
- [ ] Small / Medium / Large / Extra Large 위젯
- [ ] 위젯 탭 딥링크 연결

### Phase 3 — 완성도 (2주)

- [ ] 다크모드 완전 지원
- [ ] Undo 스낵바 (체크 후 2초)
- [ ] 설정 화면 (계정 정보, 로그아웃)
- [ ] Empty State UI
- [ ] 앱 아이콘 / 스플래시 스크린
- [ ] TestFlight / macOS / Windows 배포 테스트

### Phase 4 — 로드맵

- [ ] macOS 메뉴바 미니 위젯
- [ ] Windows 시스템 트레이 배지
- [ ] 계정 삭제 (GDPR 대응)
- [ ] 태그 / 카테고리
- [ ] 반복 일정 Todo

---

## 14. 비기능 요구사항

| 항목 | 목표 |
|------|------|
| 앱 용량 | iOS 기준 25MB 이하 |
| 콜드 스타트 | 1.5초 이내 |
| 동기화 지연 | Realtime 기준 1초 이내 |
| 위젯 갱신 지연 | 앱 포그라운드 복귀 후 즉시 |
| 오프라인 동작 | 100% 오프라인 입력/체크 가능 |
| 접근성 | VoiceOver (iOS), 고대비 모드 지원 |

---

## 15. 파일 구조 (Flutter)

```
tick/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── env.dart                 # 환경변수
│   │   └── supabase_client.dart     # Supabase 초기화
│   ├── models/
│   │   └── todo_item.dart
│   ├── repositories/
│   │   ├── todo_repository.dart     # 인터페이스
│   │   ├── supabase_todo_repo.dart  # 온라인
│   │   └── local_queue_repo.dart    # 오프라인 큐
│   ├── providers/                   # Riverpod
│   │   ├── auth_provider.dart
│   │   └── todo_provider.dart
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── signup_screen.dart
│   │   ├── main_screen.dart
│   │   ├── archive_screen.dart
│   │   └── settings_screen.dart
│   └── widgets/
│       └── todo_tile.dart
├── ios/
│   ├── Runner/
│   └── TickWidget/                  # Swift WidgetKit Extension
│       ├── TickWidget.swift
│       └── TickWidgetEntryView.swift
└── pubspec.yaml
```

---

*문서 버전: v2.0 | 변경: 로컬 DB → Supabase 계정 기반 동기화 | 2026-04-07*
