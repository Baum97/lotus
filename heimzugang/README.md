# Heimzugang

Eine App, die Schritt für Schritt erklärt, wie man vom Handy aus **sicher von unterwegs** auf den eigenen
Rechner oder das NAS im Heimnetz zugreift und Daten synchronisiert – ohne Cloud-Anbieter, ohne offene Ports
für die Daten.

Die App hat **keinen Server und kein Konto**. Angaben, Fortschritt und Notizen liegen nur lokal auf dem Handy
(`shared_preferences`). Einzige optionale Verbindung nach außen: die Abfrage der öffentlichen IP bei
`api.ipify.org`, und nur auf Knopfdruck.

## Was die App macht

1. **Einrichtungsassistent** – fragt ab: Heimgerät (Synology, QNAP, Windows, Mac, Linux/Raspberry Pi), Handy
   (Android/iOS), Router (FRITZ!Box/anderer), Internetanschluss (öffentliche IPv4, DS-Lite/CGNAT, unbekannt)
   und Ziele (Dateizugriff, Foto-Sicherung, Ordner-Sync).
2. **Empfehlung des Zugangswegs** (`lib/plan.dart`):

   | Situation | Empfehlung | Wählbar |
   |---|---|---|
   | FRITZ!Box + öffentliche IPv4 | WireGuard der FRITZ!Box | + Tailscale, + eigener WireGuard (nur Linux) |
   | DS-Lite / CGNAT | Tailscale (braucht keine eingehende Verbindung) | + FRITZ!Box-WireGuard (klappt nur, wenn das Mobilfunknetz IPv6 kann) |
   | Anschluss unbekannt | Tailscale | Anleitung zeigt, wie man es prüft |
   | Anderer Router | Tailscale | + eigener WireGuard (nur Linux) |

3. **Persönliche Anleitung** in Abschnitten, jeder Schritt abhakbar, Befehle mit Kopier-Knopf:
   Vorbereitung → Anschluss prüfen → Fernzugang → Freigabe (SMB) → Handy verbinden →
   Synchronisieren (Synology Photos, QNAP Qfile, Syncthing) → Testen über Mobilfunk → Absichern
   (keine Portfreigaben, UPnP aus, 3-2-1-Backup, Verlust des Handys).
4. **Werkzeuge**
   - *Verbindungstest*: TCP-Verbindungsaufbau zu Adresse:Port (SMB 445, DSM 5001, Syncthing 22000 …) mit
     verständlicher Fehlerdeutung (abgelehnt / keine Antwort / Name unbekannt).
   - *Notizen*: Heimnetz-IP, VPN-Adresse, DynDNS-Name – werden im Verbindungstest vorgeschlagen.
   - *Öffentliche IP*: Vergleich mit der WAN-Adresse des Routers erkennt CGNAT/DS-Lite.
5. **Glossar** der Begriffe (VPN, WireGuard, DS-Lite, DynDNS, SMB, Snapshot …).

Grundsatz der Anleitungen: Daten-Dienste (SMB, NAS-Oberfläche, SSH, RDP) werden **nie** ins Internet
freigegeben. Der Zugriff läuft immer durch ein WireGuard-VPN.

## Struktur

```
lib/models.dart          Profil, Schritt, Abschnitt, Auswahl-Enums
lib/plan.dart            Empfehlungslogik und Zusammenbau der Anleitung
lib/content/             Anleitungsinhalte je Abschnitt
lib/state.dart           Profil, Fortschritt und Notizen (lokal gespeichert)
lib/net_check.dart       Verbindungstest, öffentliche IP, Adressbereichs-Prüfung
lib/screens/             Assistent, Übersicht, Abschnitt, Werkzeuge, Glossar
test/                    Logik-, Netzwerk- und Oberflächentests
```

Neue Inhalte: Schritt in der passenden Datei unter `lib/content/` ergänzen. Schritt-IDs nie umbenennen –
an ihnen hängt der gespeicherte Fortschritt. `test/plan_test.dart` prüft alle Profil-Kombinationen auf
eindeutige IDs und leere Abschnitte.

## Entwickeln

```bash
cd heimzugang
flutter pub get
flutter test
flutter run            # Android oder iOS; Web wird nicht unterstützt (Verbindungstest braucht Sockets)
```

iOS: `NSLocalNetworkUsageDescription` ist gesetzt, damit der Verbindungstest Geräte im Heim-WLAN erreichen darf.
