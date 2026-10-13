import '../models.dart';

Abschnitt vorbereitung(Profil p) => Abschnitt(
  id: 'vorbereitung',
  titel: 'Vorbereitung',
  beschreibung: 'Das Heimgerät bekommt eine feste Adresse und ist auf dem aktuellen Stand.',
  schritte: [
    Schritt(
      id: 'vorb-updates',
      titel: 'Updates einspielen',
      text: [
        switch (p.geraet) {
          Heimgeraet.synology =>
            'DSM öffnen: Systemsteuerung › Aktualisieren & Wiederherstellen › Update installieren.',
          Heimgeraet.qnap => 'QTS öffnen: Systemsteuerung › System › Firmware-Aktualisierung.',
          Heimgeraet.windows => 'Einstellungen › Windows Update › Nach Updates suchen.',
          Heimgeraet.mac => 'Systemeinstellungen › Allgemein › Softwareupdate.',
          Heimgeraet.linux => 'Paketquellen aktualisieren und alle Updates einspielen (Befehl unten).',
        },
        if (p.router == HeimRouter.fritzbox)
          'FRITZ!Box: System › Update › FRITZ!OS-Version. Für WireGuard wird FRITZ!OS 7.50 oder neuer benötigt.'
        else
          'Router-Firmware im Router-Menü auf den neuesten Stand bringen.',
        'Handy-Betriebssystem aktualisieren.',
      ],
      befehle: [if (p.geraet == Heimgeraet.linux) 'sudo apt update && sudo apt full-upgrade'],
    ),
    Schritt(
      id: 'vorb-feste-ip',
      titel: 'Feste IP-Adresse im Heimnetz vergeben',
      text: [
        if (p.router == HeimRouter.fritzbox) ...[
          'FRITZ!Box-Oberfläche öffnen (http://fritz.box).',
          'Heimnetz › Netzwerk › Netzwerkverbindungen › beim Heimgerät auf „Bearbeiten“ (Stift).',
          'Haken bei „Diesem Netzwerkgerät immer die gleiche IPv4-Adresse zuweisen“ setzen und übernehmen.',
        ] else ...[
          'Router-Oberfläche öffnen (Adresse steht meist auf der Unterseite des Routers).',
          'Im DHCP-Bereich eine „Adressreservierung“ / „statische Zuweisung“ für das Heimgerät anlegen.',
        ],
        'Die Adresse notieren (z. B. 192.168.178.20) – sie wird später gebraucht.',
      ],
      tipp:
          'Das Heimnetz sollte kein „Allerweltsnetz“ wie 192.168.0.x oder 192.168.1.x sein. Sonst kann es '
          'unterwegs im Hotel- oder Café-WLAN zu Adresskonflikten kommen. 192.168.178.x der FRITZ!Box ist meist unproblematisch.',
    ),
    Schritt(
      id: 'vorb-konto',
      titel: 'Eigenes Benutzerkonto mit starkem Passwort',
      text: [
        switch (p.geraet) {
          Heimgeraet.synology =>
            'Systemsteuerung › Benutzer & Gruppe: ein eigenes Konto anlegen, das Standardkonto „admin“ deaktivieren.',
          Heimgeraet.qnap =>
            'Systemsteuerung › Privilegien › Benutzer: eigenes Administratorkonto anlegen, „admin“ deaktivieren.',
          Heimgeraet.windows => 'Für die Dateifreigabe ein Benutzerkonto mit Passwort verwenden (Konten ohne Passwort können keine Freigaben nutzen).',
          Heimgeraet.mac => 'Ein Benutzerkonto mit Passwort verwenden; die Freigabe wird diesem Konto zugeordnet.',
          Heimgeraet.linux => 'Einen normalen Benutzer (nicht root) für Freigabe und Synchronisation verwenden.',
        },
        'Passwort lang und einzigartig wählen und im Passwortmanager speichern.',
        if (p.geraet.istNas) 'Zwei-Faktor-Anmeldung für das Admin-Konto einschalten.',
      ],
    ),
  ],
);

Abschnitt anschlussPruefen(Profil p) => Abschnitt(
  id: 'anschluss',
  titel: 'Internetanschluss prüfen',
  beschreibung: 'Ob dein Heimnetz von außen direkt erreichbar ist, entscheidet über den passenden Weg.',
  schritte: [
    Schritt(
      id: 'ansch-ipv4',
      titel: 'Öffentliche IPv4 oder DS-Lite?',
      text: [
        if (p.router == HeimRouter.fritzbox)
          'FRITZ!Box: Internet › Online-Monitor. Steht dort „DS-Lite-Tunnel“ oder fehlt eine IPv4-Adresse, '
              'hast du keine eigene öffentliche IPv4.'
        else
          'Im Router-Menü die WAN-/Internet-IPv4-Adresse ablesen.',
        'Beginnt die Adresse mit 10., 100.64.–100.127., 172.16.–172.31. oder 192.168., ist es keine öffentliche Adresse (CGNAT).',
        'Zum Vergleich: In der App unter „Werkzeuge › Öffentliche IP“ (optional) die Adresse abrufen, mit der du im Internet '
            'erscheinst. Weicht sie von der Router-Adresse ab, liegt CGNAT vor.',
        'Ergebnis bei Bedarf im Profil korrigieren – die Anleitung passt sich an.',
      ],
      tipp:
          'Kabel- und Glasfaseranschlüsse haben oft DS-Lite. Viele Anbieter stellen auf Nachfrage kostenlos '
          'oder gegen Aufpreis auf eine öffentliche IPv4 um.',
    ),
  ],
);
