# Backup & Wiederherstellung

Der Workflow [`.github/workflows/backup.yml`](../.github/workflows/backup.yml) sichert die Supabase-Datenbank
**täglich um 02:23 UTC** (und auf Knopfdruck unter *Actions → Backup → Run workflow*):

- **Was:** alle Daten – Konten (`auth`), App-Daten (`public`) und interne Daten (`private`), dazu das Schema.
- **Wie:** `supabase db dump`, danach mit AES-256 verschlüsselt (`gpg`, Passphrase nur in GitHub-Secrets).
- **Wohin:** in einen eigenen S3-kompatiblen Speicher in der EU. Backups älter als 30 Tage werden gelöscht.
- **Nicht enthalten:** Fotos und Selfies (Supabase Storage), siehe unten.

> **Warum nicht als GitHub-Artefakt?** Das Repository ist öffentlich. Artefakte öffentlicher Repositories kann
> jede angemeldete GitHub-Person herunterladen. Verschlüsselte, aber sensible Nutzerdaten (inkl. Angaben nach
> Art. 9 DSGVO) gehören dort nicht hin. Der Workflow bricht deshalb ab, solange kein EU-Speicher eingerichtet
> ist. Nur bei einem **privaten** Repository speichert er ersatzweise als Artefakt (30 Tage).

## Einrichten (einmalig, ca. 15 Minuten)

1. **EU-Speicher anlegen** – S3-kompatibler Objektspeicher mit Rechenzentrum in der EU, z. B. Hetzner Object
   Storage, IONOS S3 oder Scaleway (wenige Cent pro Monat bei dieser Datenmenge). Einen **privaten** Bucket
   anlegen (z. B. `lotus-backups`) und Zugangsschlüssel erzeugen, die nur auf diesen Bucket dürfen.
   AV-Vertrag mit dem Anbieter abschließen.
2. **Passphrase erzeugen** (mindestens 32 Zeichen) und zusätzlich offline sicher aufbewahren, z. B. im
   Passwortmanager. **Ohne Passphrase ist jedes Backup wertlos.**
   ```bash
   openssl rand -base64 48
   ```
3. **Datenbank-URL:** Supabase-Dashboard → *Connect* → **Session pooler** (funktioniert mit IPv4, wie GitHub es
   braucht), Passwort einsetzen.
4. **GitHub-Secrets** unter *Settings → Secrets and variables → Actions → New repository secret*:

   | Secret | Inhalt |
   |---|---|
   | `SUPABASE_DB_URL` | Session-Pooler-URL aus Schritt 3 |
   | `BACKUP_PASSPHRASE` | Passphrase aus Schritt 2 |
   | `BACKUP_S3_ENDPOINT` | z. B. `https://fsn1.your-objectstorage.com` (steht beim Anbieter) |
   | `BACKUP_S3_BUCKET` | z. B. `lotus-backups` |
   | `BACKUP_S3_ACCESS_KEY`, `BACKUP_S3_SECRET_KEY` | Zugangsschlüssel aus Schritt 1 |
   | `BACKUP_S3_REGION` | optional, z. B. `eu-central` (Standard: `eu-central-1`) |

5. *Actions → Backup → Run workflow* einmal von Hand starten und prüfen, dass zwei `.sql.gpg`-Dateien im Bucket
   liegen.

Schlägt ein Lauf fehl, schickt GitHub eine E-Mail. Solange die Secrets fehlen, beendet sich der Workflow ohne
Fehler mit einem Hinweis. **Wichtig:** GitHub pausiert geplante Workflows in Repositories ohne Aktivität für
60 Tage – dann im Actions-Tab wieder aktivieren.

## Wiederherstellen

Getestet: Sichern → Verschlüsseln → Datenbank leeren → Zurückspielen ergibt exakt dieselben Daten.

1. Neues (leeres) Supabase-Projekt anlegen, Migrationen einspielen: `npx supabase db push`
2. Backup aus dem Bucket herunterladen (`lotus-<datum>-data.sql.gpg`).
3. Einspielen:
   ```bash
   TARGET_DB_URL='<Session-Pooler-URL des neuen Projekts>' BACKUP_PASSPHRASE='…' \
     scripts/restore-backup.sh lotus-<datum>-data.sql.gpg --yes
   ```
   Das Skript entschlüsselt zuerst vollständig und spielt erst dann alles in **einer** Transaktion ein. Bei
   falscher Passphrase oder beschädigter Datei bleibt die Datenbank unverändert.
4. Edge Functions und Secrets wie in `docs/EINRICHTUNG.md` einrichten, App-Konfiguration auf das neue Projekt
   umstellen.

Einmal im Quartal einen Probelauf in ein Test-Projekt machen: Ein Backup, das nie zurückgespielt wurde, ist
nur eine Hoffnung.

## Fotos & Selfies

Dateien in Supabase Storage sind nicht in der Datenbank-Sicherung (dort stehen nur die Verweise). Für die Beta
ist das vertretbar: Bei einem Totalverlust können Nutzer:innen ihre Fotos neu hochladen. Sobald es mehr
Nutzer:innen gibt, lohnt sich eine zusätzliche wöchentliche Sicherung der Buckets über die S3-Schnittstelle von
Supabase Storage (z. B. mit `rclone sync`) in denselben EU-Speicher.

## Datenschutz

- Backups enthalten personenbezogene Daten; sie liegen verschlüsselt in der EU, Zugriff hat nur, wer die
  Passphrase kennt.
- **Gelöschte Konten** verschwinden aus den Backups spätestens nach 30 Tagen. Bei einer Wiederherstellung
  müssen Konten, die nach dem Backup-Datum gelöscht wurden, erneut gelöscht werden (Nachweis über die
  Löschanfragen). Das gehört so in die Datenschutzerklärung (Speicherdauer von Backups).
