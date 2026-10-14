# Lotus

[![CI](https://github.com/Baum97/lotus/actions/workflows/ci.yml/badge.svg)](https://github.com/Baum97/lotus/actions/workflows/ci.yml)

Eine Dating-App, die darauf ausgelegt ist, dass Menschen wirklich jemanden finden – kein Cashgrab.
Arbeitstitel; Beta in Stuttgart und Ulm.

- **Konzept & Entscheidungen:** [`docs/KONZEPT.md`](docs/KONZEPT.md)
- **App (Flutter, Android-first):** [`app/`](app/README.md)
- **Backend (Supabase: Postgres/PostGIS, Auth, Storage, Realtime):** [`supabase/`](supabase/)
- **Einrichtung – wer macht was:** [`docs/EINRICHTUNG.md`](docs/EINRICHTUNG.md) · Deploy: `scripts/deploy.sh`
- **Skalierung & Lasttest:** [`docs/SKALIERUNG.md`](docs/SKALIERUNG.md)
- **Backup & Wiederherstellung:** [`docs/BACKUP.md`](docs/BACKUP.md) – täglich, verschlüsselt, EU-Speicher

## Regeln, die die Datenbank durchsetzt

| Regel | Wert |
|---|---|
| Likes pro Tag | 20 (Reset um Mitternacht, Europe/Berlin) – Vorschläge gibt es, bis sie aufgebraucht sind |
| Zurück-Liken | kostet kein Budget |
| Wegwischen rückgängig | 3× pro Monat, nur die letzte Entscheidung |
| Aktive Chats | max. 6, weitere Matches warten in einer Warteschlange |
| Chatten | erst nach Selfie-Verifizierung (in der Beta manuell im Admin-Bereich geprüft) |
| Eingeschlafene Chats | werden nach 7 Tagen ohne Nachricht geschlossen |
| Orientierung („Wen möchtest du kennenlernen?“) | nie sichtbar, nur fürs Matching; nur mit ausdrücklicher, widerrufbarer Einwilligung (Art. 9 DSGVO) |
| Datenauskunft | „Meine Daten herunterladen“ (Art. 15/20 DSGVO) als JSON inkl. Pflichtinformationen |
| Dating-Ziel | immer fürs Matching, Anzeige optional privat |
| Geburtsdatum, Standort | nie für andere sichtbar (nur Alter, gerundete Entfernung) |
| Fotos | sofort sichtbar, bis ein Admin sie ablehnt |
| Spam | gleiche Nachricht an ≥ 5 Matches → Konto eingeschränkt |
| Suchradius | 1–150 km (Standard 50 km) |
| Kinderwunsch, Rauchen | optional; Anzeige abschaltbar; optionale Ausschlusskriterien wirken gegenseitig |
| Lotus Plus | nur Komfort (Reisemodus, eigene Statistiken) – kein Einfluss auf Sichtbarkeit oder Likes |

Das eigene Like-Verhalten beeinflusst **nie** die eigene Sichtbarkeit. Vorschläge werden nach
gegenseitigen Filtern, gleicher Absicht und einem Fairness-Kontingent (seltener Gezeigte zuerst) sortiert.

## Struktur

```
docs/KONZEPT.md                    Produktkonzept & Entscheidungen
app/                               Flutter-App (siehe app/README.md)
supabase/migrations/               Schema, Logik (RPC-Funktionen), Rechte, RLS, Storage
supabase/functions/notify/         Edge Function für Push-Benachrichtigungen (FCM)
supabase/functions/verify-purchase/ Edge Function: Käufe bei Google Play prüfen und freischalten
docs/IMPRESSUM.md                  Impressum-Vorlage mit Ausfüllhilfe
supabase/templates/                E-Mail-Vorlage für den Anmeldecode
supabase/tests/local/              Datenbank-Tests (laufen auf normalem Postgres + PostGIS)
scripts/test-db.sh                 Migrationen einspielen + Datenbank-Tests ausführen
scripts/bench-db.sh                Lasttest der Vorschläge mit vielen Profilen
scripts/backup-db.sh               Datenbank sichern und verschlüsseln (täglich per backup.yml)
scripts/restore-backup.sh          Backup in ein neues Projekt zurückspielen
.github/workflows/ci.yml           CI: Datenbank, Lasttest, Edge Functions, App, Android-Build, Skripte
scripts/seed-demo.py               Demo-Profile in Stuttgart/Ulm für die lokale Entwicklung
```

## Lokal entwickeln

Voraussetzungen: Docker, Node.js (für `npx supabase`), Flutter, Python 3 mit Pillow.

```bash
npx supabase start                       # lokales Supabase inkl. Migrationen
python3 scripts/seed-demo.py             # 12 Demo-Profile (Platzhalterfotos)
cd app && flutter run --dart-define=SUPABASE_URL=http://10.0.2.2:54321 \
                      --dart-define=SUPABASE_KEY=<PUBLISHABLE_KEY aus `npx supabase status`>
```

- Anmeldecodes landen lokal im Mail-Postfach unter <http://127.0.0.1:54324>.
- `python3 scripts/seed-demo.py --like-me du@example.com` lässt einige Demo-Personen dein Konto liken.
- Dich selbst zum Admin machen (lokal per `psql postgresql://postgres:postgres@127.0.0.1:54322/postgres`,
  online im SQL-Editor des Dashboards):
  `insert into private.admins (user_id) select id from auth.users where email = 'du@example.com';`

## Tests

```bash
PGHOST=localhost PGPORT=5432 PGUSER=postgres scripts/test-db.sh   # 166 Datenbank-Prüfungen
PGHOST=localhost PGPORT=5432 PGUSER=postgres scripts/bench-db.sh  # Lasttest (50.000 Profile)
cd app && dart format lib test && flutter analyze && flutter test # App
cd supabase/functions && deno fmt && deno lint                    # Edge Functions
```

Die **CI** (GitHub Actions) prüft bei jedem Push dasselbe automatisch. Dazu kommen ein Lasttest mit Zeitgrenze,
ein Android-Build (die Debug-APK liegt als Download am CI-Lauf) und `shellcheck`. Bei Pull Requests prüft sie
außerdem, dass bestehende Migrationen nicht verändert werden, sondern nur neue hinzukommen.

## Datenbank-API (für die App)

| Funktion | Zweck |
|---|---|
| `get_my_status()` | Profil-/Onboarding-Status, Restbudgets, Verifizierung, Admin |
| `save_profile(…)`, `set_location(lat, lon)` | Profil & Suchpräferenzen speichern, Standort (~1 km) setzen |
| `get_candidates(p_limit)` | nächste Vorschläge (leer, wenn das Like-Budget aufgebraucht ist) |
| `like_profile(p_to, p_target_type, p_target_id, p_comment)` | Like auf Foto/Prompt; gibt die Match-ID zurück, falls es ein Match ist |
| `pass_profile(p_to)`, `undo_last_pass()` | wegwischen, letztes Wegwischen rückgängig machen |
| `get_incoming_likes()` | „Wer dich mag“ |
| `get_profile(p_user)` | Profilkarte (nur öffentliche Angaben) einer Person, die man sehen darf |
| `get_matches()`, `close_match(p_match, p_goodbye)` | Chat-Übersicht, Gespräch beenden |
| `start_verification()`, `submit_verification(…)` | Gesten-Selfie |
| `delete_my_account(p_found_someone, p_feedback)` | Konto löschen, „jemanden gefunden“ anonym zählen |
| `register_device_token(…)` | Push-Token speichern |
| `set_travel_location(…)`, `clear_travel_location()`, `get_my_stats()` | Lotus Plus: Reisemodus, eigene Statistiken |
| `admin_*` | Selfies prüfen, Fotos moderieren, Meldungen bearbeiten, Konten einschränken/sperren |

Fehler kommen als stabile Schlüssel (`daily_like_limit_reached`, `monthly_undo_limit_reached`,
`profile_not_available`, …), die die App übersetzt. Auf `profiles` sind nur einzelne Spalten lesbar
(kein Geburtsdatum) – also `select('id, display_name, …')` statt `select('*')`.

## Beta starten – Checkliste

**Supabase (kostenlos)**
1. Projekt in der Region **EU (Frankfurt)** anlegen.
2. `npx supabase link --project-ref <ref>` und `npx supabase db push`.
3. Authentication → Email Templates: „Magic Link“ und „Confirm signup“ durch
   `supabase/templates/login_code.html` ersetzen (Betreff „Dein Lotus-Code“) – oder `npx supabase config push`.
4. Unter Integrations → Cron prüfen, dass die Jobs `lotus-close-stale-matches` und
   `lotus-cleanup-impressions` angelegt sind (die Migrationen aktivieren `pg_cron` selbst).
5. Dich als Admin eintragen (siehe oben).
6. Für mehr als ein paar Tester:innen einen eigenen SMTP-Versand einrichten (Supabase verschickt ohne
   SMTP nur wenige E-Mails pro Stunde), z. B. über einen EU-Anbieter mit Gratis-Kontingent.

**Push-Benachrichtigungen (kostenlos)**

Benachrichtigt werden: neue Nachrichten, neue Matches, freigewordene Chats, „Jemand mag dich“ (höchstens alle
6 Stunden). Nie mit Nachrichtentext. Jede Art lässt sich in der App unter Profil → Benachrichtigungen abschalten.
1. Firebase-Projekt anlegen, darin eine Android-App mit Paketname `app.lotusdating.lotus`.
   Projekteinstellungen → Dienstkonten → „Neuen privaten Schlüssel generieren“ (JSON).
2. `npx supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat service-account.json)" NOTIFY_WEBHOOK_SECRET=<langer Zufallswert>`
3. `npx supabase functions deploy notify --no-verify-jwt`
4. Im SQL-Editor die Datenbank mit der Function verbinden (die Trigger sind schon angelegt):
   ```sql
   insert into private.settings (key, value) values
     ('notify_url', 'https://<projekt>.supabase.co/functions/v1/notify'),
     ('notify_secret', '<derselbe Zufallswert>');
   ```
5. App mit den `FIREBASE_*`-Werten bauen (siehe `app/README.md`).

**Lotus Plus & Spenden (Google Play)**
1. Play Console → Monetarisierung: ein Abo `lotus_plus_monatlich` und die In-App-Produkte `spende_klein`,
   `spende_mittel`, `spende_gross`, `beitrag_erfolg` anlegen (IDs genau so, Preise frei wählbar).
   Dafür braucht die Play Console ein Händlerkonto (siehe `docs/IMPRESSUM.md` → „Was sich ändert …“).
2. Google Cloud: Dienstkonto anlegen, in der Play Console unter Nutzer & Berechtigungen einladen
   (Recht „Finanzdaten ansehen“ bzw. „Bestellungen und Abos verwalten“), JSON-Schlüssel herunterladen.
3. `npx supabase secrets set GOOGLE_PLAY_SERVICE_ACCOUNT="$(cat play-service-account.json)" ANDROID_PACKAGE_NAME=app.lotusdating.lotus`
4. `npx supabase functions deploy verify-purchase`
5. Beta ohne Zahlungen: Admin-Bereich → Lotus-Symbol oben rechts → Plus per E-Mail-Adresse für 30 Tage vergeben.

**App verteilen**
1. Google-Play-Entwicklerkonto (einmalig 25 $), App mit Signaturschlüssel bauen.
2. „Interner Test“ in der Play Console – bis zu 100 Tester:innen per E-Mail-Liste, ohne Review-Wartezeit.

**Rechtliches vor dem ersten fremden Nutzer** (siehe `docs/KONZEPT.md`, Abschnitt 8)
- Impressum: Angaben in `app/lib/legal/legal_info.dart` und `docs/IMPRESSUM.md` eintragen (Vorlage mit Ausfüllhilfe).
- Datenschutzerklärung (besondere Kategorien nach Art. 9 DSGVO: Orientierung), Nutzungsbedingungen
  – in der App verlinken.
- Datenschutz-Folgenabschätzung (DSFA) – bei Dating-Apps praktisch immer nötig.
- Auftragsverarbeitungsverträge mit Supabase (und ggf. Firebase, SMTP-Anbieter).
