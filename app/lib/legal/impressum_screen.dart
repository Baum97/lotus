import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../widgets/common.dart';
import 'legal_info.dart';

/// Impressum – erreichbar vor der Anmeldung (Login-Screen) und im Profil.
class ImpressumScreen extends StatelessWidget {
  const ImpressumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 6),
          child: Text(text, style: theme.textTheme.titleMedium),
        );
    const address = '${LegalInfo.name}\n${LegalInfo.street}\n${LegalInfo.postalCodeCity}\n${LegalInfo.country}';

    return Scaffold(
      appBar: AppBar(title: Text(l.imprint)),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            if (!LegalInfo.isComplete) InfoBanner(text: l.imprintIncomplete, warning: true),
            heading(l.imprintProvider),
            const Text(address),
            heading(l.imprintContact),
            Text('${l.imprintPhone}: ${LegalInfo.phone}\n${l.imprintEmail}: ${LegalInfo.email}'),
            if (LegalInfo.vatId.isNotEmpty) ...[heading(l.imprintVat), const Text(LegalInfo.vatId)],
            if (LegalInfo.economicId.isNotEmpty) ...[heading(l.imprintEconomicId), const Text(LegalInfo.economicId)],
            heading(l.imprintResponsible),
            const Text(address),
            heading(l.imprintDsa),
            Text(l.imprintDsaText(LegalInfo.email)),
            heading(l.imprintDispute),
            Text(l.imprintDisputeText),
          ],
        ),
      ),
    );
  }
}
