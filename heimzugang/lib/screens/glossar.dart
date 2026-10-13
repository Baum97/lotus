import 'package:flutter/material.dart';

const glossar = <(String, String)>[
  (
    'VPN',
    'Ein verschlüsselter Tunnel vom Handy ins Heimnetz. Mit aktivem VPN verhält sich das Handy so, als wäre es '
        'zu Hause im WLAN – Dienste müssen nicht ins Internet gestellt werden.',
  ),
  (
    'WireGuard',
    'Modernes, schlankes VPN-Protokoll. Verwendet von der FRITZ!Box, von Tailscale und vom eigenen WireGuard-Server.',
  ),
  (
    'Tailscale',
    'Dienst, der Geräte über WireGuard direkt miteinander verbindet, auch hinter DS-Lite/CGNAT. Der Anbieter vermittelt '
        'nur die Verbindung; die Daten fließen Ende-zu-Ende-verschlüsselt. Selbst gehostete Alternative: Headscale.',
  ),
  (
    'Öffentliche IPv4',
    'Die Adresse, unter der dein Anschluss im Internet erreichbar ist. Nur damit kann ein Gerät von außen eine '
        'Verbindung zu dir aufbauen (z. B. zum WireGuard der FRITZ!Box).',
  ),
  (
    'DS-Lite / CGNAT',
    'Dein Anschluss teilt sich eine IPv4-Adresse mit anderen Kunden. Von außen kommt über IPv4 keine Verbindung an. '
        'Abhilfe: Tailscale, IPv6 oder beim Anbieter eine öffentliche IPv4 bestellen.',
  ),
  (
    'DynDNS / MyFRITZ!',
    'Ein fester Name (z. B. xyz.myfritz.net), der immer auf die aktuelle, sich ändernde IP deines Anschlusses zeigt.',
  ),
  (
    'Portfreigabe',
    'Leitet Anfragen aus dem Internet an ein Gerät im Heimnetz weiter. Jede Freigabe ist eine offene Tür – '
        'mit VPN brauchst du für deine Daten keine.',
  ),
  (
    'SMB',
    'Das Protokoll der Windows-Dateifreigabe. Wird von NAS, Mac, Linux, iOS-Dateien-App und Datei-Apps verstanden.',
  ),
  (
    'Syncthing',
    'Quelloffene Software, die Ordner direkt zwischen deinen Geräten synchronisiert – ohne Cloud-Speicher.',
  ),
  (
    'Snapshot',
    'Eingefrorener Zustand eines Ordners zu einem Zeitpunkt. Schützt vor versehentlichem Löschen und Erpressungs-Software.',
  ),
  ('3-2-1-Regel', '3 Kopien deiner Daten, auf 2 verschiedenen Datenträgern, davon 1 außer Haus.'),
];

class GlossarScreen extends StatelessWidget {
  const GlossarScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Begriffe erklärt')),
    body: ListView(
      children: [for (final (begriff, text) in glossar) ListTile(title: Text(begriff), subtitle: Text(text))],
    ),
  );
}
