import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../legal/consent.dart';
import '../../legal/impressum_screen.dart';
import '../../providers.dart';
import '../../widgets/common.dart';
import '../me/edit_profile_screen.dart';

/// Einwilligung einsehen/widerrufen, Datenauskunft herunterladen, Impressum.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final data = await ref.read(apiProvider).exportMyData();
    final bytes = Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(data)));
    final date = DateTime.now().toIso8601String().substring(0, 10);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'application/json', name: 'lotus-daten-$date.json')],
        fileNameOverrides: ['lotus-daten-$date.json'],
        downloadFallbackEnabled: true,
      ),
    );
    if (context.mounted) showMessage(context, l.privacyExportDone);
  }

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.privacyWithdrawTitle),
        content: Text(l.privacyWithdrawBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.privacyWithdraw)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(apiProvider).withdrawConsent(MatchingConsent.kind);
      ref.invalidate(matchingConsentProvider);
      ref.invalidate(ownPreferencesProvider);
      if (context.mounted) showMessage(context, l.privacyWithdrawn);
      // Ohne Suchangaben führt die App zurück ins Onboarding (AuthGate)
      ref.invalidate(myStatusProvider);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final consent = ref.watch(matchingConsentProvider);
    final materialL = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.privacyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l.consentTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(l.consentText),
          const SizedBox(height: 12),
          consent.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(matchingConsentProvider)),
            data: (c) => c == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InfoBanner(text: l.privacyConsentMissing, warning: true),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: (_) => const EditProfileScreen(preferencesOnly: true)),
                        ),
                        child: Text(l.privacyGiveConsent),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InfoBanner(
                        icon: Icons.check_circle_outline,
                        text: l.privacyConsentGiven(materialL.formatMediumDate(c.grantedAt), c.version),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: () => _withdraw(context, ref), child: Text(l.privacyWithdraw)),
                    ],
                  ),
          ),
          const Divider(height: 40),
          Text(l.privacyExport, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(l.privacyExportHint),
          const SizedBox(height: 12),
          AsyncButton(
            outlined: true,
            icon: Icons.download_outlined,
            label: l.privacyExport,
            onPressed: () => _export(context, ref),
          ),
          const Divider(height: 40),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
            title: Text(l.imprint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ImpressumScreen())),
          ),
        ],
      ),
    );
  }
}
