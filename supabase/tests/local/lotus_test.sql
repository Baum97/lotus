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
--   G  divers, 29, Ulm, sucht alle               → passt nicht zu A (A sucht nur Männer)
--   H  Mann, 34, Stuttgart, sucht Männer & diverse → passt zu D und G
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
    when 'G' then '00000000-0000-0000-0000-000000000010'
    when 'H' then '00000000-0000-0000-0000-000000000011'
    else ('10000000-0000-0000-0000-0000000000' || lpad(p_label, 2, '0'))
  end::uuid
$$;
grant execute on function test.uid(text) to authenticated;

create function test.seed_user(
  p_label text, p_gender public.gender, p_interested public.gender[], p_age int,
  p_lon float8, p_lat float8, p_age_min int default 18, p_age_max int default 99,
  p_intention public.intention default 'relationship', p_intention_public boolean default true,
  p_max_distance_km int default 50
) returns void
language plpgsql as $$
declare
  v_id uuid := test.uid(p_label);
begin
  insert into auth.users (id) values (v_id);
  insert into public.profiles (id, display_name, birthdate, gender, city)
  values (v_id, 'User ' || p_label, (current_date - make_interval(years => p_age, days => 10))::date,
          p_gender, 'Stuttgart');
  insert into public.match_preferences (user_id, interested_in, intention, intention_public, age_min, age_max, max_distance_km)
  values (v_id, p_interested, p_intention, p_intention_public, p_age_min, p_age_max, p_max_distance_km);
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
select test.seed_user('C', 'man', '{woman}', 28, 9.31, 48.74, p_intention => 'unsure', p_intention_public => false);
select test.seed_user('D', 'man', '{man}', 31, 9.18, 48.78);
select test.seed_user('E', 'man', '{woman}', 33, 11.58, 48.14);
select test.seed_user('F', 'man', '{woman}', 50, 9.18, 48.78);
select test.seed_user('G', 'diverse', '{woman,man,diverse}', 29, 9.99, 48.40, p_max_distance_km => 150);
select test.seed_user('H', 'man', '{man,diverse}', 34, 9.18, 48.78, p_max_distance_km => 100);
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
select test.ok(not exists (select 1 from a_candidates where id = test.uid('G')), 'G (divers) nicht, weil A nur Männer sucht');
select test.ok((select intention from a_candidates where id = test.uid('B')) = 'relationship',
  'öffentliches Dating-Ziel wird angezeigt');
select test.ok((select intention from a_candidates where id = test.uid('C')) is null,
  'privates Dating-Ziel wird nicht angezeigt');
select test.ok((select count(*) from a_candidates) = 32, 'B, C und 30 Füller vorgeschlagen');
select test.ok((select min(distance_km) from a_candidates) >= 1, 'Entfernung nur gerundet, mindestens 1 km');
select test.ok((select count(*) from public.profiles where id = test.uid('B')) = 1,
  'vorgeschlagenes Profil ist danach lesbar');
select test.ok((select count(*) from public.photos where user_id = test.uid('B')) = 1,
  'Fotos vorgeschlagener Profile sind lesbar');
select test.ok((select count(*) from public.match_preferences) = 1,
  'Orientierung & Präferenzen anderer sind nie lesbar, nur die eigenen');
select test.throws($$select birthdate from public.profiles where id = test.uid('B')$$, 'permission denied',
  'Geburtsdatum anderer ist nicht lesbar');
select test.ok((select age from public.get_profile(test.uid('B'))) = 32, 'Profilkarte zeigt das Alter');
select test.ok((select intention from public.get_profile(test.uid('C'))) is null,
  'Profilkarte verbirgt privates Dating-Ziel');
select test.ok(not exists (select 1 from public.get_profile(test.uid('E'))),
  'Profilkarte nicht vorgeschlagener Personen ist nicht abrufbar');

-- Gleichgeschlechtliche Suche und divers
select test.login(test.uid('D'));
select test.ok(exists (select 1 from public.get_candidates(50) where id = test.uid('H')),
  'Mann sucht Mann: D bekommt H vorgeschlagen');
select test.ok(not exists (select 1 from public.get_candidates(50) where id = test.uid('B')),
  'D bekommt keine Männer, die Frauen suchen');
select test.login(test.uid('G'));
select test.ok(exists (select 1 from public.get_candidates(50) where id = test.uid('H')),
  'divers: G (Ulm) bekommt H (Stuttgart, sucht auch diverse) vorgeschlagen');
select test.ok(not exists (select 1 from public.get_candidates(50) where id = test.uid('C')),
  'divers: G bekommt C (sucht nur Frauen) nicht');
select test.login(test.uid('A'));

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

-- ---------------------------------------------------------------------------
-- Onboarding: Profil speichern, Standort, Status
-- ---------------------------------------------------------------------------

insert into auth.users (id) values ('00000000-0000-0000-0000-0000000000aa');
create function test.n() returns uuid language sql immutable as $$ select '00000000-0000-0000-0000-0000000000aa'::uuid $$;
grant execute on function test.n() to authenticated;

set role authenticated;
select test.login(test.n());
select test.ok((select not has_profile from public.get_my_status()), 'neue Person hat noch kein Profil');
select test.throws($$select public.save_profile('Nina', current_date - 365 * 17, 'woman', null, 'Ulm',
  '{man}', 'relationship', true, 25, 40, 50)$$, 'too_young', 'unter 18 wird abgelehnt');
select public.save_profile('Nina', '1995-04-02', 'woman', 'Ich wandere gern.', 'Ulm',
  '{man,diverse}', 'unsure', false, 25, 40, 80);
select public.set_location(48.40, 9.99);
select test.ok((select has_profile and has_preferences and has_location and likes_remaining = 20
                from public.get_my_status()), 'Profil, Präferenzen und Standort gespeichert');
select public.save_profile('Nina M.', '2000-01-01', 'woman', null, 'Ulm',
  '{man}', 'relationship', true, 25, 40, 80);
select test.ok((select display_name from public.get_my_status()) = 'Nina M.', 'Profil lässt sich ändern');
select test.ok((select age from public.get_profile(test.n())) > 28, 'Geburtsdatum ändert sich beim Bearbeiten nicht');

-- ---------------------------------------------------------------------------
-- Datei-Speicher
-- ---------------------------------------------------------------------------

insert into storage.objects (bucket_id, name) values ('photos', test.n() || '/1.jpg');
select test.throws(format($$insert into storage.objects (bucket_id, name) values ('photos', '%s/x.jpg')$$, test.uid('A')),
  'row-level security', 'Fotos nur in den eigenen Ordner hochladen');
select test.login(test.uid('D'));
select test.ok((select count(*) from storage.objects where name like test.n() || '/%') = 0,
  'Fotos fremder, nicht vorgeschlagener Profile sind nicht abrufbar');

-- ---------------------------------------------------------------------------
-- Selfie-Verifizierung & Admin
-- ---------------------------------------------------------------------------

reset role;
insert into private.admins (user_id) values (test.uid('B'));
set role authenticated;

select test.login(test.n());
create temp table n_verification as select * from public.start_verification();
grant select on n_verification to authenticated;
select test.ok((select status from n_verification) = 'awaiting_selfie', 'Verifizierung gestartet');
reset role;
select test.ok((select gesture from n_verification) = any (private.verification_gestures()), 'zufällige Geste vorgegeben');
set role authenticated;
select test.ok((select request_id from public.start_verification()) = (select request_id from n_verification),
  'erneuter Start liefert dieselbe Anfrage');
select test.throws(format($$select public.submit_verification(%L, '%s/selfie.jpg')$$,
  (select request_id from n_verification), test.uid('A')), 'invalid_selfie_path', 'Selfie muss im eigenen Ordner liegen');
insert into storage.objects (bucket_id, name) values ('selfies', test.n() || '/selfie.jpg');
select public.submit_verification((select request_id from n_verification), test.n() || '/selfie.jpg');
select test.ok((select verification_status from public.get_my_status()) = 'pending', 'Selfie eingereicht');

select test.login(test.uid('D'));
select test.throws($$select * from public.admin_pending_verifications()$$, 'not_admin', 'Admin-Funktionen nur für Admins');
select test.ok((select count(*) from storage.objects where bucket_id = 'selfies') = 0, 'Selfies anderer sind privat');

select test.login(test.uid('B'));
select test.ok((select is_admin from public.get_my_status()), 'B ist Admin');
select test.ok((select count(*) from public.admin_pending_verifications()) = 1, 'Admin sieht offene Verifizierung');
select test.ok((select count(*) from storage.objects where bucket_id = 'selfies') = 1, 'Admin kann Selfie ansehen');
select test.ok((select count(*) from storage.objects where bucket_id = 'photos') = 1, 'Admin kann alle Fotos ansehen');
select public.admin_review_verification((select request_id from n_verification), true);

select test.login(test.n());
select test.ok((select verified and verification_status = 'approved' from public.get_my_status()), 'Person ist verifiziert');
select test.throws($$select * from public.start_verification()$$, 'already_verified', 'keine zweite Verifizierung');

-- Foto-Moderation: abgelehnte Fotos verschwinden, Profile ohne Foto werden nicht vorgeschlagen
reset role;
update public.photos set moderation = 'pending' where user_id = test.uid('H');
set role authenticated;
select test.login(test.uid('B'));
select test.ok(exists (select 1 from public.admin_recent_photos() where user_id = test.uid('H')),
  'Admin sieht ungeprüfte Fotos');
select test.login(test.uid('D'));
select test.ok(exists (select 1 from public.get_candidates(50) where id = test.uid('H')),
  'ungeprüfte Fotos sind sofort sichtbar');
select test.login(test.uid('B'));
select public.admin_set_photo_moderation((select photo_id from public.admin_recent_photos(200) where user_id = test.uid('H')), 'rejected');
select test.login(test.uid('D'));
select test.ok(not exists (select 1 from public.get_candidates(50) where id = test.uid('H')),
  'Profil ohne sichtbares Foto wird nicht mehr vorgeschlagen');
select test.ok((select count(*) from public.photos where user_id = test.uid('H')) = 0, 'abgelehntes Foto ist nicht lesbar');

-- Meldungen
insert into public.reports (reporter, reported, reason, details) values (test.uid('D'), test.uid('H'), 'scam', 'Fragt nach Krypto');
select test.login(test.uid('B'));
select test.ok((select count(*) from public.admin_open_reports()) = 1, 'Admin sieht Meldung');
select public.admin_resolve_report((select report_id from public.admin_open_reports()), 'suspended', 'Scam');
select test.ok((select count(*) from public.admin_open_reports()) = 0, 'Meldung erledigt');
reset role;
select test.ok((select status from private.trust where user_id = test.uid('H')) = 'suspended', 'gemeldete Person gesperrt');
set role authenticated;

-- ---------------------------------------------------------------------------
-- Chat-Übersicht & Spam-Erkennung
-- ---------------------------------------------------------------------------

reset role;
insert into public.likes (from_user, to_user, target_type, target_id)
select test.uid('28'), test.uid('A'), 'photo', id from public.photos where user_id = test.uid('A');
set role authenticated;
select test.login(test.uid('A'));
select public.like_profile(test.uid('28'));

select test.ok((select count(*) from public.get_matches() where state = 'active') = 5, 'Übersicht zeigt 5 aktive Chats');
select test.ok(exists (select 1 from public.get_matches() where state = 'closed' and close_reason = 'ended'),
  'kürzlich beendete Chats werden angezeigt');
select test.ok((select last_message from public.get_matches() where other_user = test.uid('B')) = 'Danke dir, alles Gute!',
  'letzte Nachricht wird angezeigt');

insert into public.messages (match_id, sender_id, body)
select match_id, test.uid('A'), 'Hey, schau dir mal meine tolle Seite an, da gibt es mehr von mir'
from public.get_matches() where state = 'active';
reset role;
select test.ok((select status from private.trust where user_id = test.uid('A')) = 'restricted',
  'gleiche Nachricht an 5 Matches schränkt den Account ein');
select test.ok(exists (select 1 from private.trust_events where user_id = test.uid('A') and signal = 'repeated_message'),
  'Trust-Event wird protokolliert');
set role authenticated;
select test.login(test.uid('A'));
select test.throws(format($$insert into public.messages (match_id, sender_id, body) values (%L, %L, 'www.example.com')$$,
  (select match_id from public.get_matches() where state = 'active' limit 1), test.uid('A')),
  'links_not_allowed', 'eingeschränkte Accounts dürfen keine Links senden');
select test.login(test.uid('D'));
select test.ok(not exists (select 1 from public.get_candidates(50) where id = test.uid('A')),
  'eingeschränkte Accounts werden nicht vorgeschlagen');

-- ---------------------------------------------------------------------------
-- Push-Tokens & Konto löschen
-- ---------------------------------------------------------------------------

select test.login(test.n());
select public.register_device_token('token-n', 'android');
select test.ok((select count(*) from public.device_tokens) = 1, 'Push-Token gespeichert');
select public.delete_my_account(true, 'Danke für alles!');
reset role;
select test.ok(not exists (select 1 from auth.users where id = test.n()), 'Konto gelöscht');
select test.ok(not exists (select 1 from public.profiles where id = test.n()), 'Profil gelöscht');
select test.ok(not exists (select 1 from public.device_tokens where token = 'token-n'), 'Push-Token gelöscht');
select test.ok((select found_someone from private.account_deletions) and
               (select count(*) from private.account_deletions) = 1, '"Jemanden gefunden" anonym gezählt');
