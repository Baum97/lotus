#!/usr/bin/env bash
# Spielt Lotus in das Supabase-Projekt ein (siehe docs/EINRICHTUNG.md).
#
# Erwartet als Umgebungsvariablen (nie in Dateien im Repo!):
#   SUPABASE_ACCESS_TOKEN, SUPABASE_PROJECT_REF, SUPABASE_DB_PASSWORD
# Optional:
#   FIREBASE_SERVICE_ACCOUNT        → Push-Benachrichtigungen
#   GOOGLE_PLAY_SERVICE_ACCOUNT     → Kaufprüfung für Plus & Spenden
#   SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_SENDER → eigener E-Mail-Versand
#
#   scripts/deploy.sh                       # alles einspielen
#   scripts/deploy.sh --admin du@example.de # zusätzlich dieses Konto zum Admin machen
set -euo pipefail

cd "$(dirname "$0")/.."
: "${SUPABASE_ACCESS_TOKEN:?fehlt – siehe docs/EINRICHTUNG.md}"
: "${SUPABASE_PROJECT_REF:?fehlt – siehe docs/EINRICHTUNG.md}"
: "${SUPABASE_DB_PASSWORD:?fehlt – siehe docs/EINRICHTUNG.md}"

admin_email=""
if [[ "${1:-}" == "--admin" ]]; then admin_email="${2:?E-Mail-Adresse fehlt}"; fi

supabase() { npx -y supabase@latest "$@"; }

# SQL über die Supabase-Management-API; gibt den ersten Wert der ersten Zeile aus (oder nichts).
sql() {
  curl -sSf -X POST "https://api.supabase.com/v1/projects/${SUPABASE_PROJECT_REF}/database/query" \
    -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" -H "Content-Type: application/json" \
    -d "$(python3 -c 'import json,sys; print(json.dumps({"query": sys.argv[1]}))' "$1")" |
    python3 -c 'import json,sys; rows=json.load(sys.stdin); print(next(iter(rows[0].values())) if rows and rows[0] else "")'
}

echo "→ Projekt verknüpfen"
supabase link --project-ref "$SUPABASE_PROJECT_REF" --password "$SUPABASE_DB_PASSWORD"

echo "→ Datenbank-Migrationen"
supabase db push --password "$SUPABASE_DB_PASSWORD"

echo "→ Auth-Einstellungen (E-Mail-Vorlage)"
supabase config push --project-ref "$SUPABASE_PROJECT_REF" <<< "y" || \
  echo "  ! config push fehlgeschlagen – Vorlage supabase/templates/login_code.html bitte im Dashboard eintragen"

if [[ -n "${SMTP_HOST:-}" ]]; then
  echo "→ SMTP für Anmeldecodes"
  curl -sSf -X PATCH "https://api.supabase.com/v1/projects/${SUPABASE_PROJECT_REF}/config/auth" \
    -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" -H "Content-Type: application/json" \
    -d "$(python3 -c 'import json,os; print(json.dumps({
      "smtp_host": os.environ["SMTP_HOST"], "smtp_port": os.environ.get("SMTP_PORT", "587"),
      "smtp_user": os.environ["SMTP_USER"], "smtp_pass": os.environ["SMTP_PASS"],
      "smtp_admin_email": os.environ["SMTP_SENDER"], "smtp_sender_name": "Lotus",
      "rate_limit_email_sent": 100}))')" > /dev/null
fi

notify_secret=""
if [[ -n "${FIREBASE_SERVICE_ACCOUNT:-}" ]]; then
  echo "→ Push-Benachrichtigungen"
  # Bestehendes Secret weiterverwenden, sonst neues erzeugen
  notify_secret=$(sql "select value from private.settings where key = 'notify_secret'" || true)
  notify_secret=${notify_secret:-$(openssl rand -hex 32)}
  supabase secrets set --project-ref "$SUPABASE_PROJECT_REF" \
    FIREBASE_SERVICE_ACCOUNT="$FIREBASE_SERVICE_ACCOUNT" NOTIFY_WEBHOOK_SECRET="$notify_secret"
  supabase functions deploy notify --project-ref "$SUPABASE_PROJECT_REF" --no-verify-jwt
  sql "insert into private.settings (key, value) values
         ('notify_url', 'https://${SUPABASE_PROJECT_REF}.supabase.co/functions/v1/notify'),
         ('notify_secret', '${notify_secret}')
       on conflict (key) do update set value = excluded.value"
fi

if [[ -n "${GOOGLE_PLAY_SERVICE_ACCOUNT:-}" ]]; then
  echo "→ Kaufprüfung (Lotus Plus & Spenden)"
  supabase secrets set --project-ref "$SUPABASE_PROJECT_REF" \
    GOOGLE_PLAY_SERVICE_ACCOUNT="$GOOGLE_PLAY_SERVICE_ACCOUNT" ANDROID_PACKAGE_NAME=app.lotusdating.lotus
  supabase functions deploy verify-purchase --project-ref "$SUPABASE_PROJECT_REF"
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
       on conflict do nothing"
fi

echo "✓ Fertig. App bauen mit:"
echo "  cd app && flutter build appbundle --dart-define=SUPABASE_URL=https://${SUPABASE_PROJECT_REF}.supabase.co --dart-define=SUPABASE_KEY=<Publishable Key>"
