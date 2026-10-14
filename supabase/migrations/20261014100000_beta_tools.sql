-- Lotus – Werkzeuge für die Beta: Einladungscodes & Warteliste, Feedback, Kennzahlen.

create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------------------
-- Einladungscodes & Warteliste
-- ---------------------------------------------------------------------------
-- Solange private.settings.invite_required = 'true' ist (Standard) und es mindestens einen Admin gibt,
-- kann nur ein Profil anlegen, wer einen Code eingelöst hat oder von der Warteliste freigeschaltet wurde.
-- Ohne Admin (frisches Projekt) ist die Anmeldung offen, damit sich der erste Admin anlegen kann.

create table private.invite_codes (
  code text primary key check (code ~ '^[A-Z0-9]{8}$'),
  region text check (char_length(region) <= 40),
  note text check (char_length(note) <= 200),
  max_uses int not null default 1 check (max_uses between 1 and 1000),
  uses int not null default 0,
  expires_at timestamptz,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

create table private.invite_redemptions (
  user_id uuid primary key references auth.users (id) on delete cascade,
  code text,  -- null = von der Warteliste freigeschaltet
  region text,
  redeemed_at timestamptz not null default now()
);

-- Fehlversuche begrenzen (gegen Durchprobieren von Codes)
create table private.invite_attempts (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  attempted_at timestamptz not null default now()
);
create index invite_attempts_user_idx on private.invite_attempts (user_id, attempted_at);

create table private.waitlist (
  user_id uuid primary key references auth.users (id) on delete cascade,
  city text not null check (char_length(city) between 1 and 60),
  created_at timestamptz not null default now()
);

insert into private.settings (key, value) values ('invite_required', 'true') on conflict (key) do nothing;

create function private.invites_required() returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((select value = 'true' from private.settings where key = 'invite_required'), true)
     and exists (select 1 from private.admins)
$$;

create function private.has_access(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select not private.invites_required()
      or exists (select 1 from private.invite_redemptions r where r.user_id = p_user)
      or exists (select 1 from public.profiles p where p.id = p_user)
$$;

-- Für die App vor dem Onboarding: Brauche ich einen Code? Stehe ich auf der Warteliste?
create function public.get_access_status()
returns table (required boolean, has_access boolean, on_waitlist boolean)
language sql stable security definer set search_path = '' as $$
  select private.invites_required(),
         private.has_access(auth.uid()),
         exists (select 1 from private.waitlist w where w.user_id = auth.uid())
  where auth.uid() is not null
$$;

-- Groß-/Kleinschreibung, Leerzeichen und Bindestriche spielen keine Rolle ("k7m2-pq4x" = "K7M2PQ4X").
-- Gibt 'ok', 'invalid' oder 'slow_down' zurück statt zu werfen: Ein Fehler würde die Transaktion
-- zurückrollen und damit auch den protokollierten Fehlversuch – die Sperre griffe nie.
create function public.redeem_invite(p_code text) returns text
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_code text := upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));
  v_invite private.invite_codes;
begin
  if v_uid is null then
    perform private.fail('not_authenticated');
  end if;
  if private.has_access(v_uid) then
    return 'ok';
  end if;
  if (select count(*) from private.invite_attempts a
      where a.user_id = v_uid and a.attempted_at > now() - interval '1 hour') >= 10 then
    return 'slow_down';
  end if;

  select * into v_invite from private.invite_codes c where c.code = v_code for update;
  if v_invite.code is null or v_invite.uses >= v_invite.max_uses
     or (v_invite.expires_at is not null and v_invite.expires_at < now()) then
    insert into private.invite_attempts (user_id) values (v_uid);
    return 'invalid';
  end if;

  update private.invite_codes set uses = uses + 1 where code = v_code;
  insert into private.invite_redemptions (user_id, code, region) values (v_uid, v_code, v_invite.region);
  delete from private.waitlist where user_id = v_uid;
  return 'ok';
end;
$$;

create function public.join_waitlist(p_city text) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    perform private.fail('not_authenticated');
  end if;
  insert into private.waitlist (user_id, city) values (v_uid, btrim(p_city))
  on conflict (user_id) do update set city = excluded.city;
end;
$$;

-- Ohne Zugang kein Profil – egal über welchen Weg (gilt für App-Anfragen, nicht für Admin/Tests).
create function private.require_access() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if current_setting('role', true) = 'authenticated' and not private.has_access(new.id) then
    perform private.fail('invite_required');
  end if;
  return new;
end;
$$;

create trigger profiles_require_access
before insert on public.profiles
for each row execute function private.require_access();

-- Admin: Codes erzeugen (8 Zeichen ohne verwechselbare Zeichen wie 0/O, 1/I)
create function public.admin_create_invites(
  p_count int default 1,
  p_max_uses int default 1,
  p_region text default null,
  p_note text default null,
  p_valid_days int default 30
) returns setof text
language plpgsql security definer set search_path = '' as $$
declare
  v_admin uuid := private.require_admin();
  v_alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_code text;
  v_bytes bytea;
begin
  for i in 1 .. least(greatest(p_count, 1), 100) loop
    loop
      v_bytes := extensions.gen_random_bytes(8);
      v_code := '';
      for j in 0 .. 7 loop
        v_code := v_code || substr(v_alphabet, 1 + get_byte(v_bytes, j) % 32, 1);
      end loop;
      exit when not exists (select 1 from private.invite_codes c where c.code = v_code);
    end loop;
    insert into private.invite_codes (code, region, note, max_uses, expires_at, created_by)
    values (v_code, nullif(btrim(p_region), ''), nullif(btrim(p_note), ''), p_max_uses,
            case when p_valid_days > 0 then now() + make_interval(days => p_valid_days) end, v_admin);
    return next v_code;
  end loop;
end;
$$;

create function public.admin_list_invites()
returns table (code text, region text, note text, uses int, max_uses int, expires_at timestamptz, created_at timestamptz)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform private.require_admin();
  return query
  select c.code, c.region, c.note, c.uses, c.max_uses, c.expires_at, c.created_at
  from private.invite_codes c order by c.created_at desc limit 200;
end;
$$;

create function public.admin_list_waitlist()
returns table (user_id uuid, email text, city text, created_at timestamptz)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform private.require_admin();
  return query
  select w.user_id, u.email::text, w.city, w.created_at
  from private.waitlist w join auth.users u on u.id = w.user_id
  order by w.created_at;
end;
$$;

create function public.admin_admit_from_waitlist(p_user uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_city text;
begin
  perform private.require_admin();
  delete from private.waitlist where user_id = p_user returning city into v_city;
  if v_city is null then
    perform private.fail('not_found');
  end if;
  insert into private.invite_redemptions (user_id, code, region) values (p_user, null, v_city)
  on conflict (user_id) do nothing;
end;
$$;

-- ---------------------------------------------------------------------------
-- Feedback
-- ---------------------------------------------------------------------------

create table public.feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid default auth.uid() references auth.users (id) on delete set null,
  category text not null check (category in ('bug', 'idea', 'other')),
  message text not null check (char_length(message) between 1 and 2000),
  app_version text check (char_length(app_version) <= 40),
  platform text check (platform in ('android', 'ios', 'web')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create function public.admin_list_feedback()
returns table (id uuid, display_name text, category text, message text, app_version text, platform text,
               created_at timestamptz)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform private.require_admin();
  return query
  select f.id, p.display_name, f.category, f.message, f.app_version, f.platform, f.created_at
  from public.feedback f left join public.profiles p on p.id = f.user_id
  where f.resolved_at is null
  order by (f.category = 'bug') desc, f.created_at desc;
end;
$$;

create function public.admin_resolve_feedback(p_id uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform private.require_admin();
  update public.feedback set resolved_at = now() where id = p_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Kennzahlen (nur Summen, keine Einzelpersonen)
-- ---------------------------------------------------------------------------

-- Region grob nach Entfernung zu den Beta-Städten
create function private.beta_region(p_location extensions.geography) returns text
language sql immutable set search_path = '' as $$
  select case
    when extensions.st_dwithin(p_location, extensions.st_makepoint(9.18, 48.78)::extensions.geography, 40000) then 'Stuttgart'
    when extensions.st_dwithin(p_location, extensions.st_makepoint(9.99, 48.40)::extensions.geography, 40000) then 'Ulm'
    else 'Andere'
  end
$$;

create function public.admin_metrics(p_days int default 30) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_since timestamptz := now() - make_interval(days => least(greatest(p_days, 1), 365));
begin
  perform private.require_admin();
  return jsonb_build_object(
    'period_days', least(greatest(p_days, 1), 365),

    'users', jsonb_build_object(
      'profiles', (select count(*) from public.profiles),
      'active_7d', (select count(*) from public.profiles where last_active_at > now() - interval '7 days'),
      'discoverable', (select count(*) from private.discovery where eligible),
      'verified', (select count(*) from public.profiles where verified_at is not null),
      'with_plus', (select count(*) from private.entitlements where valid_until > now()),
      'new_in_period', (select count(*) from public.profiles where created_at > v_since)),

    -- Wer sucht wen, je Region (auffindbare Profile) – Grundlage für gezielte Einladungen
    'balance', coalesce((
      select jsonb_agg(jsonb_build_object('region', region, 'gender', gender, 'seeking', seeking, 'count', n)
                       order by region, gender, seeking)
      from (
        select private.beta_region(d.location) as region, d.gender::text as gender,
               array_to_string(array(select unnest(d.interested_in)::text order by 1), '+') as seeking,
               count(*) as n
        from private.discovery d where d.eligible
        group by 1, 2, 3
      ) b), '[]'),

    'funnel', jsonb_build_object(
      'likes', (select count(*) from public.likes where created_at > v_since and not is_like_back),
      'likes_with_comment', (select count(*) from public.likes
                             where created_at > v_since and not is_like_back and comment is not null),
      'matches', (select count(*) from public.matches where created_at > v_since),
      -- Gespräch: beide haben mindestens einmal geschrieben
      'conversations', (select count(*) from public.matches m where m.created_at > v_since
        and exists (select 1 from public.messages x where x.match_id = m.id and x.sender_id = m.user_a)
        and exists (select 1 from public.messages x where x.match_id = m.id and x.sender_id = m.user_b)),
      'deep_conversations', (select count(*) from public.matches m where m.created_at > v_since
        and (select count(*) from public.messages x where x.match_id = m.id) >= 20),
      'closed_ended', (select count(*) from public.matches where closed_at > v_since and close_reason = 'ended'),
      'closed_stale', (select count(*) from public.matches where closed_at > v_since and close_reason = 'stale'),
      'closed_blocked', (select count(*) from public.matches where closed_at > v_since and close_reason = 'blocked')),

    -- Wie oft war das Like-Budget aufgebraucht? (Person-Tage)
    'like_budget', (
      select jsonb_build_object('days_with_likes', count(*), 'days_used_up', count(*) filter (where n >= private.daily_like_limit()))
      from (
        select from_user, (created_at at time zone 'Europe/Berlin')::date, count(*) as n
        from public.likes where created_at > v_since and not is_like_back
        group by 1, 2
      ) d),

    'undos', (select count(*) from public.passes where undone_at > v_since),

    'deletions', (
      select jsonb_build_object('total', count(*), 'found_someone', count(*) filter (where found_someone))
      from private.account_deletions where created_at > v_since),

    'open', jsonb_build_object(
      'reports', (select count(*) from public.reports where resolved_at is null),
      'verifications', (select count(*) from public.verification_requests where status = 'pending'),
      'feedback', (select count(*) from public.feedback where resolved_at is null),
      'waitlist', (select count(*) from private.waitlist)),

    'invites', jsonb_build_object(
      'required', private.invites_required(),
      'codes', (select count(*) from private.invite_codes),
      'redeemed', (select count(*) from private.invite_redemptions where code is not null),
      'from_waitlist', (select count(*) from private.invite_redemptions where code is null))
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Rechte & RLS
-- ---------------------------------------------------------------------------

alter table private.invite_codes enable row level security;
alter table private.invite_redemptions enable row level security;
alter table private.invite_attempts enable row level security;
alter table private.waitlist enable row level security;
alter table public.feedback enable row level security;
revoke all on private.invite_codes, private.invite_redemptions, private.invite_attempts, private.waitlist
  from anon, authenticated;
revoke all on public.feedback from anon, authenticated;

-- Feedback: nur absenden und eigenes lesen
grant select on public.feedback to authenticated;
grant insert (category, message, app_version, platform) on public.feedback to authenticated;
create policy feedback_own_select on public.feedback
  for select to authenticated using (user_id = (select auth.uid()));
create policy feedback_own_insert on public.feedback
  for insert to authenticated with check (user_id = (select auth.uid()));

revoke execute on function
  private.invites_required(), private.has_access(uuid), private.require_access(), private.beta_region(extensions.geography),
  public.get_access_status(), public.redeem_invite(text), public.join_waitlist(text),
  public.admin_create_invites(int, int, text, text, int), public.admin_list_invites(),
  public.admin_list_waitlist(), public.admin_admit_from_waitlist(uuid),
  public.admin_list_feedback(), public.admin_resolve_feedback(uuid), public.admin_metrics(int)
from public, anon, authenticated;

grant execute on function
  public.get_access_status(), public.redeem_invite(text), public.join_waitlist(text),
  public.admin_create_invites(int, int, text, text, int), public.admin_list_invites(),
  public.admin_list_waitlist(), public.admin_admit_from_waitlist(uuid),
  public.admin_list_feedback(), public.admin_resolve_feedback(uuid), public.admin_metrics(int)
to authenticated;
