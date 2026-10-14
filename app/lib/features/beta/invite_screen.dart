import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../../widgets/common.dart';

/// Vor dem Onboarding, solange die Beta nur mit Einladung offen ist:
/// Code einlösen oder auf die Warteliste.
class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key, required this.access});

  final AccessStatus access;

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final _code = TextEditingController();
  final _city = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final l = AppLocalizations.of(context);
    if (_code.text.trim().isEmpty) {
      showMessage(context, l.inviteCodeMissing);
      return;
    }
    await ref.read(apiProvider).redeemInvite(_code.text);
    ref.invalidate(accessStatusProvider);
  }

  Future<void> _joinWaitlist() async {
    final l = AppLocalizations.of(context);
    if (_city.text.trim().length < 2) {
      showMessage(context, l.waitlistCityMissing);
      return;
    }
    await ref.read(apiProvider).joinWaitlist(_city.text);
    ref.invalidate(accessStatusProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: l.retry,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(accessStatusProvider),
          ),
          TextButton(onPressed: () => ref.read(apiProvider).signOut(), child: Text(l.signOut)),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: LotusLogo(size: 64)),
                  const SizedBox(height: 24),
                  Text(l.inviteTitle, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(
                    l.inviteBody,
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    decoration: InputDecoration(labelText: l.inviteCodeLabel, hintText: 'K7M2-PQ4X'),
                    onSubmitted: (_) => _redeem().catchError((Object e) {
                      if (context.mounted) showError(context, e);
                    }),
                  ),
                  const SizedBox(height: 12),
                  AsyncButton(label: l.inviteRedeem, onPressed: _redeem),
                  const SizedBox(height: 40),
                  Text(l.waitlistTitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (widget.access.onWaitlist)
                    InfoBanner(text: l.waitlistJoined, icon: Icons.hourglass_empty)
                  else ...[
                    Text(l.waitlistBody, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _city,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(labelText: l.cityLabel),
                    ),
                    const SizedBox(height: 12),
                    AsyncButton(outlined: true, label: l.waitlistJoin, onPressed: _joinWaitlist),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
