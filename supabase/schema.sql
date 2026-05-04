-- Today Meal AI Supabase schema.
-- Apply in Supabase SQL editor. All personal tables use RLS.

create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  nickname text,
  gender text check (gender in ('male', 'female', 'other')),
  birth_date date,
  height_cm numeric,
  weight_kg numeric,
  target_weight_kg numeric,
  activity_level text check (activity_level in ('sedentary', 'light', 'moderate', 'active', 'veryActive')),
  goal_type text check (goal_type in ('loss', 'maintain', 'gain')),
  sleep_time time,
  target_kcal numeric,
  bmr numeric,
  tdee numeric,
  bmi numeric,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id)
);

create table if not exists public.weight_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  weight_kg numeric not null,
  bmi numeric,
  logged_at timestamptz not null default now()
);

create table if not exists public.meal_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  meal_type text not null check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack')),
  image_url text,
  eaten_at timestamptz not null,
  started_at timestamptz,
  finished_at timestamptz,
  total_kcal numeric not null default 0,
  total_carbs numeric not null default 0,
  total_protein numeric not null default 0,
  total_fat numeric not null default 0,
  ai_detected boolean not null default false,
  ai_confidence text,
  note text,
  created_at timestamptz not null default now()
);

create table if not exists public.meal_items (
  id uuid primary key default gen_random_uuid(),
  meal_log_id uuid not null references public.meal_logs(id) on delete cascade,
  food_name text not null,
  food_id text,
  intake_gram numeric not null,
  kcal numeric not null default 0,
  carbs numeric not null default 0,
  protein numeric not null default 0,
  fat numeric not null default 0,
  source text not null default 'manual' check (source in ('manual', 'mock_ai', 'vlm')),
  confidence text,
  created_at timestamptz not null default now()
);

create table if not exists public.daily_summaries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  date_key date not null,
  total_kcal numeric not null default 0,
  total_carbs numeric not null default 0,
  total_protein numeric not null default 0,
  total_fat numeric not null default 0,
  breakfast_kcal numeric not null default 0,
  lunch_kcal numeric not null default 0,
  dinner_kcal numeric not null default 0,
  snack_kcal numeric not null default 0,
  report_text text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, date_key)
);

create table if not exists public.ai_analysis_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  meal_log_id uuid references public.meal_logs(id) on delete set null,
  image_url text,
  provider text,
  raw_result jsonb,
  detected_foods jsonb,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.weight_logs enable row level security;
alter table public.meal_logs enable row level security;
alter table public.meal_items enable row level security;
alter table public.daily_summaries enable row level security;
alter table public.ai_analysis_logs enable row level security;

create policy "profiles_select_own" on public.profiles for select using (user_id = auth.uid());
create policy "profiles_insert_own" on public.profiles for insert with check (user_id = auth.uid());
create policy "profiles_update_own" on public.profiles for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "profiles_delete_own" on public.profiles for delete using (user_id = auth.uid());

create policy "weight_logs_select_own" on public.weight_logs for select using (user_id = auth.uid());
create policy "weight_logs_insert_own" on public.weight_logs for insert with check (user_id = auth.uid());
create policy "weight_logs_update_own" on public.weight_logs for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "weight_logs_delete_own" on public.weight_logs for delete using (user_id = auth.uid());

create policy "meal_logs_select_own" on public.meal_logs for select using (user_id = auth.uid());
create policy "meal_logs_insert_own" on public.meal_logs for insert with check (user_id = auth.uid());
create policy "meal_logs_update_own" on public.meal_logs for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "meal_logs_delete_own" on public.meal_logs for delete using (user_id = auth.uid());

create policy "meal_items_select_own" on public.meal_items
for select using (
  exists (select 1 from public.meal_logs ml where ml.id = meal_items.meal_log_id and ml.user_id = auth.uid())
);
create policy "meal_items_insert_own" on public.meal_items
for insert with check (
  exists (select 1 from public.meal_logs ml where ml.id = meal_items.meal_log_id and ml.user_id = auth.uid())
);
create policy "meal_items_update_own" on public.meal_items
for update using (
  exists (select 1 from public.meal_logs ml where ml.id = meal_items.meal_log_id and ml.user_id = auth.uid())
) with check (
  exists (select 1 from public.meal_logs ml where ml.id = meal_items.meal_log_id and ml.user_id = auth.uid())
);
create policy "meal_items_delete_own" on public.meal_items
for delete using (
  exists (select 1 from public.meal_logs ml where ml.id = meal_items.meal_log_id and ml.user_id = auth.uid())
);

create policy "daily_summaries_select_own" on public.daily_summaries for select using (user_id = auth.uid());
create policy "daily_summaries_insert_own" on public.daily_summaries for insert with check (user_id = auth.uid());
create policy "daily_summaries_update_own" on public.daily_summaries for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "daily_summaries_delete_own" on public.daily_summaries for delete using (user_id = auth.uid());

create policy "ai_analysis_logs_select_own" on public.ai_analysis_logs for select using (user_id = auth.uid());
create policy "ai_analysis_logs_insert_own" on public.ai_analysis_logs for insert with check (user_id = auth.uid());
create policy "ai_analysis_logs_update_own" on public.ai_analysis_logs for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "ai_analysis_logs_delete_own" on public.ai_analysis_logs for delete using (user_id = auth.uid());
