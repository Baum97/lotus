#!/usr/bin/env bash
# Spielt alle Migrationen in eine frische Datenbank ein und führt die Datenbank-Tests aus.
# Benötigt Postgres 15+ mit PostGIS. Verbindung über die üblichen PG*-Variablen (PGHOST, PGPORT, PGUSER).
#
#   PGHOST=localhost PGPORT=5432 PGUSER=postgres scripts/test-db.sh
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
db="${LOTUS_TEST_DB:-lotus_test}"
psql_db=(psql -X -q -v ON_ERROR_STOP=1 -d "$db")

psql -X -q -d postgres -c "drop database if exists $db" -c "create database $db"
# Rollen sind clusterweit; bei wiederholten Läufen existieren sie schon.
psql -X -q -d postgres -c "drop role if exists anon, authenticated, service_role" 2>/dev/null || true

"${psql_db[@]}" -f "$root/supabase/tests/local/00_supabase_stub.sql"
for migration in "$root"/supabase/migrations/*.sql; do
  echo "→ $(basename "$migration")"
  "${psql_db[@]}" -f "$migration"
done

echo "→ Tests"
"${psql_db[@]}" -f "$root/supabase/tests/local/lotus_test.sql"
echo "✓ Alle Datenbank-Tests bestanden"
