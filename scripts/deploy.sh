#!/usr/bin/env bash
# Spielt Lotus in das Supabase-Projekt ein (siehe docs/EINRICHTUNG.md).
#
# Läuft nur über die Supabase-Management-API (api.supabase.com) – kein DB-Passwort, keine Supabase-CLI.
# Der Access Token kommt entweder als Network Secret vom Proxy der Cloud-Umgebung (dann nichts setzen)
# oder lokal aus SUPABASE_ACCESS_TOKEN. Der Projekt-Ref steht in config/public.env.
#
# FIREBASE_SERVICE_ACCOUNT, GOOGLE_PLAY_SERVICE_ACCOUNT und SMTP liegen direkt in Supabase und werden
# hier nicht gesetzt.
#
#   scripts/deploy.sh                          # alles einspielen
#   scripts/deploy.sh --admin du@example.de    # zusätzlich dieses Konto zum Admin machen
#   scripts/deploy.sh --with-purchases         # zusätzlich verify-purchase deployen (braucht Play-Secret)
set -euo pipefail

cd "$(dirname "$0")/.."
# shellcheck source=/dev/null
source config/public.env
: "${SUPABASE_PROJECT_REF:?fehlt in config/public.env}"

admin_email=""
with_purchases=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --admin) admin_email="${2:?E-Mail-Adresse fehlt}"; shift 2 ;;
    --with-purchases) with_purchases=true; shift ;;
    *) echo "Unbekannte Option: $1" >&2; exit 1 ;;
  esac
done

api_base="https://api.supabase.com/v1/projects/${SUPABASE_PROJECT_REF}"
auth=()
if [[ -n "${SUPABASE_ACCESS_TOKEN:-}" ]]; then auth=(-H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}"); fi

# api METHODE PFAD [curl-Argumente …] – gibt bei Fehlern Status und Antwort aus
api() {
  local method="$1" path="$2"; shift 2
  local out status
  out=$(mktemp)
  status=$(curl -sS -o "$out" -w '%{http_code}' -X "$method" "${api_base}${path}" "${auth[@]}" "$@")
  if [[ "$status" != 2* ]]; then
    echo "  ! $method $path → HTTP $status: $(head -c 500 "$out")" >&2
    rm -f "$out"; return 1
  fi
  cat "$out"; rm -f "$out"
}

# SQL ausführen; gibt den ersten Wert der ersten Zeile aus (oder nichts).
sql() {
  api POST /database/query -H "Content-Type: application/json" \
    -d "$(python3 -c 'import json,sys; print(json.dumps({"query": sys.argv[1]}))' "$1")" |
    python3 -c 'import json,sys; rows=json.load(sys.stdin); print(next(iter(rows[0].values())) if rows and rows[0] else "")'
}

echo "→ Zugang prüfen"
api GET "" > /dev/null || { echo "Kein Zugriff auf Projekt $SUPABASE_PROJECT_REF – Token prüfen (docs/EINRICHTUNG.md)" >&2; exit 1; }

echo "→ Datenbank-Migrationen"
# Dieselbe Versionstabelle wie die Supabase-CLI, damit `supabase migration list` weiter stimmt.
sql "create schema if not exists supabase_migrations;
     create table if not exists supabase_migrations.schema_migrations
       (version text primary key, statements text[], name text)" > /dev/null
for migration in supabase/migrations/*.sql; do
  file=$(basename "$migration" .sql)
  version=${file%%_*}
  name=${file#*_}
  if [[ -n "$(sql "select 1 from supabase_migrations.schema_migrations where version = '$version'")" ]]; then
    echo "  = $file"
    continue
  fi
  echo "  + $file"
  # Migration und Versionseintrag in einer Transaktion
  sql "begin;
       $(cat "$migration")
       ;
       insert into supabase_migrations.schema_migrations (version, name) values ('$version', '$name');
       commit;" > /dev/null
done

echo "→ Auth-Einstellungen (Anmeldung per Code)"
api PATCH /config/auth -H "Content-Type: application/json" -d "$(python3 -c 'import json,sys
template = open("supabase/templates/login_code.html").read()
print(json.dumps({
  "mailer_subjects_magic_link": "Dein Lotus-Code", "mailer_templates_magic_link_content": template,
  "mailer_subjects_confirmation": "Dein Lotus-Code", "mailer_templates_confirmation_content": template,
  "mailer_otp_length": 6, "mailer_otp_exp": 3600, "mailer_autoconfirm": True,
  "disable_signup": False, "external_anonymous_users_enabled": False}))')" > /dev/null

echo "→ Push-Benachrichtigungen"
secret_names=$(api GET /secrets | python3 -c 'import json,sys; print(" ".join(s["name"] for s in json.load(sys.stdin)))')
if [[ " $secret_names " != *" FIREBASE_SERVICE_ACCOUNT "* ]]; then
  echo "  ! FIREBASE_SERVICE_ACCOUNT fehlt in Supabase (Edge Functions → Secrets) – Push funktioniert erst danach"
fi
# Bestehendes Secret weiterverwenden, sonst neues erzeugen
notify_secret=$(sql "select value from private.settings where key = 'notify_secret'" || true)
notify_secret=${notify_secret:-$(openssl rand -hex 32)}
api POST /secrets -H "Content-Type: application/json" \
  -d "[{\"name\": \"NOTIFY_WEBHOOK_SECRET\", \"value\": \"${notify_secret}\"}]" > /dev/null

# deploy_function NAME VERIFY_JWT – lädt die Function samt _shared hoch
deploy_function() {
  local name="$1" verify_jwt="$2" files=()
  for f in supabase/functions/"$name"/*.ts supabase/functions/_shared/*.ts; do
    files+=(-F "file=@${f};filename=${f#supabase/functions/}")
  done
  api POST "/functions/deploy?slug=${name}" \
    -F "metadata={\"name\": \"${name}\", \"entrypoint_path\": \"${name}/index.ts\", \"verify_jwt\": ${verify_jwt}};type=application/json" \
    "${files[@]}" > /dev/null
}
deploy_function notify false
sql "insert into private.settings (key, value) values
       ('notify_url', 'https://${SUPABASE_PROJECT_REF}.supabase.co/functions/v1/notify'),
       ('notify_secret', '${notify_secret}')
     on conflict (key) do update set value = excluded.value" > /dev/null

if $with_purchases; then
  echo "→ Kaufprüfung (Lotus Plus & Spenden)"
  if [[ " $secret_names " != *" GOOGLE_PLAY_SERVICE_ACCOUNT "* ]]; then
    echo "  ! GOOGLE_PLAY_SERVICE_ACCOUNT fehlt in Supabase (Edge Functions → Secrets)"
  fi
  api POST /secrets -H "Content-Type: application/json" \
    -d '[{"name": "ANDROID_PACKAGE_NAME", "value": "app.lotusdating.lotus"}]' > /dev/null
  deploy_function verify-purchase true
fi

if [[ -n "$admin_email" ]]; then
  # Nur einfache Adressen zulassen – sie landen in einer SQL-Abfrage
  if [[ ! "$admin_email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+$ ]]; then
    echo "Ungültige E-Mail-Adresse: $admin_email" >&2
    exit 1
  fi
  echo "→ Admin: $admin_email"
  sql "insert into private.admins (user_id)
       select id from auth.users where lower(email) = lower('$admin_email')
       on conflict do nothing" > /dev/null
fi

publishable_key=$(api GET "/api-keys?reveal=false" |
  python3 -c 'import json,sys; keys=json.load(sys.stdin); print(next((k["api_key"] for k in keys if k.get("type")=="publishable"), "<Publishable Key aus dem Dashboard>"))')

echo "✓ Fertig. App bauen mit:"
echo "  cd app && flutter build appbundle --dart-define=SUPABASE_URL=https://${SUPABASE_PROJECT_REF}.supabase.co --dart-define=SUPABASE_KEY=${publishable_key}"
