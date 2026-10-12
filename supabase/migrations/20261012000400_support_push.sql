-- Lotus – Lotus Plus, Spenden, Beitrag bei Erfolg und Push-Benachrichtigungen.
--
-- Grundsatz (Konzept Abschnitt 6): Geld kauft nie Sichtbarkeit, Likes oder Vorteile beim Matching.
-- Lotus Plus enthält nur Komfort: Reisemodus und Statistiken über das eigene Profil.

-- ---------------------------------------------------------------------------
-- Zahlungen
-- ---------------------------------------------------------------------------

-- Spenden und Beiträge bei Erfolg. user_id bleibt nach Kontolöschung leer (anonym).
create table public.contributions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles (id) on delete set null,
  kind text not null check (kind in ('donation', 'success')),
  product_id text not null,
  amount_micros bigint,
  currency text,
  purchase_token text not null unique,
  created_at timestamptz not null default now()
);

-- Wird nur von der Edge Function verify-purchase (service_role) aufgerufen, nachdem Google
-- den Kauf bestätigt hat. Idempotent über das Kauf-Token.
create function public.record_purchase(
  p_user uuid,
  p_product_id text,
  p_purchase_token text,
  p_kind text,
  p_valid_until timestamptz default null,
  p_amount_micros bigint default null,
  p_currency text default null
) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if p_kind = 'plus' then
    insert into private.entitlements (user_id, source, valid_until, purchase_token)
    values (p_user, 'play', p_valid_until, p_purchase_token)
    on conflict (user_id) do update
    set source = 'play',
        valid_until = greatest(private.entitlements.valid_until, excluded.valid_until),
        purchase_token = excluded.purchase_token,
        updated_at = now();
  elsif p_kind in ('donation', 'success') then
    insert into public.contributions (user_id, kind, product_id, amount_micros, currency, purchase_token)
    values (p_user, p_kind, p_product_id, p_amount_micros, p_currency, p_purchase_token)
    on conflict (purchase_token) do nothing;
  else
    perform private.fail('invalid_purchase_kind');
  end if;
end;
$$;

create function public.admin_grant_plus(p_email text, p_days int default 30) returns timestamptz
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid;
  v_until timestamptz;
begin
  perform private.require_admin();
  select u.id into v_user from auth.users u join public.profiles p on p.id = u.id where lower(u.email) = lower(btrim(p_email));
  if v_user is null then
    perform private.fail('profile_not_found');
  end if;
  insert into private.entitlements (user_id, source, valid_until)
  values (v_user, 'admin', now() + make_interval(days => p_days))
  on conflict (user_id) do update
  set valid_until = greatest(private.entitlements.valid_until, now()) + make_interval(days => p_days),
      updated_at = now()
  returning valid_until into v_until;
  return v_until;
end;
$$;

-- ---------------------------------------------------------------------------
-- Lotus Plus: Reisemodus
-- ---------------------------------------------------------------------------

create function private.require_plus() returns uuid
language plpgsql stable security definer set search_path = '' as $$
declare
  v_me uuid := private.current_user_id();
begin
  if not private.has_plus(v_me) then
    perform private.fail('plus_required');
  end if;
  return v_me;
end;
$$;

-- Für eine Reise oder einen Umzug Profile an einem anderen Ort sehen (max. 30 Tage am Stück).
create function public.set_travel_location(p_lat float8, p_lon float8, p_city text, p_days int default 14)
returns timestamptz
language plpgsql security definer set search_path = '' as $$
declare
  v_me uuid := private.require_plus();
  v_until timestamptz := now() + make_interval(days => least(greatest(p_days, 1), 30));
begin
  if p_lat not between -90 and 90 or p_lon not between -180 and 180 then
    perform private.fail('invalid_location');
  end if;
  update public.profile_locations
  set travel_location = extensions.st_setsrid(extensions.st_makepoint(p_lon, p_lat), 4326)::extensions.geography,
      travel_city = nullif(btrim(p_city), ''),
      travel_until = v_until
  where user_id = v_me;
  if not found then
    perform private.fail('location_missing');
  end if;
  return v_until;
end;
$$;

create function public.clear_travel_location() returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_me uuid := private.current_user_id();
begin
  update public.profile_locations
  set travel_location = null, travel_city = null, travel_until = null
  where user_id = v_me;
end;
$$;

-- ---------------------------------------------------------------------------
-- Lotus Plus: Statistiken über das eigene Profil (nie über andere)
-- ---------------------------------------------------------------------------

create function public.get_my_stats() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_me uuid := private.require_plus();
begin
  return jsonb_build_object(
    'impressions_7d', (
      select count(*) from public.impressions i
      where i.shown = v_me and i.shown_on > private.berlin_today() - 7),
    'likes_30d', (
      select count(*) from public.likes l
      where l.to_user = v_me and l.created_at > now() - interval '30 days'),
    'comments_30d', (
      select count(*) from public.likes l
      where l.to_user = v_me and l.comment is not null and l.created_at > now() - interval '30 days'),
    'matches_30d', (
      select count(*) from public.matches m
      where v_me in (m.user_a, m.user_b) and m.created_at > now() - interval '30 days'),
    -- Welche Fotos und Antworten Likes bekommen (alle Zeiten)
    'elements', coalesce((
      select jsonb_agg(e order by e->>'likes' desc) from (
        select jsonb_build_object(
          'type', 'photo', 'label', 'Foto ' || (ph.position + 1),
          'likes', (select count(*) from public.likes l where l.target_id = ph.id),
          'comments', (select count(*) from public.likes l where l.target_id = ph.id and l.comment is not null)) as e
        from public.photos ph where ph.user_id = v_me
        union all
        select jsonb_build_object(
          'type', 'prompt', 'label', pr.text,
          'likes', (select count(*) from public.likes l where l.target_id = pa.id),
          'comments', (select count(*) from public.likes l where l.target_id = pa.id and l.comment is not null))
        from public.prompt_answers pa join public.prompts pr on pr.id = pa.prompt_id
        where pa.user_id = v_me
      ) x
    ), '[]'::jsonb)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Status um Plus und Reisemodus erweitern
-- ---------------------------------------------------------------------------

drop function public.get_my_status();

create function public.get_my_status()
returns table (
  has_profile boolean,
  has_preferences boolean,
  has_location boolean,
  photo_count int,
  prompt_count int,
  display_name text,
  verified boolean,
  verification_status public.verification_status,
  trust_status public.trust_status,
  is_admin boolean,
  likes_remaining int,
  undos_remaining int,
  active_chats int,
  plus_until timestamptz,
  travel_city text,
  travel_until timestamptz
)
language sql stable security definer set search_path = '' as $$
  select
    p.id is not null,
    exists (select 1 from public.match_preferences mp where mp.user_id = auth.uid()),
    l.user_id is not null,
    (select count(*)::int from public.photos ph where ph.user_id = auth.uid()),
    (select count(*)::int from public.prompt_answers pa where pa.user_id = auth.uid()),
    p.display_name,
    coalesce(p.verified_at is not null, false),
    (select v.status from public.verification_requests v
      where v.user_id = auth.uid() order by v.created_at desc limit 1),
    (select t.status from private.trust t where t.user_id = auth.uid()),
    private.is_admin(),
    public.likes_remaining_today(),
    public.undos_remaining_this_month(),
    private.active_chat_count(auth.uid()),
    (select e.valid_until from private.entitlements e where e.user_id = auth.uid() and e.valid_until > now()),
    case when l.travel_until > now() then l.travel_city end,
    case when l.travel_until > now() then l.travel_until end
  from (select auth.uid() as uid) me
  left join public.profiles p on p.id = me.uid
  left join public.profile_locations l on l.user_id = me.uid
  where me.uid is not null
$$;

-- ---------------------------------------------------------------------------
-- Push-Benachrichtigungen
-- ---------------------------------------------------------------------------

create table public.notification_settings (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  messages boolean not null default true,
  matches boolean not null default true,
  likes boolean not null default true,
  -- Likes werden höchstens alle 6 Stunden gemeldet (kein Dauer-Pingen)
  last_like_push_at timestamptz
);

-- Für die Edge Function: Darf diese Person jetzt eine Like-Benachrichtigung bekommen?
-- Atomar, damit gleichzeitige Likes nicht mehrere Benachrichtigungen auslösen.
create function public.claim_like_push(p_user uuid) returns boolean
language sql security definer set search_path = '' as $$
  insert into public.notification_settings as s (user_id, last_like_push_at)
  values (p_user, now())
  on conflict (user_id) do update set last_like_push_at = now()
  where s.likes and (s.last_like_push_at is null or s.last_like_push_at < now() - interval '6 hours')
  returning true
$$;

-- Konfiguration für den Aufruf der Edge Function (einmalig per SQL setzen, siehe README):
--   notify_url    https://<projekt>.supabase.co/functions/v1/notify
--   notify_secret derselbe Wert wie das Secret NOTIFY_WEBHOOK_SECRET der Function
create table private.settings (
  key text primary key,
  value text not null
);

-- Ruft die Edge Function "notify" mit demselben Format wie ein Supabase-Webhook auf.
-- Ohne Konfiguration oder ohne pg_net passiert nichts (z. B. lokal und in Tests).
create function private.notify_push() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_url text := (select value from private.settings where key = 'notify_url');
  v_secret text := (select value from private.settings where key = 'notify_secret');
begin
  if v_url is null or to_regprocedure('net.http_post(text,jsonb,jsonb,jsonb,integer)') is null then
    return null;
  end if;
  -- Zurück-Likes erzeugen ein Match; dafür gibt es die Match-Benachrichtigung.
  -- (Verschachtelt, weil PL/pgSQL "and" nicht garantiert von links auswertet und
  -- new.is_like_back bei anderen Tabellen nicht existiert.)
  if tg_table_name = 'likes' then
    if new.is_like_back then
      return null;
    end if;
  end if;
  execute 'select net.http_post(url := $1, body := $2, headers := $3)'
  using v_url,
        jsonb_build_object(
          'type', tg_op,
          'table', tg_table_name,
          'record', to_jsonb(new),
          'old_record', case when tg_op = 'UPDATE' then to_jsonb(old) end),
        jsonb_build_object('Content-Type', 'application/json', 'x-webhook-secret', coalesce(v_secret, ''));
  return null;
end;
$$;

create trigger messages_notify_push after insert on public.messages
for each row execute function private.notify_push();

create trigger matches_notify_push after insert or update of state on public.matches
for each row execute function private.notify_push();

create trigger likes_notify_push after insert on public.likes
for each row execute function private.notify_push();

do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_net') then
    create extension if not exists pg_net;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Rechte & RLS
-- ---------------------------------------------------------------------------

revoke all on public.contributions, public.notification_settings from anon, authenticated;
revoke all on private.entitlements, private.settings from anon, authenticated;

grant select on public.contributions to authenticated;
grant select on public.notification_settings to authenticated;
grant insert (user_id, messages, matches, likes), update (messages, matches, likes)
  on public.notification_settings to authenticated;

alter table public.contributions enable row level security;
alter table public.notification_settings enable row level security;
alter table private.entitlements enable row level security;
alter table private.settings enable row level security;

create policy contributions_own on public.contributions
  for select to authenticated
  using (user_id = (select auth.uid()));
create policy notification_settings_own on public.notification_settings
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

revoke execute on function
  private.require_plus(), private.notify_push(),
  public.claim_like_push(uuid),
  public.record_purchase(uuid, text, text, text, timestamptz, bigint, text),
  public.admin_grant_plus(text, int),
  public.set_travel_location(float8, float8, text, int),
  public.clear_travel_location(),
  public.get_my_stats(),
  public.get_my_status()
from public, anon, authenticated;

-- Neu angelegte Hilfsfunktionen aus der Logik-Migration (has_plus, search_location, is_traveling)
-- sind dort bereits durch "revoke … on all functions" geschützt.

grant execute on function
  public.admin_grant_plus(text, int),
  public.set_travel_location(float8, float8, text, int),
  public.clear_travel_location(),
  public.get_my_stats(),
  public.get_my_status()
to authenticated;

grant execute on function public.record_purchase(uuid, text, text, text, timestamptz, bigint, text) to service_role;
grant execute on function public.claim_like_push(uuid) to service_role;
