import 'package:flutter/material.dart';

import '../main.dart';
import '../models.dart';
import '../plan.dart';

class WillkommenScreen extends StatelessWidget {
  const WillkommenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            Icon(Icons.home_work_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('Heimzugang', style: t.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Deine Daten bleiben zu Hause – und du kommst trotzdem von überall dran. '
              'Diese App führt dich Schritt für Schritt dorthin:',
              style: t.bodyLarge,
            ),
            const SizedBox(height: 16),
            for (final (icon, text) in const [
              (Icons.vpn_lock_outlined, 'Sicherer Fernzugang per VPN – ohne offene Ports für deine Daten'),
              (Icons.folder_shared_outlined, 'Dateien vom NAS oder PC auf dem Handy öffnen'),
              (Icons.sync, 'Fotos und Ordner automatisch synchronisieren'),
              (Icons.network_check, 'Eingebauter Verbindungstest zur Fehlersuche'),
            ])
              ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon), title: Text(text)),
            const SizedBox(height: 8),
            Text(
              'Die App hat keinen Server und kein Konto. Deine Angaben werden nur auf diesem Handy gespeichert.',
              style: t.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EinrichtungScreen())),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Einrichtung starten'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fragt Schritt für Schritt ab, welche Geräte vorhanden sind, und schlägt einen Zugangsweg vor.
class EinrichtungScreen extends StatefulWidget {
  const EinrichtungScreen({super.key, this.vorher});

  /// Bestehendes Profil zum Ändern.
  final Profil? vorher;

  @override
  State<EinrichtungScreen> createState() => _EinrichtungScreenState();
}

class _EinrichtungScreenState extends State<EinrichtungScreen> {
  late Heimgeraet? _geraet = widget.vorher?.geraet;
  late Handy? _handy = widget.vorher?.handy;
  late HeimRouter? _router = widget.vorher?.router;
  late Anschluss? _anschluss = widget.vorher?.anschluss;
  late final Set<Ziel> _ziele = {
    ...widget.vorher?.ziele ?? {Ziel.dateien},
  };
  late Zugangsweg? _weg = widget.vorher?.zugangsweg;
  int _seite = 0;

  static const _seiten = 6;

  bool get _weiterMoeglich => switch (_seite) {
    0 => _geraet != null,
    1 => _handy != null,
    2 => _router != null,
    3 => _anschluss != null,
    4 => _ziele.isNotEmpty,
    _ => true,
  };

  Profil get _profil => Profil(
    geraet: _geraet!,
    handy: _handy!,
    router: _router!,
    anschluss: _anschluss!,
    ziele: _ziele,
    zugangsweg: _weg,
  );

  Future<void> _weiter() async {
    if (_seite < _seiten - 1) {
      setState(() => _seite++);
      return;
    }
    await StateScope.of(context).setzeProfil(_profil);
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Einrichtung ${_seite + 1}/$_seiten'),
        leading: _seite == 0 ? null : BackButton(onPressed: () => setState(() => _seite--)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_seite + 1) / _seiten),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(padding: const EdgeInsets.all(16), children: _inhalt()),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _weiterMoeglich ? _weiter : null,
                  child: Text(_seite == _seiten - 1 ? 'Anleitung erstellen' : 'Weiter'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _inhalt() => switch (_seite) {
    0 => _auswahl(
      'Auf welches Gerät zu Hause willst du zugreifen?',
      'Der Rechner oder das NAS, auf dem deine Daten liegen.',
      Heimgeraet.values,
      _geraet,
      (v) => _geraet = v,
      (v) => v.label,
    ),
    1 => _auswahl('Welches Handy hast du?', null, Handy.values, _handy, (v) => _handy = v, (v) => v.label),
    2 => _auswahl(
      'Welcher Router steht bei dir zu Hause?',
      'Die FRITZ!Box hat einen eingebauten WireGuard-VPN-Server (ab FRITZ!OS 7.50).',
      HeimRouter.values,
      _router,
      (v) => _router = v,
      (v) => v.label,
    ),
    3 => _auswahl(
      'Wie ist dein Internetanschluss?',
      'DSL hat meist eine öffentliche IPv4. Kabel und Glasfaser oft DS-Lite. '
          'Wenn du es nicht weißt: Die Anleitung zeigt dir, wie du es prüfst.',
      Anschluss.values,
      _anschluss,
      (v) => _anschluss = v,
      (v) => v.label,
    ),
    4 => [
      _frage('Was möchtest du erreichen?', 'Mehrfachauswahl möglich.'),
      for (final z in Ziel.values)
        CheckboxListTile(
          value: _ziele.contains(z),
          title: Text(z.label),
          onChanged: (an) => setState(() => an! ? _ziele.add(z) : _ziele.remove(z)),
        ),
    ],
    _ => _zusammenfassung(),
  };

  List<Widget> _zusammenfassung() {
    final p = _profil;
    final empfohlen = empfohlenerZugangsweg(p);
    final aktuell = zugangswegFuer(p);
    return [
      _frage('Dein Zugangsweg', 'Empfohlen für deine Angaben: ${empfohlen.label}.'),
      if (p.anschluss == Anschluss.dsLite)
        const _Hinweis(
          'Mit DS-Lite/CGNAT ist dein Heimnetz über IPv4 nicht direkt erreichbar. Tailscale baut die Verbindung '
          'von innen nach außen auf und funktioniert deshalb trotzdem.',
        ),
      if (p.anschluss == Anschluss.unbekannt)
        const _Hinweis(
          'Solange der Anschluss unbekannt ist, wird Tailscale empfohlen – es funktioniert mit jedem Anschluss. '
          'Du kannst das nach der Prüfung im Profil ändern.',
        ),
      for (final w in moeglicheZugangswege(p))
        Card(
          child: ListTile(
            leading: Icon(aktuell == w ? Icons.radio_button_checked : Icons.radio_button_unchecked),
            title: Text(w == empfohlen ? '${w.label} (empfohlen)' : w.label),
            subtitle: Text(w.kurz),
            onTap: () => setState(() => _weg = w == empfohlen ? null : w),
          ),
        ),
    ];
  }

  List<Widget> _auswahl<T>(
    String frage,
    String? hilfe,
    List<T> werte,
    T? aktuell,
    void Function(T) setzen,
    String Function(T) label,
  ) => [
    _frage(frage, hilfe),
    for (final w in werte)
      Card(
        child: ListTile(
          leading: Icon(aktuell == w ? Icons.radio_button_checked : Icons.radio_button_unchecked),
          title: Text(label(w)),
          onTap: () => setState(() {
            setzen(w);
            _weg = null; // Neue Angaben → Empfehlung neu berechnen
          }),
        ),
      ),
  ];

  Widget _frage(String frage, String? hilfe) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(frage, style: Theme.of(context).textTheme.titleLarge),
        if (hilfe != null) ...[const SizedBox(height: 4), Text(hilfe)],
      ],
    ),
  );
}

class _Hinweis extends StatelessWidget {
  const _Hinweis(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: Padding(padding: const EdgeInsets.all(12), child: Text(text)),
  );
}
