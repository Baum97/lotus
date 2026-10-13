import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heimzugang/main.dart';
import 'package:heimzugang/net_check.dart';
import 'package:heimzugang/screens/werkzeuge.dart';
import 'package:heimzugang/state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> neuerState([Map<String, Object> werte = const {}]) async {
  SharedPreferences.setMockInitialValues(werte);
  return AppState(await SharedPreferences.getInstance());
}

void main() {
  testWidgets('Einrichtung führt zur persönlichen Anleitung', (tester) async {
    final state = await neuerState();
    await tester.pumpWidget(HeimzugangApp(state: state));

    await tester.scrollUntilVisible(find.text('Einrichtung starten'), 100);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Einrichtung starten'));
    await tester.pumpAndSettle();

    for (final antwort in ['Synology-NAS', 'Android', 'FRITZ!Box', 'DS-Lite / CGNAT (keine eigene IPv4)']) {
      await tester.tap(find.text(antwort));
      await tester.pump();
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
    }
    // Ziele: „Dateien“ ist vorausgewählt
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    expect(find.text('Tailscale (WireGuard-Mesh) (empfohlen)'), findsOneWidget);
    await tester.tap(find.text('Anleitung erstellen'));
    await tester.pumpAndSettle();

    expect(find.text('Synology-NAS ↔ Android'), findsOneWidget);
    expect(find.text('Fernzugang einrichten'), findsOneWidget);
    expect(state.profil, isNotNull);
  });

  testWidgets('Schritt abhaken erhöht den Fortschritt und wird gespeichert', (tester) async {
    final state = await neuerState({
      'profil': '{"geraet":"linux","handy":"ios","router":"anderer","anschluss":"oeffentlicheIpv4","ziele":["dateien"],"zugangsweg":null}',
    });
    await tester.pumpWidget(HeimzugangApp(state: state));
    expect(find.textContaining('0 von'), findsOneWidget);

    await tester.tap(find.text('Vorbereitung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erledigt').first);
    await tester.pumpAndSettle();

    expect(state.istErledigt('vorb-updates'), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('erledigt'), contains('vorb-updates'));
  });

  testWidgets('Verbindungstest zeigt das Ergebnis', (tester) async {
    final state = await neuerState();
    String? gefragt;
    await tester.pumpWidget(
      StateScope(
        state: state,
        child: MaterialApp(
          home: Scaffold(
            body: Verbindungstest(
              pruefen: (host, port) async {
                gefragt = '$host:$port';
                return const TestErgebnis(Ergebnis.abgelehnt, Duration(milliseconds: 3));
              },
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '192.168.178.20');
    await tester.tap(find.text('Verbindung prüfen'));
    await tester.pumpAndSettle();

    expect(gefragt, '192.168.178.20:445');
    expect(find.text('Nicht erreichbar'), findsOneWidget);
  });
}
