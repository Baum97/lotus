#!/usr/bin/env bash
# Spielt ein Daten-Backup in eine Datenbank ein, in der die Migrationen schon laufen
# (neues Supabase-Projekt: erst `supabase db push`, dann dieses Skript).
#
#   TARGET_DB_URL=… BACKUP_PASSPHRASE=… scripts/restore-backup.sh lotus-…-data.sql.gpg --yes
#
# ACHTUNG: Für eine leere Datenbank gedacht. Startdaten der Migrationen (Prompt-Katalog,
# Storage-Buckets) werden ersetzt; vorhandene Nutzerdaten führen zu Fehlern und Abbruch.
set -euo pipefail

: "${TARGET_DB_URL:?fehlt – Ziel-Datenbank}"
: "${BACKUP_PASSPHRASE:?fehlt}"
file="${1:?Backup-Datei (…-data.sql.gpg) fehlt}"
if [[ "${2:-}" != "--yes" ]]; then
  echo "Sicherheitsabfrage: mit --yes bestätigen, dass $TARGET_DB_URL die richtige (leere) Datenbank ist." >&2
  exit 1
fi

# Erst vollständig entschlüsseln und prüfen – sonst würde psql bei falscher Passphrase
# trotzdem laufen und eine leere Eingabe bestätigen.
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
gpg --batch --quiet --pinentry-mode loopback --passphrase-fd 3 --decrypt -o "$work/data.sql" "$file" \
  3<<<"$BACKUP_PASSPHRASE"
if ! grep -q '^COPY "auth"."users"' "$work/data.sql"; then
  echo "Backup unvollständig oder beschädigt – nichts eingespielt." >&2
  exit 1
fi

psql "$TARGET_DB_URL" -v ON_ERROR_STOP=1 -q --single-transaction \
  -c "set session_replication_role = replica" \
  -c "truncate public.prompts restart identity cascade" \
  -c "delete from storage.buckets where id in ('photos', 'selfies')" \
  -f "$work/data.sql"

psql "$TARGET_DB_URL" -qtAc "select 'Wiederhergestellt: ' || (select count(*) from auth.users) || ' Konten, '
  || (select count(*) from public.profiles) || ' Profile, ' || (select count(*) from public.messages) || ' Nachrichten'"
