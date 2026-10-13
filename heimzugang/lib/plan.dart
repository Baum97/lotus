import 'content/absichern.dart';
import 'content/freigabe.dart';
import 'content/sync.dart';
import 'content/vorbereitung.dart';
import 'content/zugang.dart';
import 'models.dart';

/// Welcher Zugangsweg passt zum Anschluss und Router?
///
/// - FRITZ!Box mit öffentlicher IPv4: WireGuard direkt im Router, ohne Drittanbieter.
/// - DS-Lite/CGNAT oder unbekannt: Tailscale, weil es keine eingehende Verbindung braucht.
/// - Anderer Router mit öffentlicher IPv4: ebenfalls Tailscale als einfachster Weg;
///   der eigene WireGuard-Server bleibt als Alternative wählbar.
Zugangsweg empfohlenerZugangsweg(Profil p) {
  if (p.anschluss == Anschluss.oeffentlicheIpv4 && p.router == HeimRouter.fritzbox) {
    return Zugangsweg.fritzWireguard;
  }
  return Zugangsweg.tailscale;
}

/// Wege, die mit dem Anschluss technisch funktionieren (für die Auswahl im Profil).
List<Zugangsweg> moeglicheZugangswege(Profil p) => [
  if (p.router == HeimRouter.fritzbox) Zugangsweg.fritzWireguard,
  Zugangsweg.tailscale,
  // Eigener WireGuard-Server braucht eingehende Verbindungen; die Anleitung deckt Linux ab.
  if (p.anschluss != Anschluss.dsLite && p.geraet == Heimgeraet.linux) Zugangsweg.eigenerWireguard,
];

Zugangsweg zugangswegFuer(Profil p) {
  final gewaehlt = p.zugangsweg;
  if (gewaehlt != null && moeglicheZugangswege(p).contains(gewaehlt)) return gewaehlt;
  return empfohlenerZugangsweg(p);
}

/// Baut die persönliche Schritt-für-Schritt-Anleitung.
List<Abschnitt> erstellePlan(Profil p) {
  final weg = zugangswegFuer(p);
  return [
    vorbereitung(p),
    anschlussPruefen(p),
    fernzugang(p, weg),
    freigabe(p),
    handyVerbinden(p, weg),
    if (p.ziele.contains(Ziel.fotos) || p.ziele.contains(Ziel.ordner)) synchronisieren(p, weg),
    testen(p, weg),
    absichern(p, weg),
  ];
}
