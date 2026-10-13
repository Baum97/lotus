import 'package:flutter/material.dart';

import '../main.dart';
import '../models.dart';
import '../plan.dart';
import 'abschnitt.dart';
import 'einrichtung.dart';
import 'glossar.dart';
import 'werkzeuge.dart';

class UebersichtScreen extends StatelessWidget {
  const UebersichtScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = StateScope.of(context);
    final profil = state.profil!;
    final plan = state.plan;
    final gesamt = state.fortschritt();
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heimzugang'),
        actions: [
          IconButton(
            tooltip: 'Werkzeuge',
            icon: const Icon(Icons.network_check),
            onPressed: () => _oeffnen(context, const WerkzeugeScreen()),
          ),
          PopupMenuButton<String>(
            onSelected: (wahl) => switch (wahl) {
              'profil' => _oeffnen(context, EinrichtungScreen(vorher: profil)),
              'glossar' => _oeffnen(context, const GlossarScreen()),
              _ => _zuruecksetzen(context),
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profil', child: Text('Angaben ändern')),
              PopupMenuItem(value: 'glossar', child: Text('Begriffe erklärt')),
              PopupMenuItem(value: 'reset', child: Text('Alle Daten löschen')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${profil.geraet.label} ↔ ${profil.handy.label}', style: t.titleLarge),
          const SizedBox(height: 4),
          Text('Zugang: ${zugangswegFuer(profil).label}'),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: gesamt.gesamt == 0 ? 0 : gesamt.erledigt / gesamt.gesamt),
          const SizedBox(height: 4),
          Text('${gesamt.erledigt} von ${gesamt.gesamt} Schritten erledigt', style: t.bodySmall),
          const SizedBox(height: 16),
          for (final (i, a) in plan.indexed) _AbschnittKachel(nummer: i + 1, abschnitt: a),
        ],
      ),
    );
  }

  static void _oeffnen(BuildContext context, Widget seite) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => seite));

  static Future<void> _zuruecksetzen(BuildContext context) async {
    final state = StateScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alle Daten löschen?'),
        content: const Text('Angaben, Fortschritt und Notizen werden von diesem Handy entfernt.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (ok == true) await state.zuruecksetzen();
  }
}

class _AbschnittKachel extends StatelessWidget {
  const _AbschnittKachel({required this.nummer, required this.abschnitt});

  final int nummer;
  final Abschnitt abschnitt;

  @override
  Widget build(BuildContext context) {
    final f = StateScope.of(context).fortschritt(abschnitt);
    final fertig = f.erledigt == f.gesamt;
    final farben = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: fertig ? farben.primary : farben.surfaceContainerHighest,
          foregroundColor: fertig ? farben.onPrimary : farben.onSurface,
          child: fertig ? const Icon(Icons.check) : Text('$nummer'),
        ),
        title: Text(abschnitt.titel),
        subtitle: Text('${f.erledigt}/${f.gesamt} · ${abschnitt.beschreibung}', maxLines: 2),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AbschnittScreen(nummer: nummer, abschnittId: abschnitt.id),
          ),
        ),
      ),
    );
  }
}
