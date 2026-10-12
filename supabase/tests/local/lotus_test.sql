-- Datenbank-Tests für Lotus. Ausführen über scripts/test-db.sh.
-- Jede Prüfung wirft bei Fehlschlag eine Exception; ON_ERROR_STOP bricht dann ab.

\set ON_ERROR_STOP 1
\o /dev/null

-- ---------------------------------------------------------------------------
-- Test-Helfer
-- ---------------------------------------------------------------------------

create schema test;
grant usage on schema test to authenticated;

create function test.ok(p_condition boolean, p_name text) returns void
language plpgsql as $$
begin
  if p_condition is not true then
    raise exception 'FAILED: %', p_name;
  end if;
  raise notice 'ok - %', p_name;
end;
$$;

-- Erwartet, dass p_sql mit einer Fehlermeldung scheitert, die p_expected enthält.
create function test.throws(p_sql text, p_expected text, p_name text) returns void
language plpgsql as $$
begin
  begin
    execute p_sql;
  exception when others then
    if strpos(sqlerrm, p_expected) > 0 then
      raise notice 'ok - %', p_name;
      return;
    end if;
    raise exception 'FAILED: % (expected "%", got "%")', p_name, p_expected, sqlerrm;
  end;
  raise exception 'FAILED: % (expected error "%", got none)', p_name, p_expected;
end;
$$;

grant execute on all functions in schema test to authenticated;

-- Als Person einloggen (wie ein JWT in Supabase)
create function test.login(p_user uuid) returns void
language sql as $$
  select set_config('request.jwt.claim.sub', p_user::text, false)
$$;
grant execute on function test.login(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Testdaten
--   A  Frau, 30, Stuttgart, sucht Männer 25–40
--   B  Mann, 32, Stuttgart, sucht Frauen         → passt
--   C  Mann, 28, Esslingen, sucht Frauen         → passt
--   D  Mann, 31, Stuttgart, sucht nur Männer     → passt nicht (Gegenseitigkeit)
--   E  Mann, 33, München, sucht Frauen           → zu weit weg
--   F  Mann, 50, Stuttgart, sucht Frauen         → außerhalb As Altersbereich
--   Füller 01–30: Männer, Stuttgart, suchen Frauen
-- ---------------------------------------------------------------------------

create function test.uid(p_label text) returns uuid
language sql immutable as $$
  select case p_label
    when 'A' then '00000000-0000-0000-0000-00000000000a'
    when 'B' then '00000000-0000-0000-0000-00000000000b'
    when 'C' then '00000000-0000-0000-0000-00000000000c'
    when 'D' then '00000000-0000-0000-0000-00000000000d'
    when 'E' then '00000000-0000-0000-0000-00000000000e'
    when 'F' then '00000000-0000-0000-0000-00000000000f'
    else ('10000000-0000-0000-0000-0000000000' || lpad(p_label, 2, '0'))
  end::uuid
$$;
grant execute on function test.uid(text) to authenticated;

create function test.seed_user(
  p_label text, p_gender public.gender, p_interested public.gender[], p_age int,
  p_lon float8, p_lat float8, p_age_min int default 18, p_age_max int default 99
) returns void
language plpgsql as $$
declare
  v_id uuid := test.uid(p_label);
begin
  insert into auth.users (id) values (v_id);
  insert into public.profiles (id, display_name, birthdate, gender, interested_in, intention, city, age_min, age_max)
  values (v_id, 'User ' || p_label, (current_date - make_interval(years => p_age, days => 10))::date,
          p_gender, p_interested, 'relationship', 'Stuttgart', p_age_min, p_age_max);
  insert into public.profile_locations (user_id, location)
  values (v_id, extensions.st_setsrid(extensions.st_makepoint(p_lon, p_lat), 4326)::extensions.geography);
  insert into public.photos (user_id, storage_path, position, moderation)
  values (v_id, v_id || '/0.jpg', 0, 'approved');
  insert into public.prompt_answers (user_id, prompt_id, answer, position)
  values (v_id, 1, 'Kaffee am Feuersee', 0);
end;
$$;

select test.seed_user('A', 'woman', '{man}', 30, 9.18, 48.78, 25, 40);
select test.seed_user('B', 'man', '{woman}', 32, 9.17, 48.77);
select test.seed_user('C', 'man', '{woman}', 28, 9.31, 48.74);
select test.seed_user('D', 'man', '{man}', 31, 9.18, 48.78);
select test.seed_user('E', 'man', '{woman}', 33, 11.58, 48.14);
select test.seed_user('F', 'man', '{woman}', 50, 9.18, 48.78);
select test.seed_user(n::text, 'man', '{woman}', 30, 9.18, 48.78) from generate_series(1, 30) n;

-- ---------------------------------------------------------------------------
-- Profil-Sichtbarkeit & Vorschläge
-- ---------------------------------------------------------------------------

set role authenticated;
select test.login(test.uid('A'));

select test.ok((select count(*) from public.profiles where id = test.uid('B')) = 0,
  'fremde Profile sind ohne Vorschlag nicht lesbar');
select test.ok((select count(*) from public.profile_locations) = 1,
  'nur der eigene Standort ist lesbar');
select test.ok(public.likes_remaining_today() = 20, 'Startbudget 20 Likes');

create temp table a_candidates as select * from public.get_candidates(50);

select test.ok(exists (select 1 from a_candidates where id = test.uid('B')), 'B wird vorgeschlagen');
select test.ok(exists (select 1 from a_candidates where id = test.uid('C')), 'C (Esslingen) wird vorgeschlagen');
select test.ok(not exists (select 1 from a_candidates where id = test.uid('D')), 'D (sucht nur Männer) nicht');
select test.ok(not exists (select 1 from a_candidates where id = test.uid('E')), 'E (München) nicht');
select test.ok(not exists (select 1 from a_candidates where id = test.uid('F')), 'F (außerhalb Altersbereich) nicht');
select test.ok((select count(*) from a_candidates) = 32, 'B, C und 30 Füller vorgeschlagen');
select test.ok((select min(distance_km) from a_candidates) >= 1, 'Entfernung nur gerundet, mindestens 1 km');
select test.ok((select count(*) from public.profiles where id = test.uid('B')) = 1,
  'vorgeschlagenes Profil ist danach lesbar');
select test.ok((select count(*) from public.photos where user_id = test.uid('B')) = 1,
  'Fotos vorgeschlagener Profile sind lesbar');

-- ---------------------------------------------------------------------------
-- Likes
-- ---------------------------------------------------------------------------

select test.throws($$select public.like_profile(test.uid('B'))$$, 'like_target_required',
  'Like ohne Foto/Prompt wird abgelehnt');
select test.throws(
  format($$select public.like_profile(%L, 'photo', %L)$$, test.uid('B'),
         (select id from public.photos where user_id = test.uid('A'))),
  'invalid_like_target', 'Like auf fremdes Foto (nicht von B) wird abgelehnt');
select test.throws($$select public.like_profile(test.uid('E'), 'photo', gen_random_uuid())$$,
  'profile_not_available', 'nicht vorgeschlagenes Profil kann nicht geliked werden');
select test.throws($$select public.like_profile(test.uid('A'), 'photo', gen_random_uuid())$$,
  'cannot_like_self', 'sich selbst liken geht nicht');

select test.ok(
  public.like_profile(test.uid('B'), 'photo',
    (select id from public.photos where user_id = test.uid('B')), 'Feuersee ist auch mein Lieblingsort!') is null,
  'Like auf Foto mit Kommentar, noch kein Match');
select test.ok(public.likes_remaining_today() = 19, 'Like kostet 1 Budget');
select test.throws(
  format($$select public.like_profile(%L, 'photo', %L)$$, test.uid('B'),
         (select id from public.photos where user_id = test.uid('B'))),
  'already_liked', 'doppeltes Like wird abgelehnt');
select test.throws($$insert into public.likes (from_user, to_user, is_like_back) values (test.uid('A'), test.uid('C'), true)$$,
  'permission denied', 'direktes Schreiben in likes ist verboten');
select test.throws($$update public.profiles set verified_at = now() where id = test.uid('A')$$,
  'permission denied', 'verified_at ist nicht selbst setzbar');

-- B sieht das Like gratis und likt zurück → Match, kostet B kein Budget
select test.login(test.uid('B'));
select test.ok((select count(*) from public.get_incoming_likes() where from_user = test.uid('A')) = 1,
  'B sieht eingehendes Like von A');
select test.ok((select comment from public.get_incoming_likes()) = 'Feuersee ist auch mein Lieblingsort!',
  'Kommentar wird mitgeliefert');
select test.ok((select count(*) from public.profiles where id = test.uid('A')) = 1,
  'B darf As Profil sehen, weil A geliked hat');
create temp table ab_match as select public.like_profile(test.uid('A')) as id;
select test.ok((select id from ab_match) is not null, 'Zurück-Like erzeugt Match');
select test.ok(public.likes_remaining_today() = 20, 'Zurück-Like kostet kein Budget');
select test.ok((select state from public.matches where id = (select id from ab_match)) = 'active',
  'Match ist aktiv');

-- ---------------------------------------------------------------------------
-- Chat
-- ---------------------------------------------------------------------------

select test.throws(
  format($$insert into public.messages (match_id, sender_id, body) values (%L, %L, 'Hi')$$,
         (select id from ab_match), test.uid('B')),
  'row-level security', 'ohne Verifizierung kein Chat');

reset role;
update public.profiles set verified_at = now() where id in (test.uid('A'), test.uid('B'));
set role authenticated;
select test.login(test.uid('B'));

insert into public.messages (match_id, sender_id, body)
select id, test.uid('B'), 'Hi! Welcher Kaffee am Feuersee?' from ab_match;
select test.ok((select count(*) from public.messages) = 1, 'verifizierte Person kann schreiben');

select test.login(test.uid('A'));
insert into public.messages (match_id, sender_id, body)
select id, test.uid('A'), 'Kannst du mir 200€ per PayPal leihen?' from ab_match;
select test.ok((select safety_flag from public.messages where sender_id = test.uid('A')) = 'money',
  'Geld-Anfrage wird markiert');

select test.login(test.uid('C'));
select test.ok((select count(*) from public.messages) = 0, 'Unbeteiligte sehen keine Nachrichten');

-- ---------------------------------------------------------------------------
-- Wegwischen & Rückgängig
-- ---------------------------------------------------------------------------

select test.login(test.uid('A'));
select public.pass_profile(test.uid('C'));
select test.ok(not exists (select 1 from public.get_candidates(50) where id = test.uid('C')),
  'weggewischtes Profil verschwindet');
select test.ok(public.undo_last_pass() = test.uid('C'), 'Rückgängig liefert C zurück');
select test.ok(public.undos_remaining_this_month() = 2, 'noch 2 Rückgängig übrig');
select test.ok(exists (select 1 from public.get_candidates(50) where id = test.uid('C')),
  'C ist wieder im Stapel');
select test.throws($$select public.undo_last_pass()$$, 'nothing_to_undo',
  'ohne neuen Pass nichts rückgängig zu machen');

select public.pass_profile(test.uid('C'));
select public.like_profile(test.uid('1'), 'photo', (select id from public.photos where user_id = test.uid('1')));
select test.throws($$select public.undo_last_pass()$$, 'nothing_to_undo',
  'nur die letzte Entscheidung ist rückgängig machbar');

select public.pass_profile(test.uid('2'));
select public.undo_last_pass();
select public.pass_profile(test.uid('2'));
select public.undo_last_pass();
select public.pass_profile(test.uid('2'));
select test.ok(public.undos_remaining_this_month() = 0, 'Monatskontingent aufgebraucht');
select test.throws($$select public.undo_last_pass()$$, 'monthly_undo_limit_reached',
  'viertes Rückgängig im Monat wird abgelehnt');

-- ---------------------------------------------------------------------------
-- Like-Budget: Vorschläge, bis die Likes aufgebraucht sind
-- ---------------------------------------------------------------------------

-- A hat B und Füller 1 geliked (18 übrig). Restliche Likes an Füller 3–20 verteilen.
select public.like_profile(test.uid(n::text), 'prompt',
  (select id from public.prompt_answers where user_id = test.uid(n::text)))
from generate_series(3, 20) n;

select test.ok(public.likes_remaining_today() = 0, 'Budget aufgebraucht');
select test.ok((select count(*) from public.get_candidates(50)) = 0,
  'ohne Likes keine weiteren Vorschläge');
select test.throws(
  format($$select public.like_profile(%L, 'photo', %L)$$, test.uid('21'),
         (select id from public.photos where user_id = test.uid('21'))),
  'daily_like_limit_reached', '21. Like wird abgelehnt');

-- Zurück-Liken geht auch ohne Budget
reset role;
insert into public.likes (from_user, to_user, target_type, target_id)
select test.uid('22'), test.uid('A'), 'photo', id from public.photos where user_id = test.uid('A');
set role authenticated;
select test.login(test.uid('A'));
select test.ok(public.like_profile(test.uid('22')) is not null, 'Zurück-Like ohne Budget möglich');

-- ---------------------------------------------------------------------------
-- Chat-Limit & Warteschlange
-- ---------------------------------------------------------------------------

-- A hat aktive Matches mit B und Füller 22. Füller 23–27 liken A → nach Zurück-Like 7 Matches.
reset role;
insert into public.likes (from_user, to_user, target_type, target_id)
select test.uid(n::text), test.uid('A'), 'photo', (select id from public.photos where user_id = test.uid('A'))
from generate_series(23, 27) n;
set role authenticated;
select test.login(test.uid('A'));
select public.like_profile(test.uid(n::text)) from generate_series(23, 27) n;

select test.ok(
  (select count(*) from public.matches where state = 'active') = 6, '6 aktive Chats');
select test.ok(
  (select count(*) from public.matches where state = 'queued') = 1, '7. Match wartet in der Warteschlange');

select public.close_match((select id from ab_match), 'Danke dir, alles Gute!');
select test.ok((select state from public.matches where id = (select id from ab_match)) = 'closed',
  'Gespräch beendet');
select test.ok(
  (select count(*) from public.messages where body = 'Danke dir, alles Gute!') = 1, 'Abschiedsnachricht gesendet');
select test.ok(
  (select count(*) from public.matches where state = 'active') = 6, 'wartendes Match rückt nach');
select test.ok(
  (select count(*) from public.matches where state = 'queued') = 0, 'Warteschlange leer');

-- ---------------------------------------------------------------------------
-- Blockieren & eingeschlafene Chats
-- ---------------------------------------------------------------------------

insert into public.blocks (blocker, blocked) values (test.uid('A'), test.uid('27'));
select test.ok(
  (select close_reason from public.matches where test.uid('27') in (user_a, user_b)) = 'blocked',
  'Blockieren beendet das Match');

reset role;
update public.matches set activated_at = now() - interval '8 days'
where state = 'active' and test.uid('22') in (user_a, user_b);
select test.ok(private.close_stale_matches() = 1, 'Chat ohne Nachricht seit 7 Tagen wird geschlossen');

-- ---------------------------------------------------------------------------
-- Gesperrte Accounts
-- ---------------------------------------------------------------------------

update private.trust set status = 'suspended' where user_id = test.uid('C');
set role authenticated;
select test.login(test.uid('C'));
select test.throws($$select * from public.get_candidates()$$, 'account_suspended',
  'gesperrte Accounts können nichts mehr tun');
select test.login(test.uid('B'));
select test.ok(not exists (select 1 from public.get_candidates(50) where id = test.uid('C')),
  'gesperrte Accounts werden nicht vorgeschlagen');
reset role;
