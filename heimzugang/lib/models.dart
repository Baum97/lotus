/// Datenmodell: Was der Nutzer zu Hause hat, und daraus abgeleitete Anleitungsschritte.
library;

enum Heimgeraet {
  synology('Synology-NAS'),
  qnap('QNAP-NAS'),
  windows('Windows-PC'),
  mac('Mac'),
  linux('Linux-Rechner / Raspberry Pi');

  const Heimgeraet(this.label);
  final String label;

  bool get istNas => this == synology || this == qnap;
}

enum Handy {
  android('Android'),
  ios('iPhone (iOS)');

  const Handy(this.label);
  final String label;
}

enum HeimRouter {
  fritzbox('FRITZ!Box'),
  anderer('Anderer Router');

  const HeimRouter(this.label);
  final String label;
}

/// Art des Internetanschlusses – entscheidet, ob das Heimnetz von außen direkt erreichbar ist.
enum Anschluss {
  oeffentlicheIpv4('Öffentliche IPv4-Adresse'),
  dsLite('DS-Lite / CGNAT (keine eigene IPv4)'),
  unbekannt('Weiß ich nicht');

  const Anschluss(this.label);
  final String label;
}

/// Wie das Handy unterwegs ins Heimnetz kommt.
enum Zugangsweg {
  fritzWireguard('WireGuard-VPN der FRITZ!Box', 'Eigener VPN-Server im Router, keine Fremdanbieter.'),
  tailscale('Tailscale (WireGuard-Mesh)', 'Funktioniert auch ohne öffentliche IPv4, Einrichtung in Minuten.'),
  eigenerWireguard(
    'Eigener WireGuard-Server',
    'WireGuard auf dem Heimgerät mit Portfreigabe – volle Kontrolle, mehr Handarbeit.',
  );

  const Zugangsweg(this.label, this.kurz);
  final String label;
  final String kurz;
}

enum Ziel {
  dateien('Unterwegs auf Dateien zugreifen'),
  fotos('Fotos vom Handy automatisch sichern'),
  ordner('Ordner zwischen Handy und Heimgerät synchronisieren');

  const Ziel(this.label);
  final String label;
}

class Profil {
  const Profil({
    required this.geraet,
    required this.handy,
    required this.router,
    required this.anschluss,
    required this.ziele,
    this.zugangsweg,
  });

  final Heimgeraet geraet;
  final Handy handy;
  final HeimRouter router;
  final Anschluss anschluss;
  final Set<Ziel> ziele;

  /// Vom Nutzer gewählter Weg; `null` bedeutet: Empfehlung verwenden.
  final Zugangsweg? zugangsweg;

  Profil copyWith({Zugangsweg? zugangsweg}) => Profil(
    geraet: geraet,
    handy: handy,
    router: router,
    anschluss: anschluss,
    ziele: ziele,
    zugangsweg: zugangsweg ?? this.zugangsweg,
  );

  Map<String, Object?> toJson() => {
    'geraet': geraet.name,
    'handy': handy.name,
    'router': router.name,
    'anschluss': anschluss.name,
    'ziele': [for (final z in ziele) z.name],
    'zugangsweg': zugangsweg?.name,
  };

  static Profil fromJson(Map<String, Object?> json) => Profil(
    geraet: Heimgeraet.values.byName(json['geraet'] as String),
    handy: Handy.values.byName(json['handy'] as String),
    router: HeimRouter.values.byName(json['router'] as String),
    anschluss: Anschluss.values.byName(json['anschluss'] as String),
    ziele: {for (final z in json['ziele'] as List) Ziel.values.byName(z as String)},
    zugangsweg: json['zugangsweg'] == null ? null : Zugangsweg.values.byName(json['zugangsweg'] as String),
  );
}

/// Ein abhakbarer Schritt der Anleitung.
class Schritt {
  const Schritt({
    required this.id,
    required this.titel,
    required this.text,
    this.befehle = const [],
    this.tipp,
    this.warnung,
    this.verbindungstest = false,
  });

  /// Stabil, damit der Fortschritt über App-Updates hinweg erhalten bleibt.
  final String id;
  final String titel;

  /// Einzelne Anweisungen, werden nummeriert angezeigt.
  final List<String> text;

  /// Befehle oder Adressen zum Kopieren.
  final List<String> befehle;
  final String? tipp;
  final String? warnung;

  /// Zeigt im Schritt einen Knopf zum eingebauten Verbindungstest.
  final bool verbindungstest;
}

class Abschnitt {
  const Abschnitt({required this.id, required this.titel, required this.beschreibung, required this.schritte});

  final String id;
  final String titel;
  final String beschreibung;
  final List<Schritt> schritte;
}
