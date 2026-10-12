# Lotus – Konzept für eine faire Dating-App

> Arbeitstitel: **Lotus**. Stand: Entwurf v0.1 – Grundlage für die gemeinsame Planung.

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

### 3.1 Tägliche Auswahl statt Endlos-Stack

- Jede Person bekommt pro Tag eine **kuratierte Auswahl** (Startwert: ~20 Profile).
- Ist die Auswahl durch, ist sie durch – kein „Mehr laden“.
- Profile werden vollständig angezeigt (Fotos, Prompts, Absichten), nicht nur ein Bild.

### 3.2 Like-Budget

- **Startwert: 8 Likes pro Tag**, nicht kaufbar, nicht verdienbar.
- Optional: nicht genutzte Likes verfallen (verhindert Horten und Massen-Likes am Wochenende).
- Ein Like bezieht sich immer auf **ein konkretes Element** (Foto oder Prompt) und kann einen Kommentar enthalten – erzwingt, dass man sich das Profil anschaut.
- „Pass“ kostet nichts, ist aber durch die Tagesauswahl ohnehin begrenzt.
- Kein Super-Like. Stattdessen: Ein Like **mit** Kommentar wird dem Gegenüber hervorgehoben angezeigt – für alle gleich verfügbar.

### 3.3 Begrenzte offene Gespräche

- Maximal **5 aktive Chats** gleichzeitig (Wert zu testen).
- Ist das Limit erreicht, gibt es keine neuen Vorschläge, bis man ein Gespräch beendet – fördert Fokus statt Sammeln.
- Gespräche ohne Antwort über 5–7 Tage werden freundlich geschlossen („Gespräch eingeschlafen“), statt ewig zu ghosten.
- Beenden ist einfach und respektvoll: optional vorformulierte, freundliche Abschiedsnachricht.

### 3.4 Absichten & Kompatibilität

- Pflichtfeld „Was suchst du?“ (feste Beziehung, offen für Beziehung, noch unsicher …).
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
4. **Ausspielung** als Tagesauswahl.

### 4.3 „Wer hat mich geliked“

Gratis für alle, aber ehrlich gestaltet: Eingehende Likes erscheinen als eigene Liste; man entscheidet dort ganz normal per Like/Pass. Ein Like zurück auf ein eingehendes Like kostet **kein** Budget (sonst würde das Limit beliebte Profile bestrafen) – zu diskutieren.

### 4.4 Offene Designfrage

Reine Kompatibilität ohne jedes Signal über gegenseitiges Interesse kann zu vielen einseitigen Likes führen. Mögliche Kompromisse:
- Reziprozität **nur** über Inhalte modellieren (ähnliche Absichten, Werte), nie über Beliebtheit.
- Oder: Beliebtheit ausschließlich nutzen, um Überflutung zu begrenzen (Höchstkontingent), nie um jemanden abzuwerten.

## 5. Bot-, Fake- & Scam-Erkennung

Weil Liken keine Konsequenz für das eigene Ranking hat, darf Missbrauch nicht über das Ranking, sondern muss über **Trust & Safety** abgefangen werden. Das Like-Budget selbst ist bereits die erste Verteidigung (ein Bot kann nicht 1.000 Likes/Tag verteilen).

### 5.1 Prävention (beim Onboarding)

- Telefonnummer-Verifizierung (keine VoIP-/Wegwerfnummern).
- **Selfie-Liveness-Check**, abgeglichen mit den Profilfotos → Verifiziert-Badge; Pflicht vor dem ersten Chat (Diskussionspunkt: Pflicht vor dem ersten Like?).
- Geräte-Attestierung: Google Play Integrity API / Apple App Attest – erkennt Emulatoren, gerootete Geräte, modifizierte Clients.
- Rate-Limits pro Gerät, IP-Bereich und Zahlungsmittel bei Registrierungen.
- Bild-Abgleich gegen bekannte Stock-/gestohlene Fotos (Reverse Image / Perceptual Hashing).

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

Ziel: kostendeckend und nachhaltig, ohne Anreiz, Menschen in der App zu halten.

**Regeln:**
- Niemals kaufbar: Likes, Sichtbarkeit, Boosts, Infos über andere, Vorteile im Matching.
- Alle Kernfunktionen sind für alle gleich.

**Mögliche Modelle (zu entscheiden):**

| Modell | Pro | Contra |
|---|---|---|
| A) Kleines Pauschal-Abo für alle (z. B. 4–6 €/Monat), erste Wochen gratis | gleiche Bedingungen, hält Bots/Fakes fern, planbare Einnahmen | Einstiegshürde, Kaltstart schwerer |
| B) Kostenlos + freiwillige Unterstützer-Mitgliedschaft (rein kosmetisch / Dank) | niedrigste Hürde | unsichere Einnahmen |
| C) Bezahlung bei Erfolg (einmaliger „Wir haben uns gefunden“-Beitrag, freiwillig) | Anreiz exakt auf Ziel ausgerichtet | kaum planbar |
| D) Genossenschaft / gemeinnützige Struktur | Glaubwürdigkeit, kein Wachstumsdruck durch Investoren | Finanzierung des Starts |

**Empfehlung:** Kombination A + C – kurzer Gratis-Zeitraum, danach ein günstiges Pauschal-Abo mit Sozialtarif; beim „gefunden“-Abmelden optionaler Beitrag. Keine Werbung.

## 7. Technische Architektur (Vorschlag)

| Bereich | Vorschlag | Begründung |
|---|---|---|
| Mobile App | **Flutter** oder **React Native (Expo)** | eine Codebasis für iOS + Android |
| Backend | **TypeScript (NestJS)** oder **Go** | schnelle Entwicklung, gute Typisierung |
| Datenbank | **PostgreSQL + PostGIS** | relationale Daten + Geo-Abfragen |
| Cache / Limits | **Redis** | Like-Budget, Rate-Limits, Tagesauswahl |
| Chat | WebSockets (eigener Service) | keine Abhängigkeit von Drittanbietern bei sensiblen Daten |
| Medien | S3-kompatibler Storage (EU-Region) + CDN | Fotos, Thumbnails |
| Push | FCM / APNs | |
| Verifizierung | Liveness-Anbieter (z. B. AWS Rekognition Face Liveness) oder eigenes Modell | Selfie-Check |
| Attestierung | Play Integrity, App Attest | Bot-/Emulator-Erkennung |
| Jobs | Queue (z. B. BullMQ / NATS) | Tagesauswahl berechnen, Moderation, Bot-Analyse |

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
- `preferences` (user_id, age_min/max, distance_km, dealbreakers)
- `daily_batches` (user_id, date, candidate_ids[])
- `likes` (from, to, target_type, target_id, comment, created_at)
- `passes` (from, to, created_at)
- `matches` (id, user_a, user_b, state, created_at, closed_at)
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

### Phase 0 – Validierung (4–6 Wochen)
- Interviews mit 15–20 Zielpersonen (Frust mit bestehenden Apps, Akzeptanz von Limits, Zahlungsbereitschaft)
- Klickbarer Prototyp (Figma), Test der Limits
- Entscheidung Monetarisierung + Tech-Stack

### Phase 1 – MVP (ca. 3–4 Monate)
- Onboarding, Profil (Fotos, Prompts, Absichten), Telefon-Verifizierung
- Tagesauswahl mit harten Filtern + einfacher Kompatibilität + Fairness-Kontingent
- Like-Budget, Like mit Kommentar, Match, Chat, Chat-Limit
- Selfie-Verifizierung, Melden/Blockieren, Basis-Moderation
- Regelbasierte Bot-Erkennung (Rate-Limits, Attestierung, Nachrichten-Muster)

### Phase 2 – Closed Beta in **einer** Stadt
- Kaltstart lösen: Dichte schlägt Reichweite – Warteliste, Freischaltung erst ab kritischer Masse pro Region
- Limits und Kontingente anhand echter Daten justieren

### Phase 3 – Ausbau
- Date-Planung, Post-Date-Feedback, Transparenz-Seite „Warum sehe ich diese Person?“
- ML-gestützte Bot-Erkennung
- Weitere Städte

## 11. Risiken

| Risiko | Gegenmaßnahme |
|---|---|
| Kaltstart / zu wenige Profile | Start in einer Stadt, Warteliste, Community-Events |
| Limits frustrieren Nutzer:innen | Limits erklären, mit Daten justieren, Fokus als Feature vermarkten |
| Ungleiches Geschlechterverhältnis | Fairness-Kontingente, Freischaltung nach Balance pro Region |
| Finanzierung | schlanker Stack, Abo-Modell früh testen |
| Romance-Scams | Verifizierung, Scam-Warnungen im Chat, schnelle Moderation |

## 12. Offene Entscheidungen

1. Monetarisierungsmodell (A/B/C/D oder Kombination)?
2. Zielgruppe zum Start (alle Orientierungen, Altersgruppe, Region)?
3. Konkrete Limits: Likes/Tag, Profile/Tag, aktive Chats?
4. Kostet ein Like-zurück auf ein eingehendes Like Budget?
5. Verifizierung Pflicht vor erstem Like oder erst vor erstem Chat?
6. Tech-Stack: Flutter vs. React Native, NestJS vs. Go?
7. Team & Budget: Wer baut was, eigenes Projekt oder Gründung?
