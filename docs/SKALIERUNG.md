# Skalierung

## Messung: Vorschläge (`get_candidates`)

Lasttest mit `scripts/bench-db.sh <profile>`: Profile über Deutschland verteilt, ein Viertel im Raum Stuttgart,
30 Tage Impressionen. Gemessen wird eine Person in Stuttgart mit 50 km Radius (Postgres 16 + PostGIS, 4 Kerne).

| Profile gesamt (davon Raum Stuttgart) | vorher | nach Index-Vorauswahl & Altersgrenzen | mit Such-Tabelle (aktuell) |
|---|---|---|---|
| 10.000 (2.500) | 266 ms | 266 ms | **15 ms** |
| 50.000 (12.500) | 2.000 ms | 193 ms | **92 ms** |
| 200.000 (50.000) | – | 1.170 ms | **siehe unten** |

Zum Vergleich: Für die Beta in Stuttgart und Ulm sind ein paar hundert bis wenige tausend Profile realistisch.

## Was umgesetzt ist

1. **Such-Tabelle `private.discovery`.** Eine Zeile pro Person mit allen Filterkriterien (Geschlecht, Alter,
   Präferenzen, Kinderwunsch/Rauchen, Aktivität, auffindbar ja/nein) und dem aktuellen Suchstandort.
   Trigger auf allen Quelltabellen halten sie aktuell. Ein Cron-Job setzt abgelaufene Reisen alle 10 Minuten
   zurück. Die Vorschläge lesen so **eine** Tabelle über einen räumlichen Index, der nur auffindbare Profile
   enthält, statt fünf Tabellen pro Kandidat zu verknüpfen.
2. **Räumlicher Index wird wirklich genutzt.** Suchstandort und Radius werden vorab als Konstanten berechnet.
3. **Altersfilter als Datumsvergleich.** Die Altersspanne wird einmal in Geburtsdaten umgerechnet, statt für
   jede Person das Alter zu berechnen.
4. **Fairness-Zähler pro Tag (`private.daily_impressions`).** Höchstens 7 Zeilen pro Kandidat statt aller
   Einzel-Impressionen. Gepflegt per Trigger, nach 8 Tagen aufgeräumt.
5. **Anzeigedaten nur für die 10 ausgewählten Profile** (Name, Bio, Reisestatus, Alter).
6. **Kleine Hilfsfunktionen sind einbettbar.** Ohne `security definer` und ohne festen `search_path` kann
   Postgres sie in die Abfrage übernehmen, statt sie pro Zeile aufzurufen.
7. **CI-Lasttest.** Bei jedem Push werden die Vorschläge mit 10.000 Profilen gemessen. Über 250 ms schlägt
   die CI fehl.

## Wann der nächste Schritt nötig wird

Die Kosten wachsen mit der Zahl der Profile **im Suchradius**, nicht mit der Gesamtzahl. Erst wenn in einer
Stadt deutlich mehr als 10.000 aktive Profile im Radius liegen, lohnt sich Folgendes (in dieser Reihenfolge):

1. **Kandidaten vorberechnen:** nachts pro Person eine Liste der passenden Profile anlegen und tagsüber nur
   noch Fairness und bereits Entschiedene filtern.
2. **Impressionen partitionieren** (nach Monat), damit Aufräumen und Indizes klein bleiben.
3. **Chat über Realtime-Broadcast** statt über Datenbank-Änderungen (Postgres Changes prüfen RLS pro
   Empfänger und werden bei vielen gleichzeitigen Chats teuer).
4. **Supabase-Tarif:** Free Tier bis etwa 500 MB Datenbank und 1 GB Dateien. Fotos sind der größte Posten,
   deshalb verkleinert die App sie schon beim Hochladen auf max. 1600 px.

## Selbst messen

```bash
PGHOST=localhost PGUSER=postgres scripts/bench-db.sh 50000        # Messung
PGHOST=localhost PGUSER=postgres scripts/bench-db.sh 10000 250    # wie in der CI, mit Grenze
```
