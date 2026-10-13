-- Misst get_candidates für eine Person im Raum Stuttgart.
\set ON_ERROR_STOP 1
select set_config('request.jwt.claim.sub', (
  select p.id::text from public.profiles p join public.profile_locations l on l.user_id = p.id
  where p.id::text like '20000000%' and p.gender = 'woman'
    and extensions.st_dwithin(l.location, extensions.st_makepoint(9.18, 48.78)::extensions.geography, 20000)
  limit 1), false);
set role authenticated;
\timing on
select count(*) as kandidaten from public.get_candidates(10);
select count(*) as kandidaten from public.get_candidates(10);
select count(*) as kandidaten from public.get_candidates(10);
\timing off
reset role;
