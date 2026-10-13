-- Lastdaten für den Vorschlags-Benchmark (nur lokal, siehe scripts/bench-db.sh):
-- :users Profile in Deutschland, ein Viertel davon im Raum Stuttgart, dazu 30 Tage Impressionen.
\set ON_ERROR_STOP 1
set client_min_messages = warning;

insert into auth.users (id)
select ('20000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid from generate_series(1, :users) n;

insert into public.profiles (id, display_name, birthdate, gender, city, last_active_at)
select ('20000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid, 'P' || n,
       current_date - make_interval(years => 20 + n % 30, days => n % 300),
       (array['woman', 'man', 'diverse']::public.gender[])[1 + n % 3 - case when n % 3 = 2 and n % 20 <> 0 then 1 else 0 end],
       'Ort', now() - make_interval(days => n % 20)
from generate_series(1, :users) n;

insert into public.match_preferences (user_id, interested_in, intention, age_min, age_max, max_distance_km, children, smoking)
select id, case gender when 'woman' then '{man}'::public.gender[] when 'man' then '{woman}' else '{woman,man,diverse}' end,
       (array['relationship', 'open_to_relationship', 'unsure']::public.intention[])[1 + (hashtext(id::text) & 3) % 3],
       20, 50, 50,
       (array['want', 'dont_want', 'open', 'have_kids', null]::public.children_wish[])[1 + (hashtext(id::text) & 7) % 5],
       (array['never', 'sometimes', null]::public.smoking[])[1 + (hashtext(id::text) & 3) % 3]
from public.profiles where id::text like '20000000%';

-- Ein Viertel im Raum Stuttgart (±0,5°), der Rest über Deutschland verteilt
insert into public.profile_locations (user_id, location)
select id, extensions.st_setsrid(extensions.st_makepoint(
         case when n % 4 = 0 then 9.18 + (random() - 0.5) else 6 + random() * 9 end,
         case when n % 4 = 0 then 48.78 + (random() - 0.5) else 47.5 + random() * 7 end), 4326)::extensions.geography
from (select id, row_number() over () n from public.profiles where id::text like '20000000%') p;

insert into public.photos (user_id, storage_path, position, moderation)
select id, id || '/0.jpg', 0, 'approved' from public.profiles where id::text like '20000000%';

-- Jede Person im Raum Stuttgart hat an 30 Tagen je ~20 Profile gesehen
insert into public.impressions (viewer, shown, shown_on)
select v.id, s.id, current_date - d
from (select id from public.profiles where id::text like '20000000%' order by id limit :users / 20) v
cross join generate_series(0, 29) d
cross join lateral (
  select id from public.profiles where id::text like '20000000%'
  offset (hashtext(v.id::text || d) & 1023) limit 20) s
on conflict do nothing;

analyze;
