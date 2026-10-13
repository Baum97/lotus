#!/usr/bin/env bash
# Lasttest für die Vorschläge: frische Datenbank mit vielen Profilen, dann get_candidates messen.
#   PGHOST=… PGUSER=postgres scripts/bench-db.sh [anzahl_profile] [grenze_ms]
# Standard: 50000 Profile, keine Grenze. Mit Grenze scheitert das Skript, wenn der schnellste
# von drei Aufrufen langsamer ist (für die CI).
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
db=lotus_bench
users="${1:-50000}"
limit_ms="${2:-}"
psql_db=(psql -X -q -v ON_ERROR_STOP=1 -d "$db")

psql -X -q -d postgres -c "drop database if exists $db" -c "create database $db"
psql -X -q -d postgres -c "drop role if exists anon, authenticated, service_role" 2>/dev/null || true
"${psql_db[@]}" -f "$root/supabase/tests/local/00_supabase_stub.sql"
for migration in "$root"/supabase/migrations/*.sql; do "${psql_db[@]}" -f "$migration"; done
echo "→ $users Profile anlegen …"
"${psql_db[@]}" -v users="$users" -f "$root/supabase/tests/bench/seed_bench.sql"
echo "→ Messung (3 Aufrufe von get_candidates)"
output=$(psql -X -v ON_ERROR_STOP=1 -d "$db" -f "$root/supabase/tests/bench/bench_candidates.sql" 2>&1)
echo "$output" | grep -E "^Time:|ERROR"
best=$(echo "$output" | sed -n 's/^Time: \([0-9.]*\) ms.*/\1/p' | sort -n | head -1)
if [[ -z "$best" ]]; then
  echo "Keine Messung – siehe Ausgabe oben" >&2
  exit 1
fi
echo "Schnellster Aufruf: ${best} ms"
if [[ -n "$limit_ms" ]] && awk -v b="$best" -v l="$limit_ms" 'BEGIN { exit !(b > l) }'; then
  echo "Zu langsam: ${best} ms > ${limit_ms} ms" >&2
  exit 1
fi
