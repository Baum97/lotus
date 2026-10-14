-- Lotus – Einwilligung nach Art. 9 DSGVO und Datenauskunft nach Art. 15/20 DSGVO.
--
-- "Wen möchtest du kennenlernen?" lässt Rückschlüsse auf die sexuelle Orientierung zu (besondere
-- Kategorie, Art. 9 Abs. 1). Verarbeitet wird sie nur mit ausdrücklicher Einwilligung (Art. 9 Abs. 2 lit. a),
-- ausschließlich fürs Matching und nie angezeigt. Die Einwilligung ist nachweisbar (Art. 7 Abs. 1) und
-- jederzeit widerrufbar (Art. 7 Abs. 3); nach Widerruf werden die Suchangaben gelöscht.

-- ---------------------------------------------------------------------------
-- Einwilligungen
-- ---------------------------------------------------------------------------

-- Verlauf statt Überschreiben: jede Erteilung ist eine eigene Zeile, ein Widerruf setzt withdrawn_at.
create table public.consents (
  id uuid primary key default gen_random_uuid(),
  -- am Konto, nicht am Profil: im Onboarding wird eingewilligt, bevor das Profil gespeichert wird
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null check (kind in ('sensitive_matching')),
  -- Version des Einwilligungstextes, dem zugestimmt wurde (Text steht in der App, siehe consent_text_*)
  version text not null check (char_length(version) between 1 and 40),
  granted_at timestamptz not null default now(),
  withdrawn_at timestamptz
);
create index consents_user_kind_idx on public.consents (user_id, kind, granted_at desc);

create function private.has_consent(p_user uuid, p_kind text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.consents c
    where c.user_id = p_user and c.kind = p_kind and c.withdrawn_at is null
  )
$$;

create function public.give_consent(p_kind text, p_version text) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_me uuid := auth.uid();
begin
  if v_me is null then
    perform private.fail('not_authenticated');
  end if;
  if private.has_consent(v_me, p_kind) then
    return;
  end if;
  insert into public.consents (user_id, kind, version) values (v_me, p_kind, p_version);
end;
$$;

-- Widerruf: Einwilligung beenden und die darauf beruhenden Daten löschen (Suchangaben inkl.
-- Orientierung). Danach ist die Person nicht mehr auffindbar, bis sie erneut einwilligt.
create function public.withdraw_consent(p_kind text) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_me uuid := auth.uid();
begin
  if v_me is null then
    perform private.fail('not_authenticated');
  end if;
  update public.consents set withdrawn_at = now()
  where user_id = v_me and kind = p_kind and withdrawn_at is null;
  if p_kind = 'sensitive_matching' then
    delete from public.match_preferences where user_id = v_me;
  end if;
end;
$$;

-- Ohne Einwilligung kann die App keine Suchangaben speichern – egal über welchen Weg.
-- Gilt für Anfragen der App (Rolle authenticated), nicht für Admin-Werkzeuge und Tests.
create function private.require_matching_consent() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if current_setting('role', true) = 'authenticated'
     and not private.has_consent(new.user_id, 'sensitive_matching') then
    perform private.fail('consent_required');
  end if;
  return new;
end;
$$;

create trigger match_preferences_require_consent
before insert or update on public.match_preferences
for each row execute function private.require_matching_consent();

-- Gelöschte Suchangaben müssen auch aus der Such-Tabelle verschwinden
create trigger match_preferences_discovery_delete after delete on public.match_preferences
for each row execute function private.on_discovery_source_change();

-- ---------------------------------------------------------------------------
-- Datenauskunft (Art. 15) in maschinenlesbarer Form (Art. 20)
-- ---------------------------------------------------------------------------

-- Alle personenbezogenen Daten der anfragenden Person als JSON, plus die Pflichtinformationen
-- nach Art. 15 Abs. 1 und 2. Daten anderer werden nur so weit aufgenommen, wie die Person sie in der
-- App ohnehin sieht (Art. 15 Abs. 4): keine Melder:innen, keine Liste, wem man gezeigt wurde.
create function public.export_my_data() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_me uuid := auth.uid();
begin
  if v_me is null then
    perform private.fail('not_authenticated');
  end if;

  return jsonb_build_object(
    'export', jsonb_build_object(
      'format_version', 1,
      'created_at', now(),
      'user_id', v_me,
      'note', 'Datenauskunft nach Art. 15 DSGVO in maschinenlesbarer Form (Art. 20 DSGVO).'),

    'information', jsonb_build_object(
      'controller', 'Siehe Impressum in der App (Profil → Impressum).',
      'purposes', jsonb_build_array(
        'Bereitstellung der Dating-App: Profil, Vorschläge, Likes, Matches, Chat',
        'Passende Vorschläge auf Basis deiner Suchangaben (inkl. wen du kennenlernen möchtest)',
        'Sicherheit: Verifizierung, Missbrauchs- und Spam-Erkennung, Bearbeitung von Meldungen',
        'Lotus Plus, Spenden und Beiträge (Prüfung der Käufe bei Google Play)',
        'Push-Benachrichtigungen, sofern eingeschaltet'),
      'legal_bases', jsonb_build_array(
        'Art. 6 Abs. 1 lit. b DSGVO – Vertrag (Nutzung der App)',
        'Art. 9 Abs. 2 lit. a DSGVO – ausdrückliche Einwilligung für Angaben, die Rückschlüsse auf die sexuelle Orientierung zulassen',
        'Art. 6 Abs. 1 lit. f DSGVO – berechtigtes Interesse an Sicherheit und Missbrauchsabwehr',
        'Art. 6 Abs. 1 lit. c DSGVO – rechtliche Pflichten (z. B. Aufbewahrung von Zahlungsbelegen)'),
      'categories', jsonb_build_array(
        'Konto (E-Mail-Adresse)', 'Profil (Name, Geburtsdatum, Geschlecht, Stadt, Texte, Fotos)',
        'Suchangaben (wen du kennenlernen möchtest, Dating-Ziel, Alter, Entfernung, Kinderwunsch, Rauchen)',
        'ungefährer Standort', 'Likes, Matches, Nachrichten', 'Verifizierungs-Selfie',
        'Sicherheits- und Moderationsdaten', 'Käufe', 'Geräte-Token für Push'),
      'recipients', jsonb_build_array(
        'Supabase Inc. – Hosting von Datenbank, Dateien und Login in der EU (Frankfurt), Auftragsverarbeiter',
        'Google Ireland Ltd. – Firebase Cloud Messaging (Push) und Google Play (Käufe), sofern genutzt',
        'Andere Nutzer:innen sehen nur dein öffentliches Profil – nie deine Orientierung, dein Geburtsdatum oder deinen Standort'),
      'storage_period', jsonb_build_array(
        'Bis zur Löschung deines Kontos; danach werden alle Daten gelöscht.',
        'Anzeige-Protokoll (wem du vorgeschlagen wurdest): 60 Tage; Tageszähler: 8 Tage.',
        'Bei Kontolöschung bleibt nur anonym, ob du jemanden gefunden hast.',
        'Zahlungsbelege nur, soweit gesetzlich vorgeschrieben.'),
      'automated_decisions', 'Vorschläge entstehen automatisch: gegenseitige Filter (Geschlecht, Alter, Entfernung, optionale Ausschlusskriterien), dann gleiche Absicht und Fairness (selten Gezeigte zuerst). Dein eigenes Like-Verhalten beeinflusst deine Sichtbarkeit nicht. Es gibt keine automatisierte Entscheidung mit rechtlicher Wirkung im Sinne von Art. 22 DSGVO.',
      'source', 'Von dir selbst angegeben; Likes und Nachrichten stammen teils von anderen Nutzer:innen.',
      'rights', jsonb_build_array(
        'Auskunft (Art. 15) – diese Datei', 'Berichtigung (Art. 16) – im Profil',
        'Löschung (Art. 17) – Profil → Konto löschen', 'Einschränkung (Art. 18)',
        'Datenübertragbarkeit (Art. 20) – diese Datei', 'Widerspruch (Art. 21)',
        'Widerruf der Einwilligung jederzeit (Art. 7 Abs. 3) – Profil → Datenschutz',
        'Beschwerde bei einer Datenschutz-Aufsichtsbehörde (Art. 77), z. B. der deines Wohnorts')),

    'account', (
      select jsonb_build_object('email', u.email, 'created_at', u.created_at, 'last_sign_in_at', u.last_sign_in_at)
      from auth.users u where u.id = v_me),

    'profile', (select to_jsonb(p) from public.profiles p where p.id = v_me),

    'search_preferences', (select to_jsonb(mp) - 'user_id' from public.match_preferences mp where mp.user_id = v_me),

    'consents', coalesce((
      select jsonb_agg(jsonb_build_object('kind', c.kind, 'version', c.version,
                                          'granted_at', c.granted_at, 'withdrawn_at', c.withdrawn_at)
                       order by c.granted_at)
      from public.consents c where c.user_id = v_me), '[]'),

    'location', (
      select jsonb_build_object(
        'latitude', extensions.st_y(l.location::extensions.geometry),
        'longitude', extensions.st_x(l.location::extensions.geometry),
        'updated_at', l.updated_at,
        'travel_city', l.travel_city, 'travel_until', l.travel_until,
        'travel_latitude', extensions.st_y(l.travel_location::extensions.geometry),
        'travel_longitude', extensions.st_x(l.travel_location::extensions.geometry))
      from public.profile_locations l where l.user_id = v_me),

    'photos', coalesce((
      select jsonb_agg(jsonb_build_object('storage_path', ph.storage_path, 'position', ph.position,
                                          'moderation', ph.moderation, 'created_at', ph.created_at)
                       order by ph.position)
      from public.photos ph where ph.user_id = v_me), '[]'),

    'prompt_answers', coalesce((
      select jsonb_agg(jsonb_build_object('prompt', pr.text, 'answer', pa.answer, 'created_at', pa.created_at)
                       order by pa.position)
      from public.prompt_answers pa join public.prompts pr on pr.id = pa.prompt_id
      where pa.user_id = v_me), '[]'),

    'likes_sent', coalesce((
      select jsonb_agg(jsonb_build_object('to', o.display_name, 'to_user_id', l.to_user, 'target', l.target_type,
                                          'comment', l.comment, 'is_like_back', l.is_like_back, 'created_at', l.created_at)
                       order by l.created_at)
      from public.likes l left join public.profiles o on o.id = l.to_user
      where l.from_user = v_me), '[]'),

    'likes_received', coalesce((
      select jsonb_agg(jsonb_build_object('from', o.display_name, 'from_user_id', l.from_user, 'target', l.target_type,
                                          'comment', l.comment, 'created_at', l.created_at)
                       order by l.created_at)
      from public.likes l left join public.profiles o on o.id = l.from_user
      where l.to_user = v_me), '[]'),

    'passes', coalesce((
      select jsonb_agg(jsonb_build_object('user_id', p.to_user, 'created_at', p.created_at, 'undone_at', p.undone_at)
                       order by p.created_at)
      from public.passes p where p.from_user = v_me), '[]'),

    'matches', coalesce((
      select jsonb_agg(jsonb_build_object(
        'match_id', m.id, 'with', o.display_name, 'state', m.state, 'created_at', m.created_at,
        'closed_at', m.closed_at, 'close_reason', m.close_reason,
        'messages', coalesce((
          select jsonb_agg(jsonb_build_object('from_me', msg.sender_id = v_me, 'body', msg.body,
                                              'created_at', msg.created_at)
                           order by msg.created_at)
          from public.messages msg where msg.match_id = m.id), '[]'))
        order by m.created_at)
      from public.matches m
      left join public.profiles o on o.id = case when m.user_a = v_me then m.user_b else m.user_a end
      where v_me in (m.user_a, m.user_b)), '[]'),

    'blocks', coalesce((
      select jsonb_agg(jsonb_build_object('blocked_user_id', b.blocked, 'created_at', b.created_at))
      from public.blocks b where b.blocker = v_me), '[]'),

    'reports_made', coalesce((
      select jsonb_agg(jsonb_build_object('reported_user_id', r.reported, 'reason', r.reason, 'details', r.details,
                                          'created_at', r.created_at, 'resolved_at', r.resolved_at))
      from public.reports r where r.reporter = v_me), '[]'),

    'moderation', jsonb_build_object(
      'status', (select t.status from private.trust t where t.user_id = v_me),
      'status_reason', (select t.reason from private.trust t where t.user_id = v_me),
      'signals', coalesce((
        select jsonb_agg(jsonb_build_object('signal', e.signal, 'created_at', e.created_at) order by e.created_at)
        from private.trust_events e where e.user_id = v_me), '[]'),
      -- Meldungen gegen dich: nur Grund und Datum, nie wer gemeldet hat (Schutz der Melder:innen)
      'reports_against_you', coalesce((
        select jsonb_agg(jsonb_build_object('reason', r.reason, 'created_at', r.created_at, 'resolved_at', r.resolved_at))
        from public.reports r where r.reported = v_me), '[]')),

    'verification', coalesce((
      select jsonb_agg(jsonb_build_object('status', v.status, 'gesture', v.gesture, 'selfie_path', v.selfie_path,
                                          'created_at', v.created_at, 'reviewed_at', v.reviewed_at)
                       order by v.created_at)
      from public.verification_requests v where v.user_id = v_me), '[]'),

    'visibility', jsonb_build_object(
      'times_shown_to_others_last_60_days', (select count(*) from public.impressions i where i.shown = v_me),
      'profiles_shown_to_you_last_60_days', (select count(*) from public.impressions i where i.viewer = v_me)),

    'notification_settings', (
      select to_jsonb(n) - 'user_id' from public.notification_settings n where n.user_id = v_me),

    'devices', coalesce((
      select jsonb_agg(jsonb_build_object('platform', d.platform, 'token', d.token, 'updated_at', d.updated_at))
      from public.device_tokens d where d.user_id = v_me), '[]'),

    'lotus_plus', (
      select jsonb_build_object('source', e.source, 'valid_until', e.valid_until)
      from private.entitlements e where e.user_id = v_me),

    'contributions', coalesce((
      select jsonb_agg(jsonb_build_object('kind', c.kind, 'product_id', c.product_id, 'amount_micros', c.amount_micros,
                                          'currency', c.currency, 'created_at', c.created_at))
      from public.contributions c where c.user_id = v_me), '[]')
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Rechte & RLS
-- ---------------------------------------------------------------------------

revoke all on public.consents from anon, authenticated;
grant select on public.consents to authenticated;
alter table public.consents enable row level security;
create policy consents_own on public.consents
  for select to authenticated
  using (user_id = (select auth.uid()));

revoke execute on function
  private.has_consent(uuid, text), private.require_matching_consent(),
  public.give_consent(text, text), public.withdraw_consent(text), public.export_my_data()
from public, anon, authenticated;

grant execute on function
  public.give_consent(text, text), public.withdraw_consent(text), public.export_my_data()
to authenticated;
