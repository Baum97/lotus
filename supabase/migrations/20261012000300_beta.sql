-- Lotus – Funktionen für die Beta: Profil speichern, Status, Selfie-Verifizierung,
-- Admin-Bereich, Konto löschen, Push-Tokens, Spam-Erkennung, Datei-Speicher.

-- ---------------------------------------------------------------------------
-- Tabellen
-- ---------------------------------------------------------------------------

create table private.admins (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now()
);

create type public.verification_status as enum ('awaiting_selfie', 'pending', 'approved', 'rejected');

create table public.verification_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  gesture text not null,
  selfie_path text,
  status public.verification_status not null default 'awaiting_selfie',
  note text,
  created_at timestamptz not null default now(),
  submitted_at timestamptz,
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles (id) on delete set null
);
create unique index verification_requests_open_idx on public.verification_requests (user_id)
  where status in ('awaiting_selfie', 'pending');

-- Anonyme Abmelde-Statistik (Nordstern-Metrik: "Ich habe jemanden gefunden")
create table private.account_deletions (
  id bigint generated always as identity primary key,
  found_someone boolean not null,
  feedback text check (char_length(feedback) <= 1000),
  created_at timestamptz not null default now()
);

create table public.device_tokens (
  token text primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  platform text not null check (platform in ('android', 'ios', 'web')),
  updated_at timestamptz not null default now()
);
create index device_tokens_user_idx on public.device_tokens (user_id);

-- ---------------------------------------------------------------------------
-- Hilfsfunktionen
-- ---------------------------------------------------------------------------

create function private.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from private.admins a where a.user_id = auth.uid())
$$;

create function private.require_admin() returns uuid
language plpgsql stable security definer set search_path = '' as $$
declare
  v_me uuid := private.current_user_id();
begin
  if not private.is_admin() then
    perform private.fail('not_admin');
  end if;
  return v_me;
end;
$$;

create function private.uuid_or_null(p_text text) returns uuid
language plpgsql immutable set search_path = '' as $$
begin
  return p_text::uuid;
exception when invalid_text_representation then
  return null;
end;
$$;

create function private.verification_gestures() returns text[]
language sql immutable as $$
  select array[
    'Daumen hoch und linke Hand ans Ohr',
    'Peace-Zeichen neben dem Gesicht',
    'Zeigefinger an die Nasenspitze',
    'Hand flach auf den Kopf legen',
    'Beide Daumen hoch',
    'Mit der rechten Hand winken'
  ]
$$;

-- ---------------------------------------------------------------------------
-- Profil & Status
-- ---------------------------------------------------------------------------

-- Legt das eigene Profil an oder aktualisiert es (Geburtsdatum nur beim Anlegen).
create function public.save_profile(
  p_display_name text,
  p_birthdate date,
  p_gender public.gender,
  p_bio text,
  p_city text,
  p_interested_in public.gender[],
  p_intention public.intention,
  p_intention_public boolean,
  p_age_min int,
  p_age_max int,
  p_max_distance_km int
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    perform private.fail('not_authenticated');
  end if;
  if exists (select 1 from private.trust t where t.user_id = v_uid and t.status = 'suspended') then
    perform private.fail('account_suspended');
  end if;
  if p_birthdate is null or p_birthdate > (private.berlin_today() - interval '18 years')::date then
    perform private.fail('too_young');
  end if;

  insert into public.profiles (id, display_name, birthdate, gender, bio, city)
  values (v_uid, btrim(p_display_name), p_birthdate, p_gender, nullif(btrim(p_bio), ''), nullif(btrim(p_city), ''))
  on conflict (id) do update
  set display_name = excluded.display_name,
      gender = excluded.gender,
      bio = excluded.bio,
      city = excluded.city;

  insert into public.match_preferences
    (user_id, interested_in, intention, intention_public, age_min, age_max, max_distance_km)
  values (v_uid, p_interested_in, p_intention, p_intention_public, p_age_min, p_age_max, p_max_distance_km)
  on conflict (user_id) do update
  set interested_in = excluded.interested_in,
      intention = excluded.intention,
      intention_public = excluded.intention_public,
      age_min = excluded.age_min,
      age_max = excluded.age_max,
      max_distance_km = excluded.max_distance_km,
      updated_at = now();
end;
$$;

create function public.set_location(p_lat float8, p_lon float8) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_me uuid := private.current_user_id();
begin
  if p_lat not between -90 and 90 or p_lon not between -180 and 180 then
    perform private.fail('invalid_location');
  end if;
  insert into public.profile_locations (user_id, location)
  values (v_me, extensions.st_setsrid(extensions.st_makepoint(p_lon, p_lat), 4326)::extensions.geography)
  on conflict (user_id) do update set location = excluded.location, updated_at = now();
end;
$$;

-- Alles, was die App beim Start wissen muss. Funktioniert auch ohne Profil (Onboarding).
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
  active_chats int
)
language sql stable security definer set search_path = '' as $$
  select
    p.id is not null,
    exists (select 1 from public.match_preferences mp where mp.user_id = auth.uid()),
    exists (select 1 from public.profile_locations l where l.user_id = auth.uid()),
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
    private.active_chat_count(auth.uid())
  from (select auth.uid() as uid) me
  left join public.profiles p on p.id = me.uid
  where me.uid is not null
$$;

-- Matches & Chats für die Übersicht (aktive, wartende und kürzlich beendete)
create function public.get_matches()
returns table (
  match_id uuid,
  state public.match_state,
  close_reason public.match_close_reason,
  other_user uuid,
  display_name text,
  verified boolean,
  created_at timestamptz,
  last_activity_at timestamptz,
  last_message text,
  last_message_mine boolean
)
language sql stable security definer set search_path = '' as $$
  select m.id, m.state, m.close_reason, o.id, o.display_name, o.verified_at is not null, m.created_at,
         coalesce(m.closed_at, m.last_message_at, m.activated_at, m.created_at),
         lm.body, lm.sender_id = auth.uid()
  from public.matches m
  join public.profiles o on o.id = case when m.user_a = auth.uid() then m.user_b else m.user_a end
  left join lateral (
    select msg.body, msg.sender_id from public.messages msg
    where msg.match_id = m.id order by msg.created_at desc limit 1
  ) lm on true
  where auth.uid() in (m.user_a, m.user_b)
    and (m.state <> 'closed' or m.closed_at > now() - interval '3 days')
  order by (m.state = 'active') desc, (m.state = 'queued') desc,
           coalesce(m.closed_at, m.last_message_at, m.activated_at, m.created_at) desc
$$;

-- ---------------------------------------------------------------------------
-- Selfie-Verifizierung (Gesten-Selfie, in der Beta manuell geprüft)
-- ---------------------------------------------------------------------------

create function public.start_verification()
returns table (request_id uuid, gesture text, status public.verification_status)
language plpgsql security definer set search_path = '' as $$
#variable_conflict use_column
declare
  v_me uuid := private.current_user_id();
  v_gestures text[] := private.verification_gestures();
begin
  if exists (select 1 from public.profiles p where p.id = v_me and p.verified_at is not null) then
    perform private.fail('already_verified');
  end if;

  if not exists (
    select 1 from public.verification_requests v
    where v.user_id = v_me and v.status in ('awaiting_selfie', 'pending')
  ) then
    insert into public.verification_requests (user_id, gesture)
    values (v_me, v_gestures[1 + floor(random() * cardinality(v_gestures))::int]);
  end if;

  return query
  select v.id, v.gesture, v.status from public.verification_requests v
  where v.user_id = v_me and v.status in ('awaiting_selfie', 'pending');
end;
$$;

create function public.submit_verification(p_request uuid, p_selfie_path text) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_me uuid := private.current_user_id();
begin
  if p_selfie_path is null or split_part(p_selfie_path, '/', 1) <> v_me::text then
    perform private.fail('invalid_selfie_path');
  end if;
  update public.verification_requests
  set selfie_path = p_selfie_path, status = 'pending', submitted_at = now()
  where id = p_request and user_id = v_me and status = 'awaiting_selfie';
  if not found then
    perform private.fail('verification_not_found');
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Admin-Bereich
-- ---------------------------------------------------------------------------

create function public.admin_pending_verifications()
returns table (request_id uuid, user_id uuid, display_name text, gesture text, selfie_path text,
               photo_paths text[], submitted_at timestamptz)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform private.require_admin();
  return query
  select v.id, v.user_id, p.display_name, v.gesture, v.selfie_path,
         array(select ph.storage_path from public.photos ph where ph.user_id = v.user_id order by ph.position),
         v.submitted_at
  from public.verification_requests v
  join public.profiles p on p.id = v.user_id
  where v.status = 'pending'
  order by v.submitted_at;
end;
$$;

create function public.admin_review_verification(p_request uuid, p_approve boolean, p_note text default null)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_admin uuid := private.require_admin();
  v_user uuid;
begin
  update public.verification_requests
  set status = case when p_approve then 'approved'::public.verification_status else 'rejected' end,
      note = p_note, reviewed_at = now(), reviewed_by = v_admin
  where id = p_request and status = 'pending'
  returning user_id into v_user;
  if v_user is null then
    perform private.fail('verification_not_found');
  end if;
  if p_approve then
    update public.profiles set verified_at = now() where id = v_user;
  end if;
end;
$$;

create function public.admin_recent_photos(p_limit int default 50)
returns table (photo_id uuid, user_id uuid, display_name text, storage_path text,
               moderation public.moderation_state, created_at timestamptz)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform private.require_admin();
  return query
  select ph.id, ph.user_id, p.display_name, ph.storage_path, ph.moderation, ph.created_at
  from public.photos ph
  join public.profiles p on p.id = ph.user_id
  where ph.moderation = 'pending'
  order by ph.created_at
  limit least(greatest(p_limit, 1), 200);
end;
$$;

create function public.admin_set_photo_moderation(p_photo uuid, p_state public.moderation_state)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform private.require_admin();
  update public.photos set moderation = p_state where id = p_photo;
  if not found then
    perform private.fail('photo_not_found');
  end if;
end;
$$;

create function public.admin_open_reports()
returns table (report_id uuid, reported uuid, reported_name text, reporter_name text,
               reason public.report_reason, details text, created_at timestamptz,
               reports_against_user bigint, trust_status public.trust_status)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform private.require_admin();
  return query
  select r.id, r.reported, rp.display_name, rr.display_name, r.reason, r.details, r.created_at,
         (select count(*) from public.reports x where x.reported = r.reported),
         t.status
  from public.reports r
  join public.profiles rp on rp.id = r.reported
  join public.profiles rr on rr.id = r.reporter
  left join private.trust t on t.user_id = r.reported
  where r.resolved_at is null
  order by (r.reason in ('scam', 'underage', 'harassment')) desc, r.created_at;
end;
$$;

-- Erledigt eine Meldung und setzt optional den Trust-Status der gemeldeten Person.
create function public.admin_resolve_report(p_report uuid, p_status public.trust_status default null,
                                            p_reason text default null)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_reported uuid;
begin
  perform private.require_admin();
  update public.reports set resolved_at = now()
  where id = p_report and resolved_at is null
  returning reported into v_reported;
  if v_reported is null then
    perform private.fail('report_not_found');
  end if;
  if p_status is not null then
    perform public.admin_set_trust_status(v_reported, p_status, p_reason);
  end if;
end;
$$;

create function public.admin_set_trust_status(p_user uuid, p_status public.trust_status, p_reason text default null)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform private.require_admin();
  update private.trust set status = p_status, reason = p_reason, updated_at = now() where user_id = p_user;
  if not found then
    perform private.fail('profile_not_found');
  end if;
  insert into private.trust_events (user_id, signal, details)
  values (p_user, 'admin_status_change', jsonb_build_object('status', p_status, 'reason', p_reason, 'by', auth.uid()));
  -- Gesperrte Accounts verlieren alle offenen Matches
  if p_status = 'suspended' then
    update public.matches
    set state = 'closed', closed_at = now(), close_reason = 'blocked'
    where state <> 'closed' and p_user in (user_a, user_b);
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Konto löschen ("Ich habe jemanden gefunden")
-- ---------------------------------------------------------------------------

-- Die App löscht vorher die eigenen Dateien im Storage; hier werden alle Daten
-- per Cascade entfernt. Gespeichert wird nur anonym, ob die Person jemanden gefunden hat.
create function public.delete_my_account(p_found_someone boolean, p_feedback text default null)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    perform private.fail('not_authenticated');
  end if;
  insert into private.account_deletions (found_someone, feedback)
  values (coalesce(p_found_someone, false), nullif(btrim(p_feedback), ''));
  delete from auth.users where id = v_uid;
end;
$$;

-- ---------------------------------------------------------------------------
-- Push-Benachrichtigungen
-- ---------------------------------------------------------------------------

create function public.register_device_token(p_token text, p_platform text) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_me uuid := private.current_user_id();
begin
  insert into public.device_tokens (token, user_id, platform)
  values (p_token, v_me, p_platform)
  on conflict (token) do update set user_id = excluded.user_id, platform = excluded.platform, updated_at = now();
end;
$$;

-- ---------------------------------------------------------------------------
-- Spam-Erkennung: dieselbe Nachricht an viele Matches
-- ---------------------------------------------------------------------------

create function private.detect_repeated_messages() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_matches int;
begin
  if char_length(new.body) < 20 then
    return null;
  end if;
  select count(distinct m.match_id) into v_matches
  from public.messages m
  where m.sender_id = new.sender_id
    and m.body = new.body
    and m.created_at > now() - interval '24 hours';

  if v_matches >= 3 then
    insert into private.trust_events (user_id, signal, details)
    values (new.sender_id, 'repeated_message', jsonb_build_object('matches', v_matches));
  end if;
  if v_matches >= 5 then
    update private.trust
    set status = 'restricted', reason = 'Gleiche Nachricht an viele Matches', updated_at = now()
    where user_id = new.sender_id and status = 'active';
  end if;
  return null;
end;
$$;

create trigger messages_detect_repeated
after insert on public.messages
for each row execute function private.detect_repeated_messages();

-- Alte Impressionen werden nur für Fairness (7 Tage) und Sichtbarkeit gebraucht
create function private.cleanup_impressions() returns void
language sql security definer set search_path = '' as $$
  delete from public.impressions where shown_on < private.berlin_today() - 60
$$;

-- ---------------------------------------------------------------------------
-- Rechte & RLS
-- ---------------------------------------------------------------------------

revoke all on public.verification_requests, public.device_tokens from anon, authenticated;
revoke all on private.admins, private.account_deletions from anon, authenticated;

grant select on public.verification_requests to authenticated;
grant select, delete on public.device_tokens to authenticated;

alter table public.verification_requests enable row level security;
alter table public.device_tokens enable row level security;
alter table private.admins enable row level security;
alter table private.account_deletions enable row level security;

create policy verification_requests_own on public.verification_requests
  for select to authenticated
  using (user_id = (select auth.uid()));
create policy device_tokens_own on public.device_tokens
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

revoke execute on function
  private.is_admin(), private.require_admin(), private.uuid_or_null(text), private.verification_gestures(),
  private.detect_repeated_messages(), private.cleanup_impressions(),
  public.save_profile(text, date, public.gender, text, text, public.gender[], public.intention, boolean, int, int, int),
  public.set_location(float8, float8),
  public.get_my_status(),
  public.get_matches(),
  public.start_verification(),
  public.submit_verification(uuid, text),
  public.admin_pending_verifications(),
  public.admin_review_verification(uuid, boolean, text),
  public.admin_recent_photos(int),
  public.admin_set_photo_moderation(uuid, public.moderation_state),
  public.admin_open_reports(),
  public.admin_resolve_report(uuid, public.trust_status, text),
  public.admin_set_trust_status(uuid, public.trust_status, text),
  public.delete_my_account(boolean, text),
  public.register_device_token(text, text)
from public, anon, authenticated;

-- In Storage-Policies verwendet
grant execute on function private.is_admin(), private.uuid_or_null(text) to authenticated;

grant execute on function
  public.save_profile(text, date, public.gender, text, text, public.gender[], public.intention, boolean, int, int, int),
  public.set_location(float8, float8),
  public.get_my_status(),
  public.get_matches(),
  public.start_verification(),
  public.submit_verification(uuid, text),
  public.admin_pending_verifications(),
  public.admin_review_verification(uuid, boolean, text),
  public.admin_recent_photos(int),
  public.admin_set_photo_moderation(uuid, public.moderation_state),
  public.admin_open_reports(),
  public.admin_resolve_report(uuid, public.trust_status, text),
  public.admin_set_trust_status(uuid, public.trust_status, text),
  public.delete_my_account(boolean, text),
  public.register_device_token(text, text)
to authenticated;

-- ---------------------------------------------------------------------------
-- Datei-Speicher (Supabase Storage)
--   photos/<user_id>/<datei>   Profilfotos – lesbar für alle, die das Profil sehen dürfen
--   selfies/<user_id>/<datei>  Verifizierungs-Selfies – nur für die Person selbst und Admins
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('photos', 'photos', false, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('selfies', 'selfies', false, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy lotus_photos_read on storage.objects
  for select to authenticated
  using (
    bucket_id = 'photos'
    and (
      private.can_view_profile(private.uuid_or_null((storage.foldername(name))[1]))
      or private.is_admin()
    )
  );
create policy lotus_photos_write on storage.objects
  for insert to authenticated
  with check (bucket_id = 'photos' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy lotus_photos_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy lotus_selfies_read on storage.objects
  for select to authenticated
  using (
    bucket_id = 'selfies'
    and ((storage.foldername(name))[1] = (select auth.uid())::text or private.is_admin())
  );
create policy lotus_selfies_write on storage.objects
  for insert to authenticated
  with check (bucket_id = 'selfies' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy lotus_selfies_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'selfies' and (storage.foldername(name))[1] = (select auth.uid())::text);

-- ---------------------------------------------------------------------------
-- Geplante Jobs
-- ---------------------------------------------------------------------------

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('lotus-cleanup-impressions', '43 3 * * *', 'select private.cleanup_impressions()');
  end if;
end;
$$;
