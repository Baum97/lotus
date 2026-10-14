#!/usr/bin/env bash
# Sichert die Supabase-Datenbank (Konten, App-Daten, interne Daten) verschlüsselt.
#
#   SUPABASE_DB_URL=… BACKUP_PASSPHRASE=… scripts/backup-db.sh <ausgabe-ordner>
#
# Ergebnis: lotus-<zeitstempel>-{schema,data}.sql.gpg (AES-256, symmetrisch mit der Passphrase).
# Fotos und Selfies (Supabase Storage) sind NICHT enthalten, siehe docs/BACKUP.md.
set -euo pipefail

: "${SUPABASE_DB_URL:?fehlt – Session-Pooler-URL aus dem Supabase-Dashboard (Connect)}"
: "${BACKUP_PASSPHRASE:?fehlt}"
out="${1:?Ausgabe-Ordner fehlt}"

if (( ${#BACKUP_PASSPHRASE} < 32 )); then
  echo "BACKUP_PASSPHRASE ist zu kurz (mindestens 32 Zeichen, z. B. openssl rand -base64 48)." >&2
  exit 1
fi

mkdir -p "$out"
stamp=$(date -u +%Y-%m-%dT%H%M%SZ)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

supabase() { npx -y supabase@latest "$@"; }

echo "→ Schema"
supabase db dump --db-url "$SUPABASE_DB_URL" -f "$work/schema.sql"
echo "→ Daten"
# Von Supabase verwaltete Storage-Tabellen ohne Nutzerdaten ausschließen (nicht wiederherstellbar)
supabase db dump --db-url "$SUPABASE_DB_URL" --data-only --use-copy \
  -x storage.buckets_vectors -x storage.vector_indexes -x storage.buckets_analytics \
  -x storage.iceberg_namespaces -x storage.iceberg_tables \
  -f "$work/data.sql"

# Plausibilität: ein Backup ohne Konten-Tabelle ist kaputt
if ! grep -q '^COPY "auth"."users"' "$work/data.sql"; then
  echo "Backup unvollständig: auth.users fehlt" >&2
  exit 1
fi

for part in schema data; do
  gpg --batch --yes --quiet --pinentry-mode loopback --passphrase-fd 3 \
    --symmetric --cipher-algo AES256 --compress-algo zlib \
    -o "$out/lotus-$stamp-$part.sql.gpg" "$work/$part.sql" 3<<<"$BACKUP_PASSPHRASE"
done
ls -l "$out"/lotus-"$stamp"-*
