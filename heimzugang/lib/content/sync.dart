import '../models.dart';

Abschnitt synchronisieren(Profil p, Zugangsweg weg) => Abschnitt(
  id: 'sync',
  titel: 'Synchronisieren',
  beschreibung: 'Fotos und Ordner gelangen automatisch auf dein Heimgerät – ohne Cloud-Anbieter.',
  schritte: [if (p.ziele.contains(Ziel.fotos)) _fotos(p), if (p.ziele.contains(Ziel.ordner)) ..._syncthing(p, weg)],
);

Schritt _fotos(Profil p) => switch (p.geraet) {
  Heimgeraet.synology => const Schritt(
    id: 'sync-fotos',
    titel: 'Foto-Sicherung mit Synology Photos',
    text: [
      'DSM: Paket-Zentrum › „Synology Photos“ installieren.',
      'App „Synology Photos“ aufs Handy laden, als Adresse die VPN-/Tailscale-Adresse des NAS eingeben, '
          'HTTPS aktivieren und anmelden.',
      'In der App: Einstellungen › Sicherung › aktivieren. Auswählen, ob nur im WLAN oder auch per Mobilfunk gesichert wird.',
      'Hintergrundaktualisierung bzw. Akkuoptimierung für die App erlauben, damit die Sicherung zuverlässig läuft.',
    ],
  ),
  Heimgeraet.qnap => const Schritt(
    id: 'sync-fotos',
    titel: 'Foto-Sicherung mit QNAP',
    text: [
      'QTS: App Center › „QuMagie“ installieren.',
      'App „Qfile“ aufs Handy laden, NAS über die VPN-/Tailscale-Adresse hinzufügen und anmelden.',
      'In Qfile: Einstellungen › „Automatisches Hochladen“ aktivieren und einen Zielordner auf dem NAS wählen.',
      'Akkuoptimierung für Qfile abschalten, damit das Hochladen im Hintergrund läuft.',
    ],
  ),
  _ => Schritt(
    id: 'sync-fotos',
    titel: 'Foto-Sicherung auf den ${p.geraet.label}',
    text: [
      if (p.handy == Handy.android)
        'Am einfachsten mit Syncthing (siehe nächster Schritt): Den Kameraordner DCIM/Camera als Ordner '
            'vom Typ „Nur senden“ teilen.'
      else
        'iOS erlaubt Syncthing nur eingeschränkt. Bewährt: eine Foto-Sicherungs-App mit SMB-Ziel (z. B. „PhotoSync“) '
            'auf die Freigabe aus Abschnitt 4 einrichten.',
      'Für Fortgeschrittene: „Immich“ (selbst gehostete Fotoverwaltung, Docker) bietet eine Google-Fotos-ähnliche App.',
    ],
    warnung:
        'Eine Synchronisation ist keine Datensicherung: Gelöschte Fotos können auch auf dem Ziel verschwinden. '
        'Ordner deshalb „Nur senden“ bzw. ohne Löschen synchronisieren.',
  ),
};

List<Schritt> _syncthing(Profil p, Zugangsweg weg) => [
  Schritt(
    id: 'sync-st-heim',
    titel: 'Syncthing auf dem ${p.geraet.label} installieren',
    text: switch (p.geraet) {
      Heimgeraet.synology => [
        'Paket-Zentrum › Einstellungen › Paketquellen: die Quelle „SynoCommunity“ (packages.synocommunity.com) hinzufügen.',
        'Unter „Community“ das Paket „Syncthing“ installieren und öffnen.',
      ],
      Heimgeraet.qnap => [
        'Syncthing als Container über die „Container Station“ starten (Image syncthing/syncthing).',
        'Den Datenordner des NAS in den Container einbinden.',
      ],
      Heimgeraet.windows || Heimgeraet.mac => [
        'Syncthing von syncthing.net/downloads herunterladen und installieren.',
        'Die Weboberfläche öffnet sich im Browser (http://127.0.0.1:8384).',
      ],
      Heimgeraet.linux => [
        'Syncthing installieren und als Benutzerdienst starten (Befehle unten).',
        'Weboberfläche: http://127.0.0.1:8384',
      ],
    },
    befehle: [
      if (p.geraet == Heimgeraet.linux) ...[
        'sudo apt install syncthing',
        'systemctl --user enable --now syncthing',
        'sudo loginctl enable-linger \$USER',
      ] else if (!p.geraet.istNas)
        'https://syncthing.net/downloads/',
    ],
    tipp: 'In der Weboberfläche unter Aktionen › Einstellungen › GUI ein Passwort setzen.',
  ),
  Schritt(
    id: 'sync-st-handy',
    titel: 'Syncthing aufs Handy',
    text: switch (p.handy) {
      Handy.android => [
        '„Syncthing-Fork“ installieren (F-Droid oder GitHub-Seite des Projekts). Die frühere offizielle '
            'Android-App wird nicht mehr weiterentwickelt.',
        'App öffnen, Speicherberechtigungen erlauben.',
      ],
      Handy.ios => [
        '„Möbius Sync“ aus dem App Store installieren (Syncthing-kompatibel, kostenpflichtige Vollversion).',
        'Hinweis: iOS synchronisiert im Hintergrund nur eingeschränkt – App gelegentlich öffnen.',
      ],
    },
  ),
  Schritt(
    id: 'sync-st-koppeln',
    titel: 'Geräte koppeln und Ordner teilen',
    text: [
      'Auf dem Heimgerät: Aktionen › „Kennung anzeigen“ – es erscheint ein QR-Code.',
      'In der Handy-App: Geräte › „+“ › QR-Code scannen.',
      'Auf dem Heimgerät erscheint eine Anfrage – „Gerät hinzufügen“ bestätigen.',
      'Auf dem Handy einen Ordner hinzufügen und für das Heimgerät freigeben. Am Heimgerät die Anfrage annehmen '
          'und den Speicherort wählen.',
      'Unter „Erweitert“ die Dateiversionierung („Einfach“ oder „Gestaffelt“) aktivieren – so bleiben '
          'versehentlich gelöschte oder überschriebene Dateien eine Zeit lang erhalten.',
    ],
  ),
  Schritt(
    id: 'sync-st-privat',
    titel: 'Optional: Nur über das eigene VPN synchronisieren',
    text: [
      'Syncthing findet Geräte normalerweise über öffentliche Discovery- und Relay-Server (Inhalte bleiben verschlüsselt).',
      'Wer das nicht möchte: In beiden Apps unter Einstellungen › Verbindungen „Globale Gerätesuche“ und „Weiterleitung“ '
          '(Relays) abschalten.',
      'Beim Gerät auf dem Handy als Adresse die Heimgerät-Adresse über das VPN eintragen (Beispiel unten).',
    ],
    befehle: [weg == Zugangsweg.tailscale ? 'tcp://100.x.y.z:22000' : 'tcp://192.168.178.20:22000'],
  ),
];
