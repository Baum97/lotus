-- Lotus – Spiellogik: Limits, Vorschläge, Likes, Matches, Warteschlange, Chat-Regeln.
--
-- Grundsätze (siehe docs/KONZEPT.md):
--  * Alle Limits werden hier durchgesetzt, nie nur im Client.
--  * Zähler werden aus den Daten abgeleitet (count), nicht separat gespeichert – nichts kann auseinanderlaufen.
--  * Das eigene Like-Verhalten fließt NICHT in die Vorschläge für andere ein.
--
-- Fehler werden als stabile Schlüssel geworfen (z. B. 'daily_like_limit_reached'), die die App übersetzt.

-- ---------------------------------------------------------------------------
-- Konfiguration
-- ---------------------------------------------------------------------------

create function private.daily_like_limit() returns int language sql immutable as 'select 20';
create function private.monthly_undo_limit() returns int language sql immutable as 'select 3';
create function private.max_active_chats() returns int language sql immutable as 'select 6';
create function private.stale_chat_days() returns int language sql immutable as 'select 7';
-- Höchstkontingent: so oft wird ein Profil pro Tag maximal (neuen Personen) gezeigt
create function private.max_daily_impressions() returns int language sql immutable as 'select 50';
-- Wer so lange nicht aktiv war, wird nicht mehr vorgeschlagen
create function private.inactive_after_days() returns int language sql immutable as 'select 14';
-- Großzügige Obergrenze gegen Bots; wirkt nur in Trust & Safety, nie im Ranking
create function private.daily_pass_limit() returns int language sql immutable as 'select 300';

-- ---------------------------------------------------------------------------
-- Hilfsfunktionen
-- ---------------------------------------------------------------------------

-- Tage und Monate laufen nach deutscher Zeit (Reset um Mitternacht).
create function private.berlin_today() returns date
language sql stable set search_path = '' as $$
  select (now() at time zone 'Europe/Berlin')::date
$$;

create function private.berlin_day_start() returns timestamptz
language sql stable set search_path = '' as $$
  select private.berlin_today()::timestamp at time zone 'Europe/Berlin'
$$;

create function private.berlin_month_start() returns timestamptz
language sql stable set search_path = '' as $$
  select date_trunc('month', private.berlin_today())::timestamp at time zone 'Europe/Berlin'
$$;

create function private.age_of(p_birthdate date) returns int
language sql stable set search_path = '' as $$
  select extract(year from age(private.berlin_today(), p_birthdate))::int
$$;

create function private.fail(p_key text) returns void
language plpgsql set search_path = '' as $$
begin
  raise exception using errcode = 'P0001', message = p_key;
end;
$$;

-- Aktuelle Person; wirft, wenn nicht eingeloggt, ohne Profil oder gesperrt.
create function private.current_user_id() returns uuid
language plpgsql stable security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_status public.trust_status;
begin
  if v_uid is null then
    perform private.fail('not_authenticated');
  end if;
  select t.status into v_status from private.trust t where t.user_id = v_uid;
  if v_status is null then
    perform private.fail('profile_missing');
  end if;
  if v_status = 'suspended' then
    perform private.fail('account_suspended');
  end if;
  return v_uid;
end;
$$;

create function private.is_blocked(p_a uuid, p_b uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.blocks b
    where (b.blocker = p_a and b.blocked = p_b) or (b.blocker = p_b and b.blocked = p_a)
  )
$$;

create function private.is_available(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from private.trust t where t.user_id = p_user and t.status = 'active')
$$;

create function private.active_chat_count(p_user uuid) returns int
language sql stable security definer set search_path = '' as $$
  select count(*)::int from public.matches m
  where m.state = 'active' and (m.user_a = p_user or m.user_b = p_user)
$$;

-- Darf die aktuelle Person das Profil p_other sehen? Nur wenn es ihr vorgeschlagen wurde,
-- die andere Person sie geliked hat oder ein Match besteht – nie per beliebiger ID.
create function private.can_view_profile(p_other uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select p_other = auth.uid()
    or (
      not private.is_blocked(auth.uid(), p_other)
      and exists (select 1 from private.trust t where t.user_id = p_other and t.status <> 'suspended')
      and (
        exists (select 1 from public.impressions i where i.viewer = auth.uid() and i.shown = p_other)
        or exists (select 1 from public.likes l where l.from_user = p_other and l.to_user = auth.uid())
        or exists (
          select 1 from public.matches m
          where (m.user_a = auth.uid() and m.user_b = p_other) or (m.user_b = auth.uid() and m.user_a = p_other)
        )
      )
    )
$$;

create function private.is_match_participant(p_match uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.matches m
    where m.id = p_match and auth.uid() in (m.user_a, m.user_b)
  )
$$;

-- Schreiben nur in aktiven Matches und erst nach Selfie-Verifizierung (Konzept 5.1).
create function private.can_send_message(p_match uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.matches m
    join public.profiles p on p.id = auth.uid()
    join private.trust t on t.user_id = auth.uid()
    where m.id = p_match
      and m.state = 'active'
      and auth.uid() in (m.user_a, m.user_b)
      and p.verified_at is not null
      and t.status <> 'suspended'
  )
$$;

-- ---------------------------------------------------------------------------
-- Budgets
-- ---------------------------------------------------------------------------

create function public.likes_remaining_today() returns int
language sql stable security definer set search_path = '' as $$
  select greatest(0, private.daily_like_limit() - count(*)::int)
  from public.likes l
  where l.from_user = auth.uid()
    and not l.is_like_back
    and l.created_at >= private.berlin_day_start()
$$;

create function public.undos_remaining_this_month() returns int
language sql stable security definer set search_path = '' as $$
  select greatest(0, private.monthly_undo_limit() - count(*)::int)
  from public.passes p
  where p.from_user = auth.uid()
    and p.undone_at >= private.berlin_month_start()
$$;

-- ---------------------------------------------------------------------------
-- Vorschläge
-- ---------------------------------------------------------------------------

-- Liefert die nächsten Vorschläge – so lange, bis das Like-Budget des Tages verbraucht ist.
-- Reihenfolge (v1, bewusst einfach):
--   1. heute schon gezeigte, aber noch nicht entschiedene Profile
--   2. gleiche Absicht vor abweichender Absicht
--   3. Fairness: wer in den letzten 7 Tagen seltener gezeigt wurde, kommt zuerst
--   4. Zufall
-- Das Like-Verhalten der Kandidat:innen spielt keine Rolle.
-- Orientierung und Dating-Ziel wirken immer im Matching; das Ziel wird nur ausgeliefert,
-- wenn die Person es öffentlich gemacht hat (sonst null).
create function public.get_candidates(p_limit int default 10)
returns table (
  id uuid,
  display_name text,
  age int,
  city text,
  intention public.intention,
  bio text,
  distance_km int,
  verified boolean
)
language plpgsql security definer set search_path = '' as $$
#variable_conflict use_column
declare
  v_me uuid := private.current_user_id();
  v_today date := private.berlin_today();
begin
  update public.profiles set last_active_at = now() where public.profiles.id = v_me;

  if public.likes_remaining_today() = 0 then
    return;
  end if;

  return query
  with me as (
    select p.id, p.gender, p.birthdate, mp.interested_in, mp.intention,
           mp.age_min, mp.age_max, mp.max_distance_km, l.location
    from public.profiles p
    join public.match_preferences mp on mp.user_id = p.id
    join public.profile_locations l on l.user_id = p.id
    where p.id = v_me
  ),
  candidates as (
    select
      o.id,
      o.display_name,
      private.age_of(o.birthdate) as age,
      o.city,
      case when op.intention_public then op.intention end as intention,
      o.bio,
      greatest(1, ceil(extensions.st_distance(ol.location, me.location) / 1000))::int as distance_km,
      o.verified_at is not null as verified,
      exists (
        select 1 from public.impressions i
        where i.viewer = v_me and i.shown = o.id and i.shown_on = v_today
      ) as shown_to_me_today,
      (op.intention = me.intention) as same_intention,
      (
        select count(*) from public.impressions i
        where i.shown = o.id and i.shown_on > v_today - 7
      ) as recent_impressions,
      (
        select count(*) from public.impressions i
        where i.shown = o.id and i.shown_on = v_today
      ) as impressions_today
    from me
    join public.profiles o on o.id <> me.id
    join public.match_preferences op on op.user_id = o.id
    join public.profile_locations ol on ol.user_id = o.id
    join private.trust t on t.user_id = o.id and t.status = 'active'
    where
      -- gegenseitige harte Filter
      o.gender = any (me.interested_in)
      and me.gender = any (op.interested_in)
      and private.age_of(o.birthdate) between me.age_min and me.age_max
      and private.age_of(me.birthdate) between op.age_min and op.age_max
      and extensions.st_dwithin(ol.location, me.location, least(me.max_distance_km, op.max_distance_km) * 1000)
      and o.last_active_at > now() - make_interval(days => private.inactive_after_days())
      and exists (select 1 from public.photos ph where ph.user_id = o.id and ph.moderation <> 'rejected')
      -- noch nicht entschieden, keine Blockierung, kein Match
      and not exists (select 1 from public.likes l where l.from_user = v_me and l.to_user = o.id)
      -- wer mich schon geliked hat, steht in "Wer hat mich geliked" (Zurück-Liken ist gratis)
      and not exists (select 1 from public.likes l where l.from_user = o.id and l.to_user = v_me)
      and not exists (
        select 1 from public.passes p
        where p.from_user = v_me and p.to_user = o.id and p.undone_at is null
      )
      and not exists (
        select 1 from public.matches m
        where (m.user_a = v_me and m.user_b = o.id) or (m.user_a = o.id and m.user_b = v_me)
      )
      and not private.is_blocked(v_me, o.id)
  ),
  picked as (
    select c.*
    from candidates c
    where c.shown_to_me_today or c.impressions_today < private.max_daily_impressions()
    order by c.shown_to_me_today desc, c.same_intention desc, c.recent_impressions, random()
    limit greatest(1, least(p_limit, 50))
  ),
  recorded as (
    insert into public.impressions (viewer, shown, shown_on)
    select v_me, picked.id, v_today from picked
    on conflict do nothing
  )
  select picked.id, picked.display_name, picked.age, picked.city, picked.intention,
         picked.bio, picked.distance_km, picked.verified
  from picked
  order by picked.shown_to_me_today desc, picked.same_intention desc, picked.recent_impressions;
end;
$$;

-- Profilkarte einer Person, die man sehen darf (Vorschlag, eingehendes Like oder Match).
-- Liefert nur öffentliche Angaben: keine Orientierung, kein Geburtsdatum, kein Standort,
-- das Dating-Ziel nur, wenn die Person es öffentlich gemacht hat.
create function public.get_profile(p_user uuid)
returns table (
  id uuid,
  display_name text,
  age int,
  gender public.gender,
  city text,
  intention public.intention,
  bio text,
  verified boolean
)
language sql stable security definer set search_path = '' as $$
  select p.id, p.display_name, private.age_of(p.birthdate), p.gender, p.city,
         case when mp.intention_public or p.id = auth.uid() then mp.intention end,
         p.bio, p.verified_at is not null
  from public.profiles p
  left join public.match_preferences mp on mp.user_id = p.id
  where p.id = p_user and private.can_view_profile(p_user)
$$;

-- "Wer hat mich geliked" – für alle gratis.
create function public.get_incoming_likes()
returns table (
  from_user uuid,
  display_name text,
  age int,
  target_type public.like_target,
  target_id uuid,
  comment text,
  created_at timestamptz
)
language sql stable security definer set search_path = '' as $$
  select l.from_user, p.display_name, private.age_of(p.birthdate), l.target_type, l.target_id, l.comment, l.created_at
  from public.likes l
  join public.profiles p on p.id = l.from_user
  where l.to_user = auth.uid()
    and private.is_available(l.from_user)
    and not private.is_blocked(auth.uid(), l.from_user)
    and not exists (select 1 from public.likes b where b.from_user = auth.uid() and b.to_user = l.from_user)
    and not exists (
      select 1 from public.passes x
      where x.from_user = auth.uid() and x.to_user = l.from_user and x.undone_at is null
    )
  order by (l.comment is not null) desc, l.created_at desc
$$;

-- ---------------------------------------------------------------------------
-- Matches & Warteschlange
-- ---------------------------------------------------------------------------

-- Serialisiert Änderungen an den Chat-Plätzen einer Person (verhindert Race Conditions).
create function private.lock_users(p_a uuid, p_b uuid) returns void
language sql set search_path = '' as $$
  select pg_advisory_xact_lock(hashtextextended('lotus:user:' || least(p_a, p_b)::text, 0)),
         pg_advisory_xact_lock(hashtextextended('lotus:user:' || greatest(p_a, p_b)::text, 0))
$$;

-- Aktiviert wartende Matches einer Person (älteste zuerst), sobald beide Seiten Platz haben.
create function private.promote_queue(p_user uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_match record;
begin
  for v_match in
    select m.id, m.user_a, m.user_b
    from public.matches m
    where m.state = 'queued' and (m.user_a = p_user or m.user_b = p_user)
    order by m.created_at
  loop
    exit when private.active_chat_count(p_user) >= private.max_active_chats();
    perform private.lock_users(v_match.user_a, v_match.user_b);
    if private.active_chat_count(v_match.user_a) < private.max_active_chats()
       and private.active_chat_count(v_match.user_b) < private.max_active_chats() then
      update public.matches
      set state = 'active', activated_at = now()
      where id = v_match.id and state = 'queued';
    end if;
  end loop;
end;
$$;

create function private.create_match(p_a uuid, p_b uuid) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_id uuid;
begin
  perform private.lock_users(p_a, p_b);
  insert into public.matches (user_a, user_b)
  values (least(p_a, p_b), greatest(p_a, p_b))
  returning id into v_id;
  perform private.promote_queue(p_a);
  return v_id;
end;
$$;

-- Nach dem Schließen eines Chats rücken wartende Matches beider Personen nach.
create function private.on_match_closed() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  perform private.promote_queue(new.user_a);
  perform private.promote_queue(new.user_b);
  return null;
end;
$$;

create trigger matches_promote_queue_after_close
after update of state on public.matches
for each row
when (old.state is distinct from new.state and new.state = 'closed')
execute function private.on_match_closed();

-- ---------------------------------------------------------------------------
-- Entscheidungen
-- ---------------------------------------------------------------------------

-- Like auf ein Foto oder eine Prompt-Antwort. Gibt die Match-ID zurück, falls es ein Match ist.
create function public.like_profile(
  p_to uuid,
  p_target_type public.like_target default null,
  p_target_id uuid default null,
  p_comment text default null
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_me uuid := private.current_user_id();
  v_like_back boolean;
begin
  if p_to = v_me then
    perform private.fail('cannot_like_self');
  end if;
  if not private.is_available(p_to) or private.is_blocked(v_me, p_to) then
    perform private.fail('profile_not_available');
  end if;

  -- Budget pro Person serialisieren, damit parallele Requests das Limit nicht überschreiten
  perform pg_advisory_xact_lock(hashtextextended('lotus:likes:' || v_me::text, 0));

  if exists (select 1 from public.likes l where l.from_user = v_me and l.to_user = p_to) then
    perform private.fail('already_liked');
  end if;
  if exists (
    select 1 from public.passes p where p.from_user = v_me and p.to_user = p_to and p.undone_at is null
  ) then
    perform private.fail('already_passed');
  end if;

  v_like_back := exists (select 1 from public.likes l where l.from_user = p_to and l.to_user = v_me);

  if not v_like_back then
    -- Nur vorgeschlagene Profile können geliked werden (kein Massen-Liken per API)
    if not exists (select 1 from public.impressions i where i.viewer = v_me and i.shown = p_to) then
      perform private.fail('profile_not_available');
    end if;
    if public.likes_remaining_today() <= 0 then
      perform private.fail('daily_like_limit_reached');
    end if;
    if p_target_type is null then
      perform private.fail('like_target_required');
    end if;
  end if;

  if (p_target_type is null) <> (p_target_id is null) then
    perform private.fail('invalid_like_target');
  end if;
  if p_target_type = 'photo' and not exists (
    select 1 from public.photos ph where ph.id = p_target_id and ph.user_id = p_to and ph.moderation <> 'rejected'
  ) then
    perform private.fail('invalid_like_target');
  end if;
  if p_target_type = 'prompt' and not exists (
    select 1 from public.prompt_answers pa where pa.id = p_target_id and pa.user_id = p_to
  ) then
    perform private.fail('invalid_like_target');
  end if;

  insert into public.likes (from_user, to_user, target_type, target_id, comment, is_like_back)
  values (v_me, p_to, p_target_type, p_target_id, nullif(btrim(p_comment), ''), v_like_back);

  if v_like_back then
    return private.create_match(v_me, p_to);
  end if;
  return null;
end;
$$;

create function public.pass_profile(p_to uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_me uuid := private.current_user_id();
  v_today_count int;
begin
  if not exists (select 1 from public.impressions i where i.viewer = v_me and i.shown = p_to)
     and not exists (select 1 from public.likes l where l.from_user = p_to and l.to_user = v_me) then
    perform private.fail('profile_not_available');
  end if;
  if exists (select 1 from public.likes l where l.from_user = v_me and l.to_user = p_to) then
    perform private.fail('already_liked');
  end if;

  select count(*) into v_today_count
  from public.passes p
  where p.from_user = v_me and p.created_at >= private.berlin_day_start();

  if v_today_count >= private.daily_pass_limit() then
    -- Nur Trust & Safety erfährt davon; das Ranking bleibt unberührt.
    insert into private.trust_events (user_id, signal, details)
    values (v_me, 'pass_limit_reached', jsonb_build_object('count', v_today_count));
    perform private.fail('slow_down');
  end if;

  insert into public.passes (from_user, to_user)
  values (v_me, p_to)
  on conflict do nothing;
end;
$$;

-- Macht das letzte Wegwischen rückgängig (3× pro Monat). Nur die jeweils letzte Entscheidung,
-- und nur wenn sie ein Pass war. Gibt die wiederhergestellte Profil-ID zurück.
create function public.undo_last_pass() returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_me uuid := private.current_user_id();
  v_pass record;
begin
  perform pg_advisory_xact_lock(hashtextextended('lotus:likes:' || v_me::text, 0));

  if public.undos_remaining_this_month() <= 0 then
    perform private.fail('monthly_undo_limit_reached');
  end if;

  select p.id, p.to_user, p.created_at into v_pass
  from public.passes p
  where p.from_user = v_me and p.undone_at is null
  order by p.created_at desc
  limit 1;

  if v_pass.id is null or exists (
    select 1 from public.likes l where l.from_user = v_me and l.created_at > v_pass.created_at
  ) or exists (
    select 1 from public.passes p where p.from_user = v_me and p.undone_at > v_pass.created_at
  ) then
    perform private.fail('nothing_to_undo');
  end if;

  update public.passes set undone_at = now() where id = v_pass.id;
  return v_pass.to_user;
end;
$$;

-- Beendet ein Gespräch (oder einen wartenden Match), optional mit freundlicher Abschiedsnachricht.
create function public.close_match(p_match uuid, p_goodbye text default null) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_me uuid := private.current_user_id();
  v_match public.matches;
begin
  select * into v_match from public.matches m where m.id = p_match for update;
  if v_match.id is null or v_me not in (v_match.user_a, v_match.user_b) then
    perform private.fail('match_not_found');
  end if;
  if v_match.state = 'closed' then
    return;
  end if;

  if nullif(btrim(p_goodbye), '') is not null and private.can_send_message(p_match) then
    insert into public.messages (match_id, sender_id, body) values (p_match, v_me, btrim(p_goodbye));
  end if;

  update public.matches
  set state = 'closed', closed_at = now(), close_reason = 'ended', closed_by = v_me
  where id = p_match;
end;
$$;

-- Für pg_cron: schließt Gespräche, in denen seit 7 Tagen niemand geschrieben hat.
create function private.close_stale_matches() returns int
language plpgsql security definer set search_path = '' as $$
declare
  v_count int;
begin
  update public.matches
  set state = 'closed', closed_at = now(), close_reason = 'stale'
  where state = 'active'
    and coalesce(last_message_at, activated_at) < now() - make_interval(days => private.stale_chat_days());
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- ---------------------------------------------------------------------------
-- Trigger
-- ---------------------------------------------------------------------------

create function private.on_profile_created() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into private.trust (user_id) values (new.id) on conflict do nothing;
  return null;
end;
$$;

create trigger profiles_create_trust
after insert on public.profiles
for each row execute function private.on_profile_created();

-- Blockieren beendet ein bestehendes Match sofort.
create function private.on_block_created() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  update public.matches
  set state = 'closed', closed_at = now(), close_reason = 'blocked', closed_by = new.blocker
  where state <> 'closed'
    and user_a = least(new.blocker, new.blocked)
    and user_b = greatest(new.blocker, new.blocked);
  return null;
end;
$$;

create trigger blocks_close_match
after insert on public.blocks
for each row execute function private.on_block_created();

-- Nachrichten: Sicherheits-Hinweise setzen, Links für eingeschränkte Accounts sperren.
create function private.before_message_insert() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_has_link boolean := new.body ~* '(https?://|www\.|\m[a-z0-9-]+\.(com|net|org|io|me|ly)\M)';
begin
  new.created_at := now();
  if v_has_link and exists (
    select 1 from private.trust t where t.user_id = new.sender_id and t.status = 'restricted'
  ) then
    perform private.fail('links_not_allowed');
  end if;
  new.safety_flag := case
    when new.body ~* '(krypto|crypto|bitcoin|btc|usdt|investment|investier|überweis|paypal|western union|gutschein|geld leihen)' then 'money'
    when v_has_link then 'link'
    when new.body ~* '(whatsapp|telegram|signal|snapchat|\+?\d[\d /-]{8,}\d)' then 'off_platform'
    else null
  end;
  return new;
end;
$$;

create trigger messages_before_insert
before insert on public.messages
for each row execute function private.before_message_insert();

create function private.after_message_insert() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  update public.matches set last_message_at = new.created_at where id = new.match_id;
  return null;
end;
$$;

create trigger messages_after_insert
after insert on public.messages
for each row execute function private.after_message_insert();
