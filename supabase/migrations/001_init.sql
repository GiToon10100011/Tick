-- Tick 앱 초기 스키마
-- Supabase SQL Editor에서 실행하세요

create table public.todos (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  text        text not null,
  is_archived boolean not null default false,
  created_at  timestamptz not null default now(),
  done_at     timestamptz
);

create index on public.todos (user_id, is_archived, created_at desc);

-- Row Level Security
alter table public.todos enable row level security;

create policy "todos: 본인만 접근"
  on public.todos
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Realtime 활성화
alter publication supabase_realtime add table public.todos;
