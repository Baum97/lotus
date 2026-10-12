-- Lotus – Grundschema
-- Siehe docs/KONZEPT.md. Alle Limits werden serverseitig durchgesetzt (Logik in 20261012000100_logic.sql).

create extension if not exists postgis with schema extensions;

-- Interne Daten (Trust & Safety, Konfiguration), für Clients nicht direkt lesbar.
create schema if not exists private;

-- ---------------------------------------------------------------------------
-- Typen
-- ---------------------------------------------------------------------------

-- Vorerst drei Optionen: weiblich, männlich, divers
create type public.gender as enum ('woman', 'man', 'diverse');
create type public.intention as enum ('relationship', 'open_to_relationship', 'unsure');
create type public.like_target as enum ('photo', 'prompt');
create type public.match_state as enum ('queued', 'active', 'closed');
create type public.match_close_reason as enum ('ended', 'stale', 'blocked');
create type public.moderation_state as enum ('pending', 'approved', 'rejected');
create type public.report_reason as enum ('fake', 'scam', 'harassment', 'inappropriate', 'underage', 'other');
create type public.trust_status as enum ('active', 'restricted', 'suspended');

-- ---------------------------------------------------------------------------
-- Profile
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 40),
  birthdate date not null check (birthdate <= current_date - interval '18 years'),
  gender public.gender not null,
  bio text check (char_length(bio) <= 500),
  city text check (char_length(city) <= 60),
  -- Nur durch die Verifizierungs-Edge-Function (service_role) setzbar
  verified_at timestamptz,
  last_active_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

-- Matching-Präferenzen – privat, nur für die eigene Person lesbar (RLS) und für das Matching.
-- Die Orientierung (interested_in) wird nie anderen angezeigt (DSGVO Art. 9).
-- Das Dating-Ziel (intention) zählt immer fürs Matching; angezeigt wird es nur, wenn intention_public.
create table public.match_preferences (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  interested_in public.gender[] not null check (cardinality(interested_in) > 0),
  intention public.intention not null,
  intention_public boolean not null default true,
  -- wirken gegenseitig, siehe get_candidates
  age_min smallint not null default 18 check (age_min >= 18),
  age_max smallint not null default 99 check (age_max <= 99 and age_max >= age_min),
  max_distance_km smallint not null default 50 check (max_distance_km between 1 and 300),
  updated_at timestamptz not null default now()
);

-- Exakter Standort getrennt von profiles, damit er nie an andere ausgeliefert wird
-- (andere sehen nur eine gerundete Entfernung).
create table public.profile_locations (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  location extensions.geography(point, 4326) not null,
  updated_at timestamptz not null default now()
);
create index profile_locations_location_idx on public.profile_locations using gist (location);

create table public.photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  storage_path text not null,
  position smallint not null check (position between 0 and 5),
  -- Beta: Fotos sind sofort sichtbar ('pending' = noch nicht geprüft); abgelehnte werden ausgeblendet
  moderation public.moderation_state not null default 'pending',
  created_at timestamptz not null default now(),
  unique (user_id, position)
);

create table public.prompts (
  id smallint generated always as identity primary key,
  text text not null unique,
  active boolean not null default true
);

create table public.prompt_answers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  prompt_id smallint not null references public.prompts (id),
  answer text not null check (char_length(answer) between 1 and 300),
  position smallint not null check (position between 0 and 2),
  created_at timestamptz not null default now(),
  unique (user_id, prompt_id),
  unique (user_id, position)
);

-- ---------------------------------------------------------------------------
-- Entscheidungen
-- ---------------------------------------------------------------------------

create table public.likes (
  id uuid primary key default gen_random_uuid(),
  from_user uuid not null references public.profiles (id) on delete cascade,
  to_user uuid not null references public.profiles (id) on delete cascade,
  -- Ein Like bezieht sich auf ein Foto oder eine Prompt-Antwort (bei Zurück-Likes optional)
  target_type public.like_target,
  target_id uuid,
  comment text check (char_length(comment) between 1 and 300),
  -- Zurück-Likes kosten kein Budget
  is_like_back boolean not null default false,
  created_at timestamptz not null default now(),
  unique (from_user, to_user),
  check (from_user <> to_user),
  check ((target_type is null) = (target_id is null)),
  check (is_like_back or target_type is not null)
);
create index likes_from_user_created_idx on public.likes (from_user, created_at);
create index likes_to_user_created_idx on public.likes (to_user, created_at desc);

create table public.passes (
  id uuid primary key default gen_random_uuid(),
  from_user uuid not null references public.profiles (id) on delete cascade,
  to_user uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  undone_at timestamptz,
  check (from_user <> to_user)
);
create unique index passes_open_unique_idx on public.passes (from_user, to_user) where undone_at is null;
create index passes_from_user_created_idx on public.passes (from_user, created_at desc);

-- Welche Profile wem gezeigt wurden: Grundlage für das Fairness-Kontingent und
-- dafür, dass man nur Profile liken kann, die einem auch vorgeschlagen wurden.
create table public.impressions (
  viewer uuid not null references public.profiles (id) on delete cascade,
  shown uuid not null references public.profiles (id) on delete cascade,
  shown_on date not null,
  primary key (viewer, shown, shown_on)
);
create index impressions_shown_idx on public.impressions (shown, shown_on);

-- ---------------------------------------------------------------------------
-- Matches & Chat
-- ---------------------------------------------------------------------------

create table public.matches (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references public.profiles (id) on delete cascade,
  user_b uuid not null references public.profiles (id) on delete cascade,
  state public.match_state not null default 'queued',
  created_at timestamptz not null default now(),
  activated_at timestamptz,
  last_message_at timestamptz,
  closed_at timestamptz,
  close_reason public.match_close_reason,
  closed_by uuid references public.profiles (id) on delete set null,
  unique (user_a, user_b),
  check (user_a < user_b),
  check ((state = 'closed') = (closed_at is not null)),
  check (state = 'queued' or activated_at is not null or state = 'closed')
);
create index matches_user_a_state_idx on public.matches (user_a, state);
create index matches_user_b_state_idx on public.matches (user_b, state);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  -- Gesetzt vom Trigger, z. B. 'link' oder 'money' → App zeigt einen Sicherheitshinweis
  safety_flag text,
  created_at timestamptz not null default now()
);
create index messages_match_created_idx on public.messages (match_id, created_at);

-- ---------------------------------------------------------------------------
-- Sicherheit
-- ---------------------------------------------------------------------------

create table public.blocks (
  blocker uuid not null references public.profiles (id) on delete cascade,
  blocked uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker, blocked),
  check (blocker <> blocked)
);
create index blocks_blocked_idx on public.blocks (blocked);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter uuid not null references public.profiles (id) on delete cascade,
  reported uuid not null references public.profiles (id) on delete cascade,
  reason public.report_reason not null,
  details text check (char_length(details) <= 1000),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  check (reporter <> reported)
);

-- Trust & Safety: liefert dem Matching nur einen Status, nie Like-Statistiken.
create table private.trust (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  status public.trust_status not null default 'active',
  reason text,
  updated_at timestamptz not null default now()
);

create table private.trust_events (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  signal text not null,
  details jsonb,
  created_at timestamptz not null default now()
);
create index trust_events_user_idx on private.trust_events (user_id, created_at desc);

-- ---------------------------------------------------------------------------
-- Prompt-Katalog
-- ---------------------------------------------------------------------------

insert into public.prompts (text) values
  ('Ein perfekter Sonntag sieht für mich so aus …'),
  ('Ich merke, dass ich jemanden mag, wenn …'),
  ('Worüber ich stundenlang reden kann:'),
  ('Mein liebster Ort in der Stadt:'),
  ('Das wünsche ich mir von einer Beziehung:'),
  ('Ein kleines Ding, das mich glücklich macht:'),
  ('Unser erstes Date sollte …'),
  ('Was mich überrascht, wenn man mich kennenlernt:'),
  ('Ich bin wirklich schlecht in …'),
  ('Ein Wert, bei dem ich keine Kompromisse mache:');
