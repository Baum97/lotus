import 'package:flutter_test/flutter_test.dart';
import 'package:heimzugang/models.dart';
import 'package:heimzugang/plan.dart';

Profil profil({
  Heimgeraet geraet = Heimgeraet.synology,
  Handy handy = Handy.android,
  HeimRouter router = HeimRouter.fritzbox,
  Anschluss anschluss = Anschluss.oeffentlicheIpv4,
  Set<Ziel> ziele = const {Ziel.dateien},
  Zugangsweg? zugangsweg,
}) => Profil(geraet: geraet, handy: handy, router: router, anschluss: anschluss, ziele: ziele, zugangsweg: zugangsweg);

/// Alle Kombinationen, die der Assistent erzeugen kann.
Iterable<Profil> alleProfile() sync* {
  for (final g in Heimgeraet.values) {
    for (final h in Handy.values) {
      for (final r in HeimRouter.values) {
        for (final a in Anschluss.values) {
          for (final w in [null, ...Zugangsweg.values]) {
            yield profil(geraet: g, handy: h, router: r, anschluss: a, ziele: Ziel.values.toSet(), zugangsweg: w);
          }
        }
      }
    }
  }
}

void main() {
  group('Empfehlung', () {
    test('FRITZ!Box mit öffentlicher IPv4 → WireGuard der FRITZ!Box', () {
      expect(empfohlenerZugangsweg(profil()), Zugangsweg.fritzWireguard);
    });

    test('DS-Lite → Tailscale, FRITZ!Box-VPN bleibt wählbar, eigener Server nicht', () {
      final p = profil(geraet: Heimgeraet.linux, anschluss: Anschluss.dsLite);
      expect(empfohlenerZugangsweg(p), Zugangsweg.tailscale);
      expect(moeglicheZugangswege(p), [Zugangsweg.fritzWireguard, Zugangsweg.tailscale]);
    });

    test('Unbekannter Anschluss → Tailscale', () {
      expect(empfohlenerZugangsweg(profil(anschluss: Anschluss.unbekannt)), Zugangsweg.tailscale);
    });

    test('Anderer Router: kein FRITZ!Box-VPN, eigener WireGuard nur für Linux', () {
      expect(moeglicheZugangswege(profil(router: HeimRouter.anderer)), [Zugangsweg.tailscale]);
      expect(moeglicheZugangswege(profil(router: HeimRouter.anderer, geraet: Heimgeraet.linux)), [
        Zugangsweg.tailscale,
        Zugangsweg.eigenerWireguard,
      ]);
    });

    test('Unpassende Wahl fällt auf die Empfehlung zurück', () {
      final p = profil(router: HeimRouter.anderer, zugangsweg: Zugangsweg.fritzWireguard);
      expect(zugangswegFuer(p), Zugangsweg.tailscale);
    });

    test('Passende Wahl wird übernommen', () {
      expect(zugangswegFuer(profil(zugangsweg: Zugangsweg.tailscale)), Zugangsweg.tailscale);
    });
  });

  group('Plan', () {
    test('Jede Kombination ergibt einen vollständigen Plan mit eindeutigen Schritt-IDs', () {
      var anzahl = 0;
      for (final p in alleProfile()) {
        final plan = erstellePlan(p);
        final ids = [for (final a in plan) ...a.schritte.map((s) => s.id)];
        expect(ids.toSet().length, ids.length, reason: 'doppelte IDs bei ${p.toJson()}');
        for (final a in plan) {
          expect(a.schritte, isNotEmpty, reason: '${a.id} leer bei ${p.toJson()}');
          for (final s in a.schritte) {
            expect(s.text.where((t) => t.trim().isEmpty), isEmpty, reason: s.id);
          }
        }
        anzahl++;
      }
      expect(anzahl, greaterThan(100));
    });

    test('Abschnitt Synchronisieren nur bei passenden Zielen', () {
      expect(erstellePlan(profil()).map((a) => a.id), isNot(contains('sync')));
      expect(erstellePlan(profil(ziele: {Ziel.fotos})).map((a) => a.id), contains('sync'));
    });

    test('Fernzugang passt zum Weg', () {
      String erster(Profil p) => erstellePlan(p).firstWhere((a) => a.id == 'fernzugang').schritte.first.id;
      expect(erster(profil()), 'fritz-myfritz');
      expect(erster(profil(anschluss: Anschluss.dsLite)), 'ts-konto');
      expect(erster(profil(geraet: Heimgeraet.linux, zugangsweg: Zugangsweg.eigenerWireguard)), 'wg-dyndns');
    });

    test('Ohne eigenen WireGuard-Server wird keine Portfreigabe verlangt', () {
      final schritte = [for (final a in erstellePlan(profil(anschluss: Anschluss.dsLite))) ...a.schritte];
      expect(schritte.map((s) => s.id), isNot(contains('wg-portfreigabe')));
    });
  });

  test('Profil übersteht JSON-Rundreise', () {
    final p = profil(
      geraet: Heimgeraet.mac,
      handy: Handy.ios,
      ziele: {Ziel.ordner, Ziel.fotos},
      zugangsweg: Zugangsweg.tailscale,
    );
    final zurueck = Profil.fromJson(p.toJson());
    expect(zurueck.toJson(), p.toJson());
  });
}
