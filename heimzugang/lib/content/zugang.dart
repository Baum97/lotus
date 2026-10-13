import '../models.dart';

Abschnitt fernzugang(Profil p, Zugangsweg weg) => Abschnitt(
  id: 'fernzugang',
  titel: 'Fernzugang einrichten',
  beschreibung: '${weg.label}: ${weg.kurz}',
  schritte: switch (weg) {
    Zugangsweg.fritzWireguard => _fritzWireguard(p),
    Zugangsweg.tailscale => _tailscale(p),
    Zugangsweg.eigenerWireguard => _eigenerWireguard(p),
  },
);

List<Schritt> _fritzWireguard(Profil p) => [
  Schritt(
    id: 'fritz-myfritz',
    titel: 'MyFRITZ!-Adresse einrichten',
    text: [
      'FRITZ!Box: Internet › MyFRITZ!-Konto › „MyFRITZ! für diese FRITZ!Box aktivieren“.',
      'Mit einer E-Mail-Adresse registrieren und die Bestätigungsmail öffnen.',
      'Die angezeigte MyFRITZ!-Adresse (endet auf .myfritz.net) notieren. Sie zeigt immer auf deinen Anschluss, '
          'auch wenn sich die IP-Adresse ändert.',
    ],
    tipp: 'Der WireGuard-Assistent trägt diese Adresse automatisch in die VPN-Verbindung ein.',
  ),
  Schritt(
    id: 'fritz-wg-anlegen',
    titel: 'WireGuard-Verbindung für das Handy anlegen',
    text: [
      'Internet › Freigaben › VPN (WireGuard) › „Verbindung hinzufügen“.',
      '„Vereinfachte Einrichtung“ wählen und „Einzelgerät verbinden“ (Smartphone, Notebook) auswählen.',
      'Einen Namen vergeben, z. B. „Handy“, und fertigstellen.',
      'Die Bestätigung an der FRITZ!Box durchführen (Taste drücken oder Code am Telefon, je nach Einstellung).',
      'Den angezeigten QR-Code geöffnet lassen – er wird im nächsten Abschnitt mit dem Handy gescannt.',
    ],
    tipp: 'Menünamen weichen je nach FRITZ!OS-Version leicht ab. Für jedes Gerät eine eigene Verbindung anlegen.',
    warnung:
        'Der QR-Code enthält den geheimen Schlüssel. Nicht abfotografieren, nicht teilen. '
        'Geht das Handy verloren, die Verbindung in der FRITZ!Box löschen.',
  ),
];

List<Schritt> _tailscale(Profil p) => [
  Schritt(
    id: 'ts-konto',
    titel: 'Tailscale-Konto anlegen',
    text: [
      'Auf tailscale.com „Get started“ wählen und mit einem bestehenden Konto (Google, Microsoft, Apple, GitHub) anmelden.',
      'Für private Nutzung reicht der kostenlose Tarif.',
    ],
    befehle: ['https://login.tailscale.com/start'],
    tipp:
        'Tailscale überträgt deine Daten Ende-zu-Ende-verschlüsselt (WireGuard). Der Anbieter sieht nur, welche Geräte '
        'existieren, nicht deine Dateien. Wer gar keinen Fremdanbieter möchte, kann den Koordinationsserver mit „Headscale“ '
        'selbst betreiben.',
  ),
  Schritt(
    id: 'ts-heimgeraet',
    titel: 'Tailscale auf dem ${p.geraet.label} installieren',
    text: switch (p.geraet) {
      Heimgeraet.synology => [
        'DSM: Paket-Zentrum öffnen, nach „Tailscale“ suchen und installieren.',
        'Paket öffnen, „Log in“ wählen und mit dem Tailscale-Konto anmelden.',
      ],
      Heimgeraet.qnap => [
        'QTS: App Center öffnen, nach „Tailscale“ suchen und installieren.',
        'App öffnen und mit dem Tailscale-Konto anmelden.',
      ],
      Heimgeraet.windows || Heimgeraet.mac => [
        'Installationsprogramm von tailscale.com/download herunterladen und installieren.',
        'Über das Tailscale-Symbol (Taskleiste bzw. Menüleiste) „Log in“ wählen und anmelden.',
        if (p.geraet == Heimgeraet.windows) 'Im Tailscale-Menü „Run unattended“ aktivieren, damit der Zugang auch ohne angemeldeten Benutzer funktioniert.',
      ],
      Heimgeraet.linux => [
        'Installationsskript ausführen (Befehl unten).',
        '„tailscale up“ ausführen und den angezeigten Link zum Anmelden öffnen.',
      ],
    },
    befehle: [
      if (p.geraet == Heimgeraet.linux) ...[
        'curl -fsSL https://tailscale.com/install.sh | sh',
        'sudo tailscale up',
      ] else if (!p.geraet.istNas)
        'https://tailscale.com/download',
    ],
  ),
  const Schritt(
    id: 'ts-ablauf',
    titel: 'Schlüsselablauf für das Heimgerät abschalten',
    text: [
      'In der Tailscale-Verwaltung (login.tailscale.com/admin/machines) beim Heimgerät auf „…“ tippen.',
      '„Disable key expiry“ wählen. Sonst muss sich das Heimgerät alle paar Monate neu anmelden – '
          'was unterwegs nicht möglich ist.',
      'Die Tailscale-Adresse des Heimgeräts notieren (beginnt mit 100.) sowie den Gerätenamen.',
    ],
    befehle: ['https://login.tailscale.com/admin/machines'],
  ),
];

List<Schritt> _eigenerWireguard(Profil p) => [
  Schritt(
    id: 'wg-dyndns',
    titel: 'Feste Adresse für den Anschluss (DynDNS)',
    text: [
      'Deine öffentliche IP ändert sich regelmäßig. Ein DynDNS-Name zeigt immer auf die aktuelle Adresse.',
      if (p.router == HeimRouter.fritzbox)
        'Am einfachsten: MyFRITZ! aktivieren (Internet › MyFRITZ!-Konto) und die .myfritz.net-Adresse verwenden.'
      else
        'Im Router unter „DynDNS“ / „DDNS“ einen Anbieter eintragen (z. B. den des Router-Herstellers oder einen freien Dienst).',
      'Den Namen notieren, z. B. meinzuhause.example.net.',
    ],
  ),
  const Schritt(
    id: 'wg-installieren',
    titel: 'WireGuard auf dem Linux-Rechner installieren',
    text: [
      'Pakete installieren und Schlüsselpaare für Server und Handy erzeugen (Befehle unten).',
      'Die Schlüssel bleiben im Ordner /etc/wireguard und sind nur für root lesbar.',
    ],
    befehle: [
      'sudo apt install wireguard qrencode iptables',
      'sudo sh -c \'umask 077; cd /etc/wireguard && wg genkey | tee server.key | wg pubkey > server.pub '
          '&& wg genkey | tee handy.key | wg pubkey > handy.pub\'',
      'ip route get 1.1.1.1   # zeigt den Netzwerkadapter, z. B. „dev eth0“',
    ],
  ),
  const Schritt(
    id: 'wg-config',
    titel: 'Server konfigurieren',
    text: [
      'Datei /etc/wireguard/wg0.conf mit dem Inhalt unten anlegen (sudo nano /etc/wireguard/wg0.conf).',
      '<SERVER_KEY> durch den Inhalt von server.key und <HANDY_PUB> durch handy.pub ersetzen.',
      'eth0 durch den Adapternamen aus dem vorigen Schritt ersetzen.',
      'Weiterleitung einschalten und den Dienst dauerhaft starten (Befehle unten).',
    ],
    befehle: [
      '[Interface]\n'
          'Address = 10.8.0.1/24\n'
          'ListenPort = 51820\n'
          'PrivateKey = <SERVER_KEY>\n'
          'PostUp = iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE\n'
          'PostDown = iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE\n'
          '\n'
          '[Peer]\n'
          'PublicKey = <HANDY_PUB>\n'
          'AllowedIPs = 10.8.0.2/32',
      'echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-wireguard.conf && sudo sysctl --system',
      'sudo systemctl enable --now wg-quick@wg0',
    ],
  ),
  Schritt(
    id: 'wg-portfreigabe',
    titel: 'Portfreigabe UDP 51820',
    text: [
      if (p.router == HeimRouter.fritzbox)
        'FRITZ!Box: Internet › Freigaben › Portfreigaben › Gerät für Freigaben hinzufügen › Linux-Rechner wählen › '
            'Neue Freigabe › Portfreigabe, Protokoll UDP, Port 51820.'
      else
        'Im Router eine Portweiterleitung anlegen: Protokoll UDP, Port 51820, Ziel = feste IP des Linux-Rechners.',
      'Nur diesen einen Port freigeben – WireGuard antwortet nicht auf fremde Anfragen und ist dadurch von außen unsichtbar.',
    ],
    warnung:
        'Niemals Ports für Dateifreigaben (445), Weboberflächen oder Fernwartung (22, 3389) ins Internet freigeben.',
  ),
  const Schritt(
    id: 'wg-handy-config',
    titel: 'Handy-Konfiguration als QR-Code erzeugen',
    text: [
      'Datei handy.conf mit dem Inhalt unten anlegen; <HANDY_KEY> = Inhalt von handy.key, <SERVER_PUB> = server.pub.',
      'Endpoint = dein DynDNS-Name. Unter AllowedIPs dein Heimnetz eintragen (z. B. 192.168.178.0/24).',
      'QR-Code im Terminal anzeigen und im nächsten Abschnitt mit dem Handy scannen.',
      'Danach handy.conf und handy.key löschen – das Handy hat sie gespeichert.',
    ],
    befehle: [
      '[Interface]\n'
          'PrivateKey = <HANDY_KEY>\n'
          'Address = 10.8.0.2/32\n'
          '\n'
          '[Peer]\n'
          'PublicKey = <SERVER_PUB>\n'
          'Endpoint = meinzuhause.example.net:51820\n'
          'AllowedIPs = 192.168.178.0/24, 10.8.0.0/24\n'
          'PersistentKeepalive = 25',
      'sudo qrencode -t ansiutf8 < handy.conf',
      'sudo shred -u handy.conf /etc/wireguard/handy.key',
    ],
  ),
];

Abschnitt handyVerbinden(Profil p, Zugangsweg weg) {
  final adresse = switch (weg) {
    Zugangsweg.tailscale => 'die Tailscale-Adresse des Heimgeräts (100.x.y.z) oder seinen Namen',
    _ => 'die feste Heimnetz-IP des Heimgeräts (z. B. 192.168.178.20)',
  };
  return Abschnitt(
    id: 'handy',
    titel: 'Handy verbinden',
    beschreibung: 'VPN-App einrichten und die Freigabe auf dem Handy einbinden.',
    schritte: [
      Schritt(
        id: 'handy-vpn',
        titel: weg == Zugangsweg.tailscale ? 'Tailscale-App einrichten' : 'WireGuard-App einrichten',
        text: [
          if (weg == Zugangsweg.tailscale) ...[
            'Tailscale aus dem ${p.handy == Handy.ios ? 'App Store' : 'Play Store'} installieren.',
            'Mit demselben Konto wie beim Heimgerät anmelden und die VPN-Anfrage des Systems erlauben.',
            'In der Geräteliste der App muss das Heimgerät als „Connected“ erscheinen.',
          ] else ...[
            'Die offizielle App „WireGuard“ aus dem ${p.handy == Handy.ios ? 'App Store' : 'Play Store'} installieren.',
            '„+“ › „QR-Code scannen“ und den QR-Code vom vorigen Abschnitt scannen.',
            'Der Verbindung einen Namen geben (z. B. „Zuhause“) und die VPN-Anfrage des Systems erlauben.',
          ],
        ],
        tipp: p.handy == Handy.android
            ? 'Dauerhaft verbunden bleiben: Android-Einstellungen › Netzwerk › VPN › Zahnrad › „Durchgehend aktives VPN“.'
            : weg == Zugangsweg.tailscale
            ? null
            : 'In der WireGuard-App unter „Bei Bedarf aktivieren“ einstellen, dass das VPN nur im Mobilfunk/fremden WLAN startet.',
      ),
      if (p.ziele.contains(Ziel.dateien))
        Schritt(
          id: 'handy-dateien',
          titel: 'Freigabe in einer Datei-App einbinden',
          text: switch (p.handy) {
            Handy.ios => [
              'App „Dateien“ öffnen › „Durchsuchen“ › oben rechts „…“ › „Mit Server verbinden“.',
              'Als Server smb:// gefolgt von $adresse eingeben.',
              '„Registrierter Benutzer“ wählen, Benutzername und Passwort des Heimgeräts eingeben.',
              'Die Freigabe erscheint links unter „Freigegeben“.',
            ],
            Handy.android => [
              'Android hat keinen eingebauten SMB-Zugriff. Eine Datei-App mit SMB installieren, '
                  'z. B. die quelloffene „Material Files“ (Play Store oder F-Droid).',
              if (p.geraet == Heimgeraet.synology)
                'Alternativ die Synology-App „DS file“ verwenden (Adresse wie unten, Port 5001/HTTPS).',
              if (p.geraet == Heimgeraet.qnap) 'Alternativ die QNAP-App „Qfile“ verwenden.',
              'In Material Files: Menü › „Remote hinzufügen“ › „SMB-Server“.',
              'Als Host $adresse eintragen, Benutzername und Passwort des Heimgeräts.',
            ],
          },
          befehle: [weg == Zugangsweg.tailscale ? 'smb://100.x.y.z' : 'smb://192.168.178.20'],
          tipp:
              'Die Adresse im Befehl ist ein Beispiel – deine echte Adresse hast du in den vorigen Schritten notiert.',
        ),
    ],
  );
}

Abschnitt testen(Profil p, Zugangsweg weg) => Abschnitt(
  id: 'testen',
  titel: 'Von unterwegs testen',
  beschreibung: 'Erst ein Test über Mobilfunk zeigt, ob der Zugang wirklich funktioniert.',
  schritte: [
    const Schritt(
      id: 'test-mobil',
      titel: 'WLAN aus, Mobilfunk an',
      text: [
        'Am Handy das WLAN ausschalten, mobile Daten einschalten.',
        'VPN-Verbindung einschalten.',
        'Mit dem eingebauten Verbindungstest prüfen, ob das Heimgerät erreichbar ist.',
        'Danach eine Datei über die Datei-App öffnen.',
      ],
      verbindungstest: true,
    ),
    Schritt(
      id: 'test-fehler',
      titel: 'Wenn es nicht klappt',
      text: [
        'VPN-App zeigt keine Verbindung: Uhrzeit des Handys prüfen, VPN neu einschalten.',
        if (weg == Zugangsweg.fritzWireguard) ...[
          'Bei DS-Lite funktioniert der FRITZ!Box-VPN nur, wenn das Mobilfunknetz IPv6 unterstützt '
              '(Mobilfunk-Einstellungen › APN-Protokoll „IPv4/IPv6“). Sonst Tailscale verwenden.',
          'In der FRITZ!Box unter System › Ereignisse nach WireGuard-Meldungen sehen.',
        ],
        if (weg == Zugangsweg.eigenerWireguard) ...[
          'Auf dem Server „sudo wg show“ ausführen: Steht beim Peer kein „latest handshake“, kommt nichts an – '
              'Portfreigabe und DynDNS prüfen.',
        ],
        if (weg == Zugangsweg.tailscale) 'In der Tailscale-App prüfen, ob das Heimgerät online ist. Wenn nicht: Tailscale auf dem Heimgerät neu starten.',
        'Verbindung steht, aber Port geschlossen: Freigabe/Dienst auf dem Heimgerät und dessen Firewall prüfen.',
      ],
    ),
  ],
);
