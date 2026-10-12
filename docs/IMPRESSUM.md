# Impressum – Vorlage für Lotus

Diese Vorlage gilt für die App **und** die Web-Version (z. B. als Link im Play Store, den Google für Apps
mit Käufen verlangt). In der App steht derselbe Text; die Angaben werden in
[`app/lib/legal/legal_info.dart`](../app/lib/legal/legal_info.dart) eingetragen. Solange dort Platzhalter
stehen, zeigt die App „Impressum unvollständig“ an.

> **Hinweis:** Das ist eine sorgfältig recherchierte Vorlage, aber keine Rechtsberatung. Vor dem Start mit
> fremden Nutzer:innen einmal von einer Anwältin/einem Anwalt für IT-Recht oder über einen
> Rechtstexte-Dienst (z. B. IT-Recht Kanzlei, eRecht24 Premium) prüfen lassen – besonders zusammen mit
> Datenschutzerklärung und Nutzungsbedingungen.

---

## Impressum

### Angaben gemäß § 5 DDG

[Vorname Nachname]
[Straße Hausnummer]
[PLZ Ort]
Deutschland

### Kontakt

Telefon: [+49 …]
E-Mail: [kontakt@example.de]

### Umsatzsteuer-Identifikationsnummer gemäß § 27a UStG

[DE…] – *Abschnitt löschen, wenn keine USt-IdNr. vorhanden ist.*

### Wirtschafts-Identifikationsnummer gemäß § 139c AO

[DE…-00001] – *Abschnitt löschen, wenn keine W-IdNr. vorhanden ist.*

### Verantwortlich für den Inhalt nach § 18 Abs. 2 MStV

[Vorname Nachname]
[Straße Hausnummer]
[PLZ Ort]
Deutschland

### Zentrale Kontaktstelle nach Art. 11 und 12 DSA

Für Behörden, die EU-Kommission, das Gremium für digitale Dienste sowie für Nutzer:innen:
[kontakt@example.de]. Wir kommunizieren auf Deutsch und Englisch. Anfragen werden von einem Menschen
bearbeitet.

### Verbraucherstreitbeilegung

Wir sind nicht bereit und nicht verpflichtet, an Streitbeilegungsverfahren vor einer
Verbraucherschlichtungsstelle teilzunehmen.

---

## Ausfüllen – ohne Spielraum

| Angabe | Pflicht | Was genau |
|---|---|---|
| Name | ja | Vollständiger Vor- und Nachname, wie im Ausweis. Kein Spitzname, keine Abkürzung, kein „Lotus-Team“. |
| Anschrift | ja | **Ladungsfähig**: Straße, Hausnummer, PLZ, Ort. **Kein Postfach.** |
| E-Mail | ja | Muss gelesen werden – Anfragen zeitnah beantworten. |
| Zweiter Kontaktweg | ja | Telefonnummer (EuGH, C-298/07: neben der E-Mail ein weiterer schneller Kontaktweg). |
| USt-IdNr. | nur wenn vorhanden | Kleinunternehmer (§ 19 UStG) ohne USt-IdNr.: Abschnitt weglassen. **Nie die Steuernummer angeben.** |
| W-IdNr. | nur wenn vorhanden | Wird vom BZSt seit Ende 2024 schrittweise vergeben. |
| DSA-Kontaktstelle | ja | Gilt für jeden Vermittlungsdienst unabhängig von der Größe. Die Kontaktstelle für Nutzer:innen darf **nicht nur ein Bot** sein (Art. 12 DSA). |

**Bewusst nicht enthalten:**
- **Kein Link zur EU-OS-Plattform (Online-Streitbeilegung).** Die Plattform wurde am 20.07.2025
  abgeschaltet. Ein alter Hinweis darauf gilt als irreführend und kann abgemahnt werden.
- **Keine „Haftung für Inhalte/Links“-Floskeln.** Sie sind rechtlich wirkungslos.

**Wo das Impressum stehen muss:** „leicht erkennbar, unmittelbar erreichbar und ständig verfügbar“ – in der
App auf dem Login-Screen und im Profil (umgesetzt), im Play Store als Web-Link und auf einer eventuellen
Website. Seit dem 28.06.2025 auch barrierefrei, also als echter Text und nicht als Bild (umgesetzt).

## Was sich ändert, sobald Lotus Geld einnimmt

Mit Lotus Plus oder Spenden über den Play Store wird aus dem Hobbyprojekt ein **geschäftsmäßiges Angebot**:

1. **Gewerbe anmelden** beim Gewerbeamt deines Wohnorts (meist online, ca. 20–60 €).
2. **Finanzamt:** Fragebogen zur steuerlichen Erfassung. Bei wenig Umsatz die Kleinunternehmerregelung
   (§ 19 UStG) wählen; Google führt die Umsatzsteuer für Play-Store-Verkäufe an Verbraucher in der EU
   ohnehin selbst ab.
3. **Play Console:** Als Händlerkonto werden Name und Adresse **öffentlich im Store angezeigt** – dieselbe
   Adresse wie im Impressum.
4. **Rechtstexte ergänzen:** Nutzungsbedingungen mit Abo-Regeln, Widerrufsbelehrung für digitale Inhalte,
   Kündigungsmöglichkeit (in Google Play vorhanden).

## Noch offene Rechtsfragen (vor dem Start klären)

- **Datenschutzerklärung** inkl. Art. 9 DSGVO (Orientierung), Supabase, Firebase und Google Play als Empfänger.
- **Datenschutz-Folgenabschätzung (DSFA)** – bei Dating-Apps praktisch immer nötig.
- **Jugendschutz:** Ob ein Jugendschutzbeauftragter oder der Anschluss an eine Selbstkontrolle (§ 7 JMStV)
  nötig ist, hängt von den Inhalten ab. Lotus ist ab 18 und moderiert, das sollte aber einmal fachlich
  geprüft werden.
- **Privatadresse:** Wer die eigene Wohnadresse nicht veröffentlichen möchte, kann eine Geschäftsadresse
  (Coworking, Bürodienst) nutzen. Sie muss aber **ladungsfähig** sein, also Post persönlich zustellbar
  machen. Reine c/o-Weiterleitungen sind umstritten.
