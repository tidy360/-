-- جدول واحد يخزّن كل بيانات "مكتبتي" بشكل حي وآمن على قاعدة بياناتك الحقيقية
create table if not exists app_state (
  id int primary key default 1,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz default now(),
  constraint single_row check (id = 1)
);

alter table app_state enable row level security;

create policy "allow all - app_state" on app_state for all using (true) with check (true);
