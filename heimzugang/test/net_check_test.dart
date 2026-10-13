import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heimzugang/net_check.dart';

void main() {
  test('Offener Port wird erkannt', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((s) => s.destroy());

    final e = await pruefeVerbindung('127.0.0.1', server.port);
    expect(e.ergebnis, Ergebnis.offen);
  });

  test('Geschlossener Port wird als abgelehnt erkannt', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    await server.close();

    final e = await pruefeVerbindung('127.0.0.1', port);
    expect(e.ergebnis, Ergebnis.abgelehnt);
  });

  test('Private und CGNAT-Adressen', () {
    for (final ip in ['10.0.0.1', '100.64.0.1', '100.127.255.255', '172.16.5.4', '172.31.0.1', '192.168.178.1']) {
      expect(istNichtOeffentlich(ip), isTrue, reason: ip);
    }
    for (final ip in ['8.8.8.8', '100.63.0.1', '100.128.0.1', '172.32.0.1', '193.168.0.1', 'kein.ip', '1.2.3']) {
      expect(istNichtOeffentlich(ip), isFalse, reason: ip);
    }
  });
}
