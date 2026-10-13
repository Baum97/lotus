import 'package:flutter/material.dart';

import '../main.dart';
import '../models.dart';
import '../net_check.dart';
import '../state.dart';

class WerkzeugeScreen extends StatelessWidget {
  const WerkzeugeScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Werkzeuge'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Verbindungstest'),
            Tab(text: 'Notizen'),
            Tab(text: 'Öffentliche IP'),
          ],
        ),
      ),
      body: const TabBarView(children: [Verbindungstest(), _Notizen(), _OeffentlicheIp()]),
    ),
  );
}

class Verbindungstest extends StatefulWidget {
  const Verbindungstest({super.key, this.pruefen = pruefeVerbindung});

  /// Austauschbar für Tests.
  final Future<TestErgebnis> Function(String host, int port) pruefen;

  @override
  State<Verbindungstest> createState() => _VerbindungstestState();
}

class _VerbindungstestState extends State<Verbindungstest> {
  final _host = TextEditingController();
  final _port = TextEditingController(text: '${Dienst.smb.port}');
  bool _laeuft = false;
  TestErgebnis? _ergebnis;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_host.text.isEmpty) {
      final state = StateScope.of(context);
      _host.text = state.notiz(Notiz.vpnIp.name).isNotEmpty
          ? state.notiz(Notiz.vpnIp.name)
          : state.notiz(Notiz.heimIp.name);
      if (state.profil?.geraet == Heimgeraet.synology) _port.text = '${Dienst.dsmHttps.port}';
    }
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  Future<void> _starten() async {
    final port = int.tryParse(_port.text.trim());
    if (_host.text.trim().isEmpty || port == null || port < 1 || port > 65535) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bitte Adresse und Port (1–65535) angeben.')));
      return;
    }
    setState(() {
      _laeuft = true;
      _ergebnis = null;
    });
    final e = await widget.pruefen(_host.text, port);
    if (mounted) {
      setState(() {
        _laeuft = false;
        _ergebnis = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final vorschlaege = [
      for (final n in [Notiz.heimIp, Notiz.vpnIp, Notiz.dyndns])
        if (state.notiz(n.name).isNotEmpty) state.notiz(n.name),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Prüft, ob das Handy einen Dienst auf dem Heimgerät erreicht. Teste einmal im Heim-WLAN und einmal '
          'über Mobilfunk mit eingeschaltetem VPN.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _host,
          decoration: const InputDecoration(
            labelText: 'Adresse des Heimgeräts',
            hintText: '192.168.178.20 oder 100.x.y.z',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          autocorrect: false,
        ),
        if (vorschlaege.isNotEmpty)
          Wrap(
            spacing: 8,
            children: [
              for (final v in vorschlaege) ActionChip(label: Text(v), onPressed: () => setState(() => _host.text = v)),
            ],
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _port,
          decoration: const InputDecoration(labelText: 'Port', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final d in Dienst.values)
              ChoiceChip(
                label: Text('${d.label} · ${d.port}'),
                selected: _port.text == '${d.port}',
                onSelected: (_) => setState(() => _port.text = '${d.port}'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _laeuft ? null : _starten,
          icon: _laeuft
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.play_arrow),
          label: const Text('Verbindung prüfen'),
        ),
        if (_ergebnis case final e?) ...[const SizedBox(height: 16), _ErgebnisKarte(e)],
      ],
    );
  }
}

class _ErgebnisKarte extends StatelessWidget {
  const _ErgebnisKarte(this.e);
  final TestErgebnis e;

  @override
  Widget build(BuildContext context) {
    final farben = Theme.of(context).colorScheme;
    final ok = e.ergebnis == Ergebnis.offen;
    return Card(
      color: ok ? farben.primaryContainer : farben.errorContainer,
      child: ListTile(
        leading: Icon(ok ? Icons.check_circle : Icons.error_outline),
        title: Text(ok ? 'Erreichbar (${e.dauer.inMilliseconds} ms)' : 'Nicht erreichbar'),
        subtitle: Text([e.erklaerung, if (e.detail case final d? when d.isNotEmpty) 'Technisch: $d'].join('\n')),
      ),
    );
  }
}

class _Notizen extends StatelessWidget {
  const _Notizen();

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Halte hier fest, was du während der Einrichtung notieren sollst. Keine Passwörter – '
          'die gehören in einen Passwortmanager.',
        ),
        const SizedBox(height: 16),
        for (final n in Notiz.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              initialValue: state.notiz(n.name),
              decoration: InputDecoration(labelText: n.label, hintText: n.hinweis, border: const OutlineInputBorder()),
              autocorrect: false,
              onChanged: (v) => state.setzeNotiz(n.name, v),
            ),
          ),
      ],
    );
  }
}

class _OeffentlicheIp extends StatefulWidget {
  const _OeffentlicheIp();

  @override
  State<_OeffentlicheIp> createState() => _OeffentlicheIpState();
}

class _OeffentlicheIpState extends State<_OeffentlicheIp> {
  final _routerIp = TextEditingController();
  String? _ip;
  String? _fehler;
  bool _laeuft = false;

  @override
  void dispose() {
    _routerIp.dispose();
    super.dispose();
  }

  Future<void> _abrufen() async {
    setState(() {
      _laeuft = true;
      _fehler = null;
    });
    try {
      final ip = await oeffentlicheIp();
      if (mounted) setState(() => _ip = ip);
    } on Object catch (e) {
      if (mounted) setState(() => _fehler = 'Abruf fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _laeuft = false);
    }
  }

  String? get _bewertung {
    final router = _routerIp.text.trim();
    if (router.isEmpty) return null;
    if (istNichtOeffentlich(router)) {
      return 'Die WAN-Adresse deines Routers ist keine öffentliche Adresse → CGNAT/DS-Lite. '
          'Tailscale verwenden oder beim Anbieter eine öffentliche IPv4 anfragen.';
    }
    if (_ip == null) return 'Jetzt die öffentliche IP abrufen, um sie zu vergleichen.';
    return router == _ip
        ? 'Router-Adresse und öffentliche Adresse stimmen überein → du hast eine öffentliche IPv4.'
        : 'Die Adressen weichen ab → wahrscheinlich CGNAT/DS-Lite. (Im Heim-WLAN abrufen, VPN aus!)';
  }

  @override
  Widget build(BuildContext context) {
    final bewertung = _bewertung;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Hilft herauszufinden, ob dein Anschluss eine eigene öffentliche IPv4-Adresse hat. '
          'Dafür fragt die App auf Knopfdruck den Dienst api.ipify.org nach der Adresse, mit der du im Internet '
          'erscheinst. Sonst nimmt die App keinen Kontakt zu fremden Servern auf.',
        ),
        const SizedBox(height: 8),
        const Text('Im Heim-WLAN und mit ausgeschaltetem VPN abrufen.'),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _laeuft ? null : _abrufen,
          icon: const Icon(Icons.public),
          label: const Text('Öffentliche IP abrufen'),
        ),
        if (_ip != null) ...[const SizedBox(height: 8), SelectableText('Öffentliche IP: $_ip')],
        if (_fehler != null) ...[const SizedBox(height: 8), Text(_fehler!)],
        const SizedBox(height: 16),
        TextField(
          controller: _routerIp,
          decoration: const InputDecoration(
            labelText: 'IPv4-Adresse aus dem Router (WAN/Internet)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        if (bewertung != null) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(padding: const EdgeInsets.all(12), child: Text(bewertung)),
          ),
        ],
      ],
    );
  }
}
