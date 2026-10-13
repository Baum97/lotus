import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models.dart';
import 'werkzeuge.dart';

class AbschnittScreen extends StatelessWidget {
  const AbschnittScreen({super.key, required this.nummer, required this.abschnittId});

  final int nummer;

  /// Per ID, damit die Seite nach einer Profiländerung den aktuellen Inhalt zeigt.
  final String abschnittId;

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final abschnitt = state.plan.where((a) => a.id == abschnittId).firstOrNull;
    if (abschnitt == null) return Scaffold(appBar: AppBar());
    final offen = abschnitt.schritte.indexWhere((s) => !state.istErledigt(s.id));
    return Scaffold(
      appBar: AppBar(title: Text('$nummer. ${abschnitt.titel}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(abschnitt.beschreibung)),
          for (final (i, s) in abschnitt.schritte.indexed)
            SchrittKarte(key: ValueKey(s.id), schritt: s, nummer: i + 1, aufgeklappt: i == offen),
          if (offen == -1)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check),
                label: const Text('Abschnitt erledigt – zurück zur Übersicht'),
              ),
            ),
        ],
      ),
    );
  }
}

class SchrittKarte extends StatelessWidget {
  const SchrittKarte({super.key, required this.schritt, required this.nummer, this.aufgeklappt = false});

  final Schritt schritt;
  final int nummer;
  final bool aufgeklappt;

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final erledigt = state.istErledigt(schritt.id);
    final farben = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: aufgeklappt,
        leading: Checkbox(value: erledigt, onChanged: (v) => state.setzeErledigt(schritt.id, v ?? false)),
        title: Text(
          '$nummer. ${schritt.titel}',
          style: erledigt ? TextStyle(color: farben.onSurfaceVariant, decoration: TextDecoration.lineThrough) : null,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, zeile) in schritt.text.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text('${i + 1}.', style: TextStyle(color: farben.primary)),
                  ),
                  Expanded(child: Text(zeile)),
                ],
              ),
            ),
          for (final befehl in schritt.befehle) _Befehl(befehl),
          if (schritt.tipp case final tipp?) _Hinweisbox(Icons.lightbulb_outline, tipp, farben.secondaryContainer),
          if (schritt.warnung case final warnung?) _Hinweisbox(Icons.warning_amber, warnung, farben.errorContainer),
          if (schritt.verbindungstest)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WerkzeugeScreen())),
                icon: const Icon(Icons.network_check),
                label: const Text('Verbindungstest öffnen'),
              ),
            ),
          if (!erledigt)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => state.setzeErledigt(schritt.id, true),
                icon: const Icon(Icons.check),
                label: const Text('Erledigt'),
              ),
            ),
        ],
      ),
    );
  }
}

class _Befehl extends StatelessWidget {
  const _Befehl(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final farben = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: farben.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: SelectableText(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
            ),
          ),
          IconButton(
            tooltip: 'Kopieren',
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kopiert')));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _Hinweisbox extends StatelessWidget {
  const _Hinweisbox(this.icon, this.text, this.farbe);
  final IconData icon;
  final String text;
  final Color farbe;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: farbe, borderRadius: BorderRadius.circular(8)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
