# Lotus einrichten – wer macht was

Kurz gesagt: **Konten anlegen und Verträge abschließen musst du selbst**, weil das in deinem Namen passiert
(Ausweis, Zahlungsdaten, Zustimmung zu AGB und Auftragsverarbeitungsverträgen). Alles danach, also Datenbank,
Funktionen und App-Build, erledigt `scripts/deploy.sh`, und das kann ich für dich ausführen.

Zeitaufwand für deinen Teil: etwa 1–2 Stunden, dazu Wartezeit für die Identitätsprüfung bei Google (meist 1–3 Tage).

## 1. Das kannst nur du (in dieser Reihenfolge)

| # | Konto | Kosten | Wofür | Hinweise |
|---|---|---|---|---|
| 1 | **Supabase** – supabase.com | 0 € | Datenbank, Login, Fotos, Chat | Mit GitHub anmelden. Neues Projekt: Name `lotus`, Region **Central EU (Frankfurt)**, ein starkes Datenbank-Passwort (im Passwortmanager speichern). Der **AV-Vertrag (DPA)** gilt automatisch über die Nutzungsbedingungen (Organization settings → Legal Documents → *View DPA*, PDF für die eigenen Unterlagen speichern). |
| 2 | **Google Play Console** – play.google.com/console | 25 $ einmalig | App verteilen, Abo & Spenden | Kontotyp „Privatperson“. Google prüft deinen Ausweis. Für Plus/Spenden zusätzlich das **Händlerkonto** (Zahlungsprofil) einrichten; Name und Adresse werden dann im Store angezeigt. |
| 3 | **Firebase** – console.firebase.google.com | 0 € | Push-Benachrichtigungen | Projekt anlegen (Google Analytics **aus**), Android-App mit Paketname `app.lotusdating.lotus` hinzufügen. |
| 4 | **E-Mail-Versand (SMTP)** | 0 € im Gratis-Kontingent | Anmeldecodes verschicken | Ohne eigenen SMTP verschickt Supabase nur wenige Mails pro Stunde. Ein EU-Anbieter mit Gratis-Kontingent (z. B. Brevo oder Mailjet) reicht. Absenderadresse bestätigen, AV-Vertrag abschließen. |
| 5 | **Impressum** | – | Pflicht | Deine Daten in `app/lib/legal/legal_info.dart` eintragen, oder sag sie mir (Name, Anschrift ohne Postfach, E-Mail, Telefon), dann trage ich sie ein. |
| 6 | **Gewerbe** (erst wenn Geld fließt) | ca. 20–60 € | Plus & Spenden | Siehe `docs/IMPRESSUM.md`, Abschnitt „Was sich ändert …“. |

**Nie ins Chat-Fenster kopieren:** Passwörter, API-Schlüssel und Service-Account-Dateien.

## 2. Zugänge so hinterlegen, dass ich deployen kann

Im Claude-Code-Fenster oben im Titel das Cloud-Environment öffnen → **Edit** → bei *Network secrets*
(bzw. *API credentials* oder als Umgebungsvariable) eintragen:

| Name | Woher |
|---|---|
| `SUPABASE_ACCESS_TOKEN` | supabase.com → Account → Access Tokens → „Generate new token“ |
| `SUPABASE_PROJECT_REF` | Projekt-URL `https://<ref>.supabase.co` → der Teil `<ref>` |
| `SUPABASE_DB_PASSWORD` | das Datenbank-Passwort aus Schritt 1 |
| `FIREBASE_SERVICE_ACCOUNT` | Firebase → Projekteinstellungen → Dienstkonten → „Neuen privaten Schlüssel generieren“ → Inhalt der JSON-Datei |
| `GOOGLE_PLAY_SERVICE_ACCOUNT` | Google Cloud → Dienstkonto anlegen → JSON-Schlüssel; dieses Konto in der Play Console unter „Nutzer und Berechtigungen“ einladen (Finanzdaten ansehen, Bestellungen und Abos verwalten) |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_SENDER` | vom SMTP-Anbieter |

Danach eine **neue Sitzung** starten und mir sagen: „Deploy Lotus“.

**Backups:** Für die tägliche Sicherung zusätzlich einen EU-Objektspeicher anlegen und die Backup-Secrets direkt
in GitHub hinterlegen – Schritt für Schritt in `docs/BACKUP.md`.

## 2a. Stand Oktober 2026 – so ist es tatsächlich eingerichtet

Die Cloud-Umgebung bietet **Network Secrets**: Der Wert wird automatisch an Anfragen an einen Host angehängt,
Claude sieht ihn nie. Deshalb gilt statt der Tabelle oben:

| Wert | Wo |
|---|---|
| Supabase Access Token | Network Secret, Typ *Bearer*, Host `api.supabase.com` |
| `FIREBASE_SERVICE_ACCOUNT` | direkt in Supabase: Edge Functions → Secrets |
| SMTP-Zugang (später) | direkt in Supabase: Authentication → SMTP Settings |
| `GOOGLE_PLAY_SERVICE_ACCOUNT` (später) | direkt in Supabase: Edge Functions → Secrets |
| Projekt-Ref, Firebase-App-Werte | öffentlich, in `config/public.env` |
| DB-Passwort | nicht nötig |

**Für die Deploy-Sitzung (Claude):** `scripts/deploy.sh` erwartet noch Umgebungsvariablen und das DB-Passwort.
Vor dem ersten Deploy auf reine Management-API umstellen (`api.supabase.com`, Authorization kommt vom Proxy):
Migrationen über `/database/query` mit eigener Versionstabelle, Auth-Config per `PATCH /config/auth`,
`NOTIFY_WEBHOOK_SECRET` per `POST /secrets` (Wert selbst erzeugen), Edge Functions per Deploy-Endpunkt bzw.
`supabase functions deploy --use-api`, Publishable Key per `GET /api-keys`. Zuerst mit einem harmlosen
`GET /v1/projects` prüfen, ob der Proxy den Token anhängt. `FIREBASE_SERVICE_ACCOUNT` nicht setzen – der liegt schon in Supabase.

## 3. Das erledigt `scripts/deploy.sh`

1. Datenbank-Migrationen einspielen (`supabase db push`)
2. E-Mail-Vorlage für den Anmeldecode und SMTP setzen
3. Secrets für die Edge Functions setzen
4. Edge Functions `notify` und `verify-purchase` deployen
5. Datenbank mit der Push-Function verbinden (`private.settings`)
6. Dich als Admin eintragen (`--admin du@example.de`, nachdem du dich einmal in der App angemeldet hast)

Die APK baue ich anschließend mit deinen Projektwerten. Hochladen in die Play Console musst du wieder selbst.

**Einladungen:** Solange es noch keinen Admin gibt, kann sich jede:r registrieren – so kommst du selbst als
Erste:r hinein. Sobald du Admin bist, gilt die Einladungspflicht. Dann im Admin-Bereich → Einladungen Codes
erstellen (z. B. 10 Stück für Stuttgart mit der Notiz „Freundeskreis“) und verschicken. Wer keinen Code hat,
landet auf der Warteliste und kann dort freigeschaltet werden. Für einen offenen Start die Pflicht abschalten:
`update private.settings set value = 'false' where key = 'invite_required';`

## 4. In der Play Console (du)

1. App anlegen: Name „Lotus“, Kategorie „Dating“, kostenlos.
2. **Monetarisierung → Produkte:** Abo `lotus_plus_monatlich` (3,99 €/Monat); In-App-Produkte
   `spende_klein` (3 €), `spende_mittel` (5 €), `spende_gross` (10 €), `beitrag_erfolg` (15 €).
3. **Store-Eintrag:** Datenschutzerklärung-URL, Impressum-URL, Altersfreigabe-Fragebogen
   (Dating → 18+), Formular „Datensicherheit“.
4. **Test → Interner Test:** App-Bundle hochladen, Tester:innen per E-Mail-Liste einladen (bis zu 100).
