-- Lotus – Zugriffsrechte & Row Level Security
--
-- Supabase vergibt standardmäßig alle Rechte auf neue Tabellen an anon/authenticated.
-- Wir entziehen sie und vergeben nur, was die App wirklich braucht. Alles, was Limits
-- betrifft (Likes, Passes, Matches), geht ausschließlich über die RPC-Funktionen.

-- ---------------------------------------------------------------------------
-- Grundrechte zurücksetzen
-- ---------------------------------------------------------------------------

revoke all on all tables in schema public from anon, authenticated;
revoke all on all tables in schema private from anon, authenticated;
revoke execute on all functions in schema public from public, anon, authenticated;
revoke execute on all functions in schema private from public, anon, authenticated;

-- Hilfsfunktionen, die in RLS-Policies aufgerufen werden, brauchen Schema-Zugriff.
grant usage on schema private to authenticated;
grant execute on function
  private.can_view_profile(uuid),
  private.is_match_participant(uuid),
  private.can_send_message(uuid)
to authenticated;

-- App-API
grant execute on function
  public.likes_remaining_today(),
  public.undos_remaining_this_month(),
  public.get_candidates(int),
  public.get_incoming_likes(),
  public.like_profile(uuid, public.like_target, uuid, text),
  public.pass_profile(uuid),
  public.undo_last_pass(),
  public.close_match(uuid, text)
to authenticated;

-- ---------------------------------------------------------------------------
-- Tabellen-Rechte (spaltengenau, wo Nutzer:innen selbst schreiben)
-- ---------------------------------------------------------------------------

grant select on public.profiles to authenticated;
grant insert (id, display_name, birthdate, gender, interested_in, intention, bio, city,
              age_min, age_max, max_distance_km)
  on public.profiles to authenticated;
grant update (display_name, gender, interested_in, intention, bio, city,
              age_min, age_max, max_distance_km)
  on public.profiles to authenticated;

grant select, delete on public.profile_locations to authenticated;
grant insert (user_id, location), update (location, updated_at) on public.profile_locations to authenticated;

grant select, delete on public.photos to authenticated;
grant insert (user_id, storage_path, position), update (position) on public.photos to authenticated;

grant select on public.prompts to authenticated;

grant select, delete on public.prompt_answers to authenticated;
grant insert (user_id, prompt_id, answer, position), update (prompt_id, answer, position)
  on public.prompt_answers to authenticated;

grant select on public.likes, public.passes, public.matches to authenticated;

grant select on public.messages to authenticated;
grant insert (match_id, sender_id, body) on public.messages to authenticated;

grant select, delete on public.blocks to authenticated;
grant insert (blocker, blocked) on public.blocks to authenticated;

grant select on public.reports to authenticated;
grant insert (reporter, reported, reason, details) on public.reports to authenticated;

-- impressions und alles in private: kein Client-Zugriff.

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.profile_locations enable row level security;
alter table public.photos enable row level security;
alter table public.prompts enable row level security;
alter table public.prompt_answers enable row level security;
alter table public.likes enable row level security;
alter table public.passes enable row level security;
alter table public.impressions enable row level security;
alter table public.matches enable row level security;
alter table public.messages enable row level security;
alter table public.blocks enable row level security;
alter table public.reports enable row level security;
alter table private.trust enable row level security;
alter table private.trust_events enable row level security;

-- profiles: eigenes Profil + Profile, die einem vorgeschlagen wurden / einen geliked haben / gematcht sind
create policy profiles_select on public.profiles
  for select to authenticated
  using (private.can_view_profile(id));
create policy profiles_insert on public.profiles
  for insert to authenticated
  with check (id = (select auth.uid()));
create policy profiles_update on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- Standort: nur der eigene
create policy profile_locations_own on public.profile_locations
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- Fotos: eigene immer, fremde nur freigegebene von sichtbaren Profilen
create policy photos_select on public.photos
  for select to authenticated
  using (
    user_id = (select auth.uid())
    or (moderation = 'approved' and private.can_view_profile(user_id))
  );
create policy photos_insert on public.photos
  for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy photos_update on public.photos
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy photos_delete on public.photos
  for delete to authenticated
  using (user_id = (select auth.uid()));

create policy prompts_select on public.prompts
  for select to authenticated
  using (active);

create policy prompt_answers_select on public.prompt_answers
  for select to authenticated
  using (private.can_view_profile(user_id));
create policy prompt_answers_insert on public.prompt_answers
  for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy prompt_answers_update on public.prompt_answers
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy prompt_answers_delete on public.prompt_answers
  for delete to authenticated
  using (user_id = (select auth.uid()));

-- Likes: eigene ausgehende und eingehende ("Wer hat mich geliked" ist gratis)
create policy likes_select on public.likes
  for select to authenticated
  using (from_user = (select auth.uid()) or to_user = (select auth.uid()));

create policy passes_select on public.passes
  for select to authenticated
  using (from_user = (select auth.uid()));

create policy matches_select on public.matches
  for select to authenticated
  using ((select auth.uid()) in (user_a, user_b));

create policy messages_select on public.messages
  for select to authenticated
  using (private.is_match_participant(match_id));
create policy messages_insert on public.messages
  for insert to authenticated
  with check (sender_id = (select auth.uid()) and private.can_send_message(match_id));

create policy blocks_own on public.blocks
  for all to authenticated
  using (blocker = (select auth.uid()))
  with check (blocker = (select auth.uid()));

create policy reports_select on public.reports
  for select to authenticated
  using (reporter = (select auth.uid()));
create policy reports_insert on public.reports
  for insert to authenticated
  with check (reporter = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- Realtime: neue Nachrichten und Match-Statusänderungen live an die App
-- ---------------------------------------------------------------------------

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.messages, public.matches;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Geplante Jobs (pg_cron ist auf Supabase verfügbar)
-- ---------------------------------------------------------------------------

do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
    perform cron.schedule('lotus-close-stale-matches', '17 * * * *', 'select private.close_stale_matches()');
  end if;
end;
$$;
