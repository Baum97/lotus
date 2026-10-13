import 'dart:convert';
import 'dart:io';

/// Bekannte Dienste für den Verbindungstest.
enum Dienst {
  smb('Dateifreigabe (SMB)', 445),
  dsmHttps('Synology DSM (HTTPS)', 5001),
  qnapHttps('QNAP QTS (HTTPS)', 443),
  syncthing('Syncthing', 22000),
  ssh('SSH', 22),
  fritzbox('Router-Oberfläche (HTTP)', 80);

  const Dienst(this.label, this.port);
  final String label;
  final int port;
}

enum Ergebnis { offen, abgelehnt, zeitueberschreitung, adresseUnbekannt, keinNetz }

class TestErgebnis {
  const TestErgebnis(this.ergebnis, this.dauer, [this.detail]);
  final Ergebnis ergebnis;
  final Duration dauer;
  final String? detail;

  String get erklaerung => switch (ergebnis) {
    Ergebnis.offen => 'Erreichbar. Das Heimgerät antwortet auf diesem Port.',
    Ergebnis.abgelehnt =>
      'Das Gerät ist erreichbar, aber auf diesem Port läuft kein Dienst (oder eine Firewall lehnt ab). '
          'Freigabe/Dienst auf dem Heimgerät prüfen.',
    Ergebnis.zeitueberschreitung =>
      'Keine Antwort. Ist das VPN verbunden? Stimmt die Adresse? Ist das Heimgerät eingeschaltet?',
    Ergebnis.adresseUnbekannt =>
      'Der Name konnte nicht aufgelöst werden. Tippfehler? Bei Tailscale-Namen muss das VPN aktiv sein.',
    Ergebnis.keinNetz => 'Das Handy hat gerade keine Netzwerkverbindung.',
  };
}

/// Prüft per TCP-Verbindungsaufbau, ob [host]:[port] erreichbar ist. Es werden keine Daten gesendet.
Future<TestErgebnis> pruefeVerbindung(String host, int port, {Duration timeout = const Duration(seconds: 5)}) async {
  final uhr = Stopwatch()..start();
  try {
    final socket = await Socket.connect(host.trim(), port, timeout: timeout);
    socket.destroy();
    return TestErgebnis(Ergebnis.offen, uhr.elapsed);
  } on SocketException catch (e) {
    return TestErgebnis(_einordnen(e), uhr.elapsed, e.osError?.message ?? e.message);
  }
}

Ergebnis _einordnen(SocketException e) {
  final text = '${e.message} ${e.osError?.message ?? ''}'.toLowerCase();
  final code = e.osError?.errorCode;
  final namensfehler = text.contains('lookup') || (text.contains('host') && text.contains('not known'));
  if (namensfehler) return Ergebnis.adresseUnbekannt;
  if (text.contains('refused') || code == 111 || code == 61 || code == 10061) return Ergebnis.abgelehnt;
  if (text.contains('network is unreachable') || code == 101 || code == 51) return Ergebnis.keinNetz;
  // Zeitüberschreitung und alles Unklare: Es kam keine verwertbare Antwort zurück.
  return Ergebnis.zeitueberschreitung;
}

/// Fragt die öffentliche IP-Adresse bei api.ipify.org ab. Nur auf ausdrücklichen Wunsch des Nutzers.
Future<String> oeffentlicheIp({HttpClient? client}) async {
  final c = client ?? HttpClient();
  c.connectionTimeout = const Duration(seconds: 8);
  try {
    final req = await c.getUrl(Uri.parse('https://api.ipify.org'));
    final res = await req.close();
    if (res.statusCode != 200) throw HttpException('Status ${res.statusCode}');
    return (await res.transform(utf8.decoder).join()).trim();
  } finally {
    c.close();
  }
}

/// Liegt eine IPv4-Adresse in einem privaten oder CGNAT-Bereich?
bool istNichtOeffentlich(String ipv4) {
  final teile = ipv4.trim().split('.').map(int.tryParse).toList();
  if (teile.length != 4 || teile.any((t) => t == null || t < 0 || t > 255)) return false;
  final [a, b, _, _] = teile.cast<int>();
  return a == 10 ||
      (a == 100 && b >= 64 && b <= 127) ||
      (a == 172 && b >= 16 && b <= 31) ||
      (a == 192 && b == 168) ||
      a == 127;
}
