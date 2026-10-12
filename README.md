# Lotus

Eine Dating-App, die darauf ausgelegt ist, dass Menschen wirklich jemanden finden – kein Cashgrab.

- **Konzept & Entscheidungen:** [`docs/KONZEPT.md`](docs/KONZEPT.md)
- **Stack:** Flutter (App) + Supabase (Postgres/PostGIS, Auth, Storage, Realtime)

## Regeln, die die Datenbank durchsetzt

| Regel | Wert |
|---|---|
| Likes pro Tag | 20 (Reset um Mitternacht, Europe/Berlin) – Vorschläge gibt es, bis sie aufgebraucht sind |
| Zurück-Liken | kostet kein Budget |
| Wegwischen rückgängig | 3× pro Monat, nur die letzte Entscheidung |
| Aktive Chats | max. 6, weitere Matches warten in einer Warteschlange |
| Chatten | erst nach Selfie-Verifizierung |
| Eingeschlafene Chats | werden nach 7 Tagen ohne Nachricht geschlossen |

Das eigene Like-Verhalten beeinflusst **nie** die eigene Sichtbarkeit. Vorschläge werden nach
gegenseitigen Filtern, gleicher Absicht und einem Fairness-Kontingent (seltener Gezeigte zuerst) sortiert.

## Struktur

```
docs/KONZEPT.md                    Produktkonzept
supabase/migrations/               Schema, Logik (RPC-Funktionen), Rechte & RLS
supabase/tests/local/              Datenbank-Tests (laufen auf normalem Postgres)
scripts/test-db.sh                 Migrationen einspielen + Tests ausführen
```

## Datenbank-API (für die App)

| Funktion | Zweck |
|---|---|
| `get_candidates(p_limit)` | nächste Vorschläge (leer, wenn das Like-Budget aufgebraucht ist) |
| `like_profile(p_to, p_target_type, p_target_id, p_comment)` | Like auf Foto/Prompt; gibt die Match-ID zurück, falls es ein Match ist |
| `pass_profile(p_to)` | wegwischen |
| `undo_last_pass()` | letztes Wegwischen rückgängig machen |
| `get_incoming_likes()` | „Wer hat mich geliked“ |
| `likes_remaining_today()` / `undos_remaining_this_month()` | Restbudgets |
| `close_match(p_match, p_goodbye)` | Gespräch beenden, optional mit Abschiedsnachricht |

Fehler kommen als stabile Schlüssel (`daily_like_limit_reached`, `monthly_undo_limit_reached`,
`profile_not_available`, …), die die App übersetzt.

## Tests ausführen

Benötigt Postgres 15+ mit PostGIS:

```bash
PGHOST=localhost PGPORT=5432 PGUSER=postgres scripts/test-db.sh
```

## Auf Supabase einspielen

```bash
supabase init          # erzeugt supabase/config.toml
supabase link --project-ref <ref>
supabase db push
```

Projekt in der EU-Region anlegen. `pg_cron` im Dashboard aktivieren, damit eingeschlafene Chats automatisch geschlossen werden.
