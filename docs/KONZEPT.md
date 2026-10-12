# Lotus – Konzept für eine faire Dating-App

> Arbeitstitel: **Lotus** (Name kann sich noch ändern). Stand: v0.5 – Beta-Version implementiert – Grundsatzentscheidungen getroffen (siehe Abschnitt 12).
>
> Rahmen: **Hobbyprojekt, kein Team, kein Budget.** Zielgruppe: Singles.

## 1. Vision

Lotus ist eine Dating-App, deren Erfolg daran gemessen wird, **wie viele Menschen sie wieder löschen, weil sie jemanden gefunden haben** – nicht an Bildschirmzeit oder an verkauften Boosts.

### Leitprinzipien

1. **Qualität vor Menge** – wenige, bewusste Entscheidungen statt endlosem Swipen.
2. **Kein Pay-to-Win** – Geld kauft niemals Sichtbarkeit, Likes oder Informationen über andere.
3. **Liken ist folgenlos für dich selbst** – wie viele oder wen du likest, beeinflusst nie deine eigene Sichtbarkeit oder dein Ranking.
4. **Faire Sichtbarkeit** – jedes aktive Profil wird regelmäßig gezeigt; niemand wird von einem Attraktivitäts-Score „versteckt“.
5. **Echte Menschen** – Verifizierung und Bot-Erkennung sind Kernfunktionen, kein Add-on.
6. **Transparenz** – Nutzer:innen können nachlesen, warum ihnen jemand vorgeschlagen wird und wie die Limits funktionieren.

## 2. Abgrenzung zu Tinder / Hinge / Bumble

| Mechanik | Typische Apps | Lotus |
|---|---|---|
| Swipes | unbegrenzt bzw. künstlich begrenzt, um Abos zu verkaufen | fest begrenzt für **alle**, nicht kaufbar |
| „Wer hat mich geliked“ | hinter Paywall | gratis für alle – nach eigener Entscheidung (siehe 4.3) |
| Boosts / Spotlight | kaufbar | existieren nicht |
| Ranking | interner Attraktivitäts-Score (Elo o. ä.) | Kompatibilität + Fairness-Kontingent, kein globaler Desirability-Score |
| Eigenes Like-Verhalten | beeinflusst das eigene Ranking | **kein** Einfluss |
| Erfolgsmetrik | DAU, Verweildauer, Umsatz pro Nutzer | Matches → Gespräche → Dates → „gefunden“-Abmeldungen |

## 3. Kernmechaniken

### 3.1 Profile anschauen, bis die Likes aufgebraucht sind

- Es gibt **keine feste Anzahl Profile pro Tag**: Man bekommt so lange Vorschläge, bis die **20 Likes des Tages verbraucht** sind. Danach ist für heute Schluss (eingehende Likes beantworten geht weiterhin).
- Das Like-Budget ist damit die einzige Grenze – Passen ist kostenlos, aber jedes Like ist eine bewusste Entscheidung.
- Profile werden vollständig angezeigt (Fotos, Prompts, Absichten), nicht nur ein Bild.
- Schutz gegen Dauer-Wegwischen durch Bots: eine großzügige technische Obergrenze für Passes (z. B. 300/Tag). Sie greift nur in der Bot-Erkennung (Trust & Safety) und beeinflusst **nie** das Ranking.
- Gibt es in der Region keine passenden Kandidat:innen mehr, wird das ehrlich angezeigt („Für heute hast du alle passenden Profile gesehen“) statt Profile außerhalb der Präferenzen aufzufüllen.

### 3.2 Like-Budget

- **20 Likes pro Tag** – für alle gleich, nicht kaufbar, nicht verdienbar.
- Nicht genutzte Likes verfallen um Mitternacht (kein Horten).
- Ein Like bezieht sich immer auf **ein konkretes Element** (Foto oder Prompt) und kann einen Kommentar enthalten – erzwingt, dass man sich das Profil anschaut.
- **Zurück-Liken ist gratis:** Ein Like auf eine Person, die einen bereits geliked hat, kostet kein Budget – sonst würden beliebte Profile durch das Limit bestraft.
- Kein Super-Like. Ein Like **mit** Kommentar wird dem Gegenüber hervorgehoben angezeigt – für alle gleich verfügbar.

**Wegwischen rückgängig machen**
- **3× pro Monat** kann ein „Pass“ rückgängig gemacht werden – für alle, auch ohne Abo.
- Kontingent setzt sich am Monatsersten zurück, wird nicht übertragen.
- Nur der jeweils letzte Pass ist rückgängig machbar (verhindert, dass man das Feature als zweiten Stapel missbraucht).

### 3.3 Begrenzte offene Gespräche

- Maximal **6 aktive Chats** gleichzeitig.
- Ist das Limit erreicht, kann man weiter liken, aber neue Matches landen in einer **Warteschlange** und öffnen sich (in Reihenfolge) erst, wenn ein Chat frei wird. Das Gegenüber sieht nur „Match – Chat öffnet sich bald“.
- Ein Match ist erst aktiv, wenn **beide** Seiten einen freien Chat-Platz haben.
- Gespräche ohne Antwort über 7 Tage werden freundlich geschlossen („Gespräch eingeschlafen“) und geben den Platz frei.
- Beenden ist einfach und respektvoll: optional vorformulierte, freundliche Abschiedsnachricht.

### 3.4 Absichten & Kompatibilität

- **Offen für alle Orientierungen** von Anfang an.
- **Geschlecht** (vorerst): männlich, weiblich, divers.
- **„Wen möchtest du kennenlernen?“** – ein oder mehrere Geschlechter. Diese Angabe ist **immer privat**: Sie wird nur für das Matching verwendet und nie im Profil angezeigt (sexuelle Orientierung ist nach DSGVO Art. 9 besonders geschützt).
- **Dating-Ziel** „Was suchst du?“ (feste Beziehung, offen für Beziehung, noch unsicher) – wird immer fürs Matching verwendet; jede Person entscheidet selbst, ob es im Profil **öffentlich oder privat** ist (Standard: öffentlich).
- Andere sehen nur das Alter, nie das Geburtsdatum, und nur eine gerundete Entfernung, nie den Standort.
- Harte Filter wirken **gegenseitig** (Alter, Entfernung, Geschlecht/Interesse, Kinderwunsch optional) – man sieht nur Leute, für die man selbst auch in Frage kommt.
- Prompts / Werte-Fragen als Grundlage für Kompatibilität und Gesprächseinstieg.

### 3.5 Nach dem Match

- Gesprächsstarter auf Basis der Prompts.
- Leichtes „Wollen wir uns treffen?“-Feature (beide müssen zustimmen).
- Nach einem Date: freiwilliges, privates Feedback („Habt ihr euch getroffen? War die Person wie im Profil?“) – dient **nur** Safety & Qualitätsmessung, **nicht** dem Ranking der Person.
- Button „Ich habe jemanden gefunden 🎉“ beim Löschen → wichtigste Produkt-Metrik.

## 4. Ranking, Sichtbarkeit & Fairness

### 4.1 Grundsatz: Like-Verhalten ist vom Ranking entkoppelt

Folgende Signale fließen **nicht** in die eigene Sichtbarkeit ein:

- Anzahl ausgehender Likes / Passes
- Like-Quote („wählerisch“ vs. „likt alles“)
- Wen man likt (Attraktivität der gelikten Personen)

Technisch wird das über eine **Datentrennung** abgesichert: Der Matching-Service hat keinen Zugriff auf aggregierte Like-Statistiken pro Person. Diese liegen nur im Trust-&-Safety-Service (Bot-Erkennung), der dem Matching ausschließlich einen **Status** liefert (siehe 5.3), keinen Score.

### 4.2 Wie Vorschläge entstehen

1. **Kandidaten** – gegenseitige harte Filter, nicht blockiert, nicht kürzlich gesehen, in den letzten X Tagen aktiv, Trust-Status ≥ „normal“.
2. **Kompatibilität** – Absichten, Distanz, Prompt-/Werte-Überschneidung, gemeinsame Interessen.
3. **Fairness-Re-Ranking** – jedes aktive Profil hat ein Mindest- und ein Höchstkontingent an Impressionen pro Tag/Woche:
   - Mindestkontingent: niemand verschwindet.
   - Höchstkontingent: sehr gefragte Profile werden nicht überflutet (besser für sie, und andere bekommen Aufmerksamkeit).
4. **Ausspielung** als fortlaufender Stapel, bis das Like-Budget des Tages verbraucht ist.

### 4.3 „Wer hat mich geliked“

Gratis für alle, aber ehrlich gestaltet: Eingehende Likes erscheinen als eigene Liste; man entscheidet dort ganz normal per Like/Pass. Ein Like zurück auf ein eingehendes Like kostet **kein** Budget (sonst würde das Limit beliebte Profile bestrafen) – zu diskutieren.

### 4.4 Offene Designfrage

Reine Kompatibilität ohne jedes Signal über gegenseitiges Interesse kann zu vielen einseitigen Likes führen. Mögliche Kompromisse:
- Reziprozität **nur** über Inhalte modellieren (ähnliche Absichten, Werte), nie über Beliebtheit.
- Oder: Beliebtheit ausschließlich nutzen, um Überflutung zu begrenzen (Höchstkontingent), nie um jemanden abzuwerten.

## 5. Bot-, Fake- & Scam-Erkennung

Weil Liken keine Konsequenz für das eigene Ranking hat, darf Missbrauch nicht über das Ranking, sondern muss über **Trust & Safety** abgefangen werden. Das Like-Budget selbst ist bereits die erste Verteidigung (ein Bot kann nicht 1.000 Likes/Tag verteilen).

### 5.1 Prävention (beim Onboarding)

- Beta: Anmeldung per **6-stelligem E-Mail-Code** (kostenlos). Später optional Telefonnummer (keine VoIP-/Wegwerfnummern) als zusätzliche Bot-Hürde.
- **Selfie-Verifizierung ist Pflicht vor dem ersten Chat**: Liken und Matchen geht ohne, Nachrichten schreiben erst danach. Verifizierte Profile bekommen ein Badge.
  - Beta (umgesetzt): **Gesten-Selfie** mit zufälliger Geste; ein Admin vergleicht es im Admin-Bereich mit den Profilfotos und bestätigt oder lehnt ab. Später: automatischer Abgleich (Open-Source-Face-Embeddings) oder kommerzieller Liveness-Anbieter.
- Geräte-Attestierung: Google Play Integrity API / Apple App Attest (beide kostenlos) – erkennt Emulatoren, gerootete Geräte, modifizierte Clients.
- Rate-Limits pro Gerät und IP-Bereich bei Registrierungen.
- Bild-Abgleich über Perceptual Hashing gegen bereits gesperrte Accounts.

### 5.2 Laufende Verhaltenssignale

| Bereich | Signale |
|---|---|
| Interaktion | unnatürlich gleichmäßige Zeitabstände, Entscheidungen schneller als Profil-Ladezeit, kein Scrollen durchs Profil, 24/7-Aktivität |
| Nachrichten | Copy-Paste-Texte an viele Matches, frühe Links / Telefonnummern / Messenger-Wechsel, Krypto-/Geld-Schlüsselwörter |
| Netzwerk | Rechenzentrums-ASNs, VPN/Proxy-Häufung, viele Accounts pro Gerät/IP |
| Graph | Cluster neuer Accounts, die dieselben Personen anschreiben |
| Community | Meldungen, Blockierungen kurz nach Match |

### 5.3 Ausgabe: Status statt Score

Trust & Safety liefert pro Account nur einen Status:

- `verified` – Liveness bestanden
- `normal`
- `restricted` – z. B. kein Versand von Links, Shadow-Queue für Moderation, erneute Verifizierung erforderlich
- `suspended` – gesperrt, mit Begründung und Einspruchsmöglichkeit (DSA-konform)

Dieser Status ist ein **Gate** (darf jemand angezeigt werden / schreiben?), kein Ranking-Faktor zwischen echten Nutzer:innen.

### 5.4 Moderation

- Automatische Foto-Moderation (Nacktheit, Minderjährige, Gewalt) + menschliche Review-Queue.
- Meldungen mit Kategorien; schwere Fälle (Scam, Belästigung) priorisiert.
- Warnhinweis im Chat bei Geld-/Krypto-/Link-Anfragen („Die Person hat nach Geld gefragt – Vorsicht“).

## 6. Monetarisierung ohne Cashgrab

Ziel: die Betriebskosten decken, ohne Anreiz, Menschen in der App zu halten.

**Regeln:**
- Niemals kaufbar: Likes, Sichtbarkeit, Boosts, Infos über andere, Vorteile im Matching, Rückgängig-Kontingent.
- Alles, was man zum Finden einer Person braucht, ist für alle gleich und kostenlos.
- Keine Werbung.

**Entschiedenes Modell – drei Säulen:**

1. **Komfort-Abo („Lotus Plus“)** – nur Nicht-Essentielles, z. B.:
   - Standort ändern / Reisemodus (Profile in einer anderen Stadt sehen, z. B. vor Umzug)
   - Erweiterte Profilgestaltung (mehr Prompts, Farbthemen, Profil-Musik)
   - Statistiken nur über sich selbst (z. B. „Welcher Prompt bekommt die meisten Kommentare?“)
   - Chat-Extras (Sprachnachrichten-Länge, Sticker)

   **Wichtig beim Reisemodus:** Wer seinen Standort ändert, erscheint in der Zielstadt **ganz normal** im Fairness-Kontingent – nicht bevorzugt. Und Leute in der Zielstadt sehen, dass die Person aktuell „zu Besuch / zieht bald her“ ist.

2. **Freiwillige Beiträge** – jederzeit, „Pay what you want“, rein als Unterstützung (optional kleines Unterstützer-Badge, das man ausblenden kann).

3. **Beitrag bei Erfolg** – beim Abmelden mit „Ich habe jemanden gefunden 🎉“ eine freundliche, freiwillige Bitte um einen einmaligen Beitrag.

**Hinweis:** In-App-Käufe über App Store / Play Store kosten 15 % Provision (Small Business Program). Freiwillige Beiträge können je nach Store-Regeln ggf. über externe Plattformen laufen (z. B. Ko-fi, GitHub Sponsors) – vor dem Launch prüfen.

## 7. Technische Architektur (Vorschlag)

Rahmen: **eine Person, kein Budget.** Deshalb so wenig eigene Infrastruktur wie möglich, alles mit kostenlosem Einstieg, und kein Lock-in, das später teuer wird.

| Bereich | Vorschlag | Begründung |
|---|---|---|
| Mobile App | **Flutter** | eine Codebasis für iOS + Android, sehr gute UI-Performance, gute Supabase-Integration |
| Backend | **Supabase** (Free Tier, EU-Region) | liefert Postgres, Auth (inkl. Telefon-OTP), Storage, Realtime-Chat und Edge Functions in einem – ein eigener Server entfällt |
| Datenbank | **Postgres + PostGIS** (in Supabase) | Geo-Abfragen; Limits & Regeln direkt per SQL-Funktionen und Row Level Security |
| Logik | Postgres-Funktionen + **Supabase Edge Functions** (TypeScript) | Like-Budget, Vorschläge, Matching serverseitig – nichts davon im Client |
| Chat | **Supabase Realtime** | kein eigener WebSocket-Server nötig |
| Medien | Supabase Storage | Fotos, Thumbnails |
| Push | Firebase Cloud Messaging (kostenlos, auch für iOS) | |
| Jobs | `pg_cron` | eingeschlafene Chats schließen, Warteschlange nachrücken lassen, Fairness-Kontingente zurücksetzen |
| Verifizierung | Gesten-Selfie + Open-Source-Gesichtsabgleich | siehe 5.1 |
| Attestierung | Play Integrity, App Attest | kostenlos |

**Laufende Kosten (geschätzt):**
- Entwicklung & Beta: **0 €** (Supabase Free Tier, Android-Testgeräte), einmalig 25 $ Google-Play-Konto.
- iOS: 99 $/Jahr Apple Developer Program – erst nötig, wenn iOS-Beta startet.
- Ab einigen tausend aktiven Nutzer:innen: Supabase Pro ~25 $/Monat → durch Abo/Beiträge zu decken.
- Telefon-OTP per SMS kostet pro Nachricht (Twilio o. ä.) → für die Beta ggf. E-Mail-Login + Telefon erst vor dem Chat.

Wichtig: Alle Limits (Likes, Rückgängig, Chats) werden **serverseitig** in der Datenbank durchgesetzt, nie nur in der App – sonst sind sie trivial zu umgehen.

### Services (logisch, anfangs als modularer Monolith)

```
┌────────────┐   ┌──────────────┐   ┌──────────────┐
│  Profiles  │   │  Discovery   │   │     Chat     │
│ (Fotos,    │──▶│ (Kandidaten, │   │ (Matches,    │
│  Prompts)  │   │  Fairness)   │   │  Nachrichten)│
└────────────┘   └──────▲───────┘   └──────┬───────┘
                        │ nur Status        │ Events
                 ┌──────┴────────────────────▼──────┐
                 │        Trust & Safety            │
                 │ (Verifizierung, Bot-Erkennung,   │
                 │  Meldungen, Moderation)          │
                 └──────────────────────────────────┘
```

Die Pfeilrichtung ist bewusst: Discovery bekommt von Trust & Safety nur den Status, niemals Like-Statistiken.

### Grobes Datenmodell

- `users` (id, status, created_at, verified_at)
- `profiles` (user_id, name, birthdate, gender, interested_in, intention, bio, location)
- `photos` (id, user_id, url, order, moderation_state)
- `prompts` / `prompt_answers`
- `profile_locations` (user_id, location) – nur selbst lesbar
- `match_preferences` (user_id, interested_in, intention, intention_public, age_min/max, max_distance_km) – nur selbst lesbar
- `likes` (from, to, target_type, target_id, comment, created_at)
- `passes` (from, to, created_at, undone_at)
- `undo_usage` (user_id, month, count) – max. 3 pro Monat
- `subscriptions` (user_id, plan, valid_until) – nur Komfort-Features
- `contributions` (user_id, amount, kind: voluntary | success, created_at)
- `matches` (id, user_a, user_b, state: queued | active | closed, created_at, closed_at) – max. 6 `active` pro Person
- `messages` (id, match_id, sender, body, created_at)
- `reports`, `blocks`
- `trust_events` (user_id, signal, value, created_at) – nur für Trust & Safety lesbar
- `impressions` (viewer, shown, date) – für Fairness-Kontingente

## 8. Recht & Datenschutz (EU / DE)

- **DSGVO Art. 9**: sexuelle Orientierung und ggf. Gesundheit/Religion sind besondere Kategorien → ausdrückliche Einwilligung, Datenschutz-Folgenabschätzung (DSFA), Datenminimierung.
- Hosting in der EU, Verschlüsselung at rest & in transit, Löschkonzept (Account-Löschung = echte Löschung).
- **Digital Services Act**: Meldewege, Begründung von Sperren, Beschwerdeverfahren, Transparenz über Empfehlungssysteme (passt zu Prinzip 6).
- Mindestalter 18, Altersprüfung.
- Biometrische Daten (Liveness) → nur zur Verifizierung, kurze Speicherdauer.
- App-Store-Richtlinien für Dating-Apps (Meldefunktion, Blockieren, Moderation sind Pflicht).

## 9. Metriken

**Nordstern:** Anteil der Abmeldungen mit „Ich habe jemanden gefunden“.

Weitere:
- Match → Gespräch (≥ 1 Antwort) Quote
- Gespräch → Date Quote
- Antwortrate / Ghosting-Rate
- Gleichverteilung der Impressionen (Gini-Koeffizient)
- Fake-/Scam-Meldungen pro 1.000 aktive Nutzer:innen
- **Bewusst nicht** optimiert: Verweildauer, Sessions pro Tag

## 10. Roadmap

Angepasst an ein Hobbyprojekt: kleine, abgeschlossene Schritte, jeder für sich nutzbar.

### ✅ Schritte 1–3 – Fundament, Kern-Loop, Chat & Sicherheit (umgesetzt)
- Datenbank mit allen Regeln serverseitig (`supabase/migrations`, 104 Tests), lokal gegen echtes Supabase geprüft
- Flutter-App: E-Mail-Code-Login, Onboarding (5 Schritte), Entdecken bis Like-Budget leer, Like auf Foto/Prompt mit Kommentar, Weiter, Rückgängig (3/Monat), „Wer dich mag“ mit gratis Zurück-Liken, Matches mit 6 Plätzen + Warteschlange, Realtime-Chat mit Sicherheitshinweisen, Gespräch beenden mit Abschiedsnachricht, Blockieren, Melden, Gesten-Selfie-Verifizierung, Konto löschen mit „Ich habe jemanden gefunden“
- Admin-Bereich: Selfies prüfen, Fotos moderieren (sichtbar bis abgelehnt), Meldungen bearbeiten, Konten einschränken/sperren
- Regelbasierte Bot-Erkennung: Like-Budget, Likes nur auf vorgeschlagene Profile, Pass-Obergrenze, Spam-Erkennung (gleiche Nachricht an viele Matches), Link-Sperre für eingeschränkte Konten
- Push-Benachrichtigungen (Edge Function + FCM, optional zuschaltbar)

### Schritt 4 – Closed Beta (als Nächstes)
- Organisatorisches aus Abschnitt 12 „Noch offen“ erledigen (Konten, Rechtliches)
- Android-Beta über den internen Test der Play Console, Freundeskreis + Bekannte in **Stuttgart und Ulm**
- Kaltstart: gezielt einladen, auf ausgewogene Gruppen achten
- Limits anhand echter Nutzung justieren

### Schritt 5 – Ausbau
- iOS, Lotus Plus (Reisemodus etc.), freiwillige Beiträge & Beitrag bei Erfolg (Zahlungsabwicklung)
- Geräte-Attestierung (Play Integrity / App Attest), automatischer Selfie-Abgleich
- Transparenz-Seite „Warum sehe ich diese Person?“
- Englische Übersetzung

## 11. Risiken

| Risiko | Gegenmaßnahme |
|---|---|
| Kaltstart / zu wenige Profile | Start in Stuttgart + Ulm, Warteliste, Community-Events, gezielte Einladungen für kleinere Gruppen (z. B. Frauen, die Frauen suchen) |
| Limits frustrieren Nutzer:innen | Limits erklären, mit Daten justieren, Fokus als Feature vermarkten |
| Ungleiches Geschlechterverhältnis | Fairness-Kontingente, Freischaltung nach Balance pro Region |
| Finanzierung | Free-Tier-Stack, Kosten erst ab Wachstum, Komfort-Abo + Beiträge |
| Zeit (eine Person) | kleine Schritte, Supabase statt eigenem Backend, Scope strikt halten |
| Romance-Scams | Verifizierung, Scam-Warnungen im Chat, schnelle Moderation |

## 12. Offene Entscheidungen

### Entschieden

| # | Thema | Entscheidung |
|---|---|---|
| 1 | Monetarisierung | Komfort-Abo (nur Nicht-Essentielles, z. B. Standort ändern) + freiwillige Beiträge + Beitrag bei Erfolg |
| 2 | Limits | 20 Likes/Tag · Pass 3×/Monat rückgängig · max. 6 aktive Chats |
| 3 | Zurück-Liken | kostet kein Budget |
| 4 | Verifizierung | Pflicht vor dem ersten Chat |
| 5 | Zielgruppe / Rahmen | Singles · Hobbyprojekt, kein Team, kein Budget |
| 6 | Profile pro Tag | unbegrenzt, bis die 20 Likes aufgebraucht sind |
| 7 | Chat-Limit erreicht | neue Matches kommen in eine Warteschlange |
| 8 | Tech-Stack | Flutter + Supabase |
| 9 | Beta-Region | Stuttgart **und** Ulm |
| 10 | Orientierungen | alle von Anfang an |
| 11 | Geschlecht | vorerst männlich, weiblich, divers |
| 12 | Orientierung im Profil | privat, nur fürs Matching |
| 13 | Dating-Ziel im Profil | fürs Matching immer genutzt, Anzeige optional privat |
| 14 | Name | „Lotus“ ist Arbeitstitel |

| 15 | Sprache | vorerst nur Deutsch (Texte in Übersetzungsdatei, Englisch später möglich) |
| 16 | Login | 6-stelliger Code per E-Mail |
| 17 | Moderation (Beta) | Fotos sofort sichtbar, Admin kann ablehnen; Selfies prüft der Admin manuell |
| 18 | Design | ruhig & warm: Rosé, Salbeigrün, Creme, weiche Rundungen |

### Noch offen

**Produkt**
1. Ulm ↔ Stuttgart liegen ~90 km auseinander: Standard-Suchradius 50 km lassen (zwei getrennte Pools) oder größer wählen?
2. Weitere optionale Matching-Kriterien (z. B. Kinderwunsch, Rauchen) – und wenn ja, ebenfalls privat?
3. Endgültiger Name und App-ID (`app.lotusdating.lotus` ist nach dem ersten Play-Store-Upload nicht mehr änderbar).

**Organisatorisch (vor dem ersten fremden Nutzer)**
4. Konten: Supabase (EU), Google-Play-Entwicklerkonto (25 $), optional Firebase (Push), SMTP-Versand für E-Mails.
5. Rechtliches: Impressum, Datenschutzerklärung (Art. 9 DSGVO), Nutzungsbedingungen, DSFA, AV-Verträge.
6. Wer moderiert außer dir (Urlaub, Krankheit)? Meldungen zu Scam/Minderjährigen sollten innerhalb eines Tages bearbeitet werden.
