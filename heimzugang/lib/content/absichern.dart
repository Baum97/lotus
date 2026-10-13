import '../models.dart';

Abschnitt absichern(Profil p, Zugangsweg weg) => Abschnitt(
  id: 'absichern',
  titel: 'Absichern',
  beschreibung: 'Der Zugang ist eingerichtet – jetzt die Türen schließen, die nicht offen sein müssen.',
  schritte: [
    Schritt(
      id: 'sich-ports',
      titel: 'Keine unnötigen Portfreigaben',
      text: [
        if (p.router == HeimRouter.fritzbox) ...[
          'FRITZ!Box: Internet › Freigaben › Portfreigaben – alle Einträge prüfen und löschen, die du nicht brauchst.',
          'Beim Heimgerät „Selbstständige Portfreigaben erlauben“ (UPnP) ausschalten.',
        ] else
          'Im Router alle Portweiterleitungen prüfen und UPnP ausschalten.',
        if (weg == Zugangsweg.eigenerWireguard) 'Einzig erlaubte Freigabe: UDP 51820 für WireGuard.',
        if (weg != Zugangsweg.eigenerWireguard) 'Für deinen Zugangsweg ist keine einzige Portfreigabe nötig.',
      ],
      warnung:
          'SMB (445), NAS-Oberflächen (5000/5001, 8080), SSH (22) und Remotedesktop (3389) gehören nie direkt ins '
          'Internet – sie werden ständig automatisiert angegriffen.',
    ),
    if (p.geraet.istNas)
      Schritt(
        id: 'sich-nas-cloud',
        titel: 'Hersteller-Fernzugang abschalten, wenn nicht benötigt',
        text: [
          if (p.geraet == Heimgeraet.synology)
            'Systemsteuerung › Externer Zugriff › QuickConnect: deaktivieren, wenn du nur noch über VPN zugreifst.'
          else
            'myQNAPcloud: deaktivieren, wenn du nur noch über VPN zugreifst.',
          'Automatische Sperre nach Fehlversuchen einschalten (Synology: Sicherheit › Konto › Auto-Block; '
              'QNAP: Sicherheit › IP-Zugriffsschutz).',
        ],
      ),
    const Schritt(
      id: 'sich-backup',
      titel: 'Echte Datensicherung (3-2-1)',
      text: [
        'Synchronisation ersetzt kein Backup: Ein gelöschter oder von Schadsoftware verschlüsselter Ordner wird mitsynchronisiert.',
        'Regel: 3 Kopien, 2 verschiedene Datenträger, 1 Kopie außer Haus (z. B. USB-Platte bei Familie oder verschlüsselt in der Cloud).',
        'Wo möglich Snapshots aktivieren (Synology: Snapshot Replication, QNAP: Snapshots, Linux: Btrfs/ZFS).',
        'Einmal testweise eine Datei aus dem Backup zurückholen.',
      ],
    ),
    Schritt(
      id: 'sich-handy',
      titel: 'Handy schützen',
      text: [
        'Bildschirmsperre mit PIN/Biometrie ist Pflicht – das Handy ist jetzt ein Schlüssel zu deinem Heimnetz.',
        switch (weg) {
          Zugangsweg.fritzWireguard => 'Bei Verlust: VPN-Verbindung in der FRITZ!Box unter VPN (WireGuard) löschen.',
          Zugangsweg.tailscale => 'Bei Verlust: Gerät in der Tailscale-Verwaltung (Machines) entfernen.',
          Zugangsweg.eigenerWireguard =>
            'Bei Verlust: [Peer]-Block des Handys aus wg0.conf entfernen, '
                'dann „sudo systemctl restart wg-quick@wg0“.',
        },
        'Passwort des Heimgerät-Kontos ändern, falls es auf dem verlorenen Handy gespeichert war.',
      ],
    ),
    Schritt(
      id: 'sich-updates',
      titel: 'Automatische Updates',
      text: [
        if (p.router == HeimRouter.fritzbox)
          'FRITZ!Box: System › Update › Auto-Update › „Neue FRITZ!OS-Versionen installieren“.',
        switch (p.geraet) {
          Heimgeraet.synology =>
            'DSM: Aktualisieren & Wiederherstellen › Update-Einstellungen › wichtige Updates automatisch.',
          Heimgeraet.qnap => 'QTS: Firmware-Aktualisierung › Automatische Aktualisierung aktivieren.',
          Heimgeraet.linux => 'Paket „unattended-upgrades“ installieren und aktivieren.',
          _ => 'Automatische Updates des Betriebssystems eingeschaltet lassen.',
        },
        'VPN- und Sync-Apps auf dem Handy aktuell halten.',
      ],
      befehle: [if (p.geraet == Heimgeraet.linux) 'sudo apt install unattended-upgrades'],
    ),
  ],
);
