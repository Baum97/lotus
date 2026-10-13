import '../models.dart';

Abschnitt freigabe(Profil p) => Abschnitt(
  id: 'freigabe',
  titel: 'Ordner im Heimnetz freigeben',
  beschreibung: 'Ein Ordner auf dem ${p.geraet.label} wird per SMB (Windows-Dateifreigabe) erreichbar.',
  schritte: [
    Schritt(
      id: 'freig-ordner',
      titel: 'Freigabe anlegen',
      text: switch (p.geraet) {
        Heimgeraet.synology => [
          'Systemsteuerung › Gemeinsamer Ordner › Erstellen, z. B. „Daten“.',
          'Papierkorb aktivieren; bei Btrfs-Volumes Datenprüfsumme aktivieren.',
          'Berechtigungen: nur dein eigenes Konto mit Lesen/Schreiben.',
          'Systemsteuerung › Dateidienste › SMB: „SMB-Dienst aktivieren“. Unter „Erweiterte Einstellungen“ '
              'als Minimum SMB2 einstellen.',
        ],
        Heimgeraet.qnap => [
          'Systemsteuerung › Privilegien › Freigabeordner › Erstellen, z. B. „Daten“.',
          'Zugriffsrechte nur für dein eigenes Konto vergeben.',
          'Systemsteuerung › Netzwerk- & Dateidienste › Win/Mac/NFS/WebDAV › SMB aktivieren, '
              'niedrigste Version SMB 2.1 oder höher.',
        ],
        Heimgeraet.windows => [
          'Einstellungen › Netzwerk und Internet › WLAN/Ethernet: Netzwerkprofil auf „Privat“ stellen.',
          'Rechtsklick auf den Ordner › Eigenschaften › Freigabe › „Erweiterte Freigabe“.',
          '„Diesen Ordner freigeben“ anhaken › Berechtigungen: „Jeder“ entfernen, dein Konto mit „Ändern“ hinzufügen.',
          'Beim Anmelden vom Handy den Windows-Benutzernamen (bei Microsoft-Konto die E-Mail-Adresse) und das '
              'Kontopasswort verwenden – nicht die PIN.',
        ],
        Heimgeraet.mac => [
          'Systemeinstellungen › Allgemein › Teilen › „Dateifreigabe“ einschalten.',
          'Auf das (i) daneben tippen, mit „+“ den Ordner hinzufügen und nur deinem Benutzer Lese-/Schreibrechte geben.',
          '„Optionen…“ › „Dateien und Ordner über SMB teilen“ anhaken und deinen Benutzer aktivieren.',
          'Ruhezustand verhindern: Systemeinstellungen › Energie › „Ruhezustand bei Netzwerkzugriff beenden“ aktivieren.',
        ],
        Heimgeraet.linux => [
          'Samba installieren (Befehl unten).',
          'Am Ende von /etc/samba/smb.conf eine Freigabe eintragen (Beispiel unten, Pfad und Benutzer anpassen).',
          'Samba-Passwort für deinen Benutzer setzen und den Dienst neu starten.',
        ],
      },
      befehle: [
        if (p.geraet == Heimgeraet.linux) ...[
          'sudo apt install samba',
          '[daten]\n'
              '   path = /home/BENUTZER/Daten\n'
              '   valid users = BENUTZER\n'
              '   read only = no\n'
              '   server min protocol = SMB2',
          'sudo smbpasswd -a BENUTZER',
          'sudo systemctl restart smbd',
        ],
      ],
      warnung: p.geraet == Heimgeraet.windows || p.geraet == Heimgeraet.mac
          ? 'Ein PC muss eingeschaltet sein, damit du zugreifen kannst. Energieoptionen so einstellen, dass er nicht '
                'in den Ruhezustand geht, oder „Wake on LAN“ einrichten.'
          : null,
    ),
    const Schritt(
      id: 'freig-lokal-testen',
      titel: 'Im Heimnetz testen',
      text: [
        'Handy mit dem Heim-WLAN verbinden (VPN aus).',
        'Mit dem Verbindungstest Port 445 (SMB) an der festen IP des Heimgeräts prüfen.',
        'Ist der Port hier schon geschlossen, liegt es an Freigabe oder Firewall – nicht am Fernzugang.',
      ],
      verbindungstest: true,
    ),
  ],
);
