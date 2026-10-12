import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../../services/store.dart';
import '../../widgets/common.dart';
import '../support/support_screen.dart';

/// Konto löschen – mit der wichtigsten Frage: Hast du jemanden gefunden?
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  bool? _foundSomeone;
  final _feedback = TextEditingController();
  StreamSubscription<StoreEvent>? _events;

  @override
  void initState() {
    super.initState();
    _events = ref.read(storeProvider).events.listen(handleStoreEvent(context, ref));
  }

  @override
  void dispose() {
    _events?.cancel();
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final found = _foundSomeone!;
    if (found) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const LotusLogo(size: 64),
          content: Text(l.deleteCongrats, textAlign: TextAlign.center),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.ok))],
        ),
      );
    }
    await ref.read(apiProvider).deleteAccount(foundSomeone: found, feedback: _feedback.text);
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final success = ref.watch(storeProductsProvider).value?[StoreProducts.success];
    return Scaffold(
      appBar: AppBar(title: Text(l.deleteTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.deleteFoundQuestion, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          RadioGroup<bool>(
            groupValue: _foundSomeone,
            onChanged: (value) => setState(() => _foundSomeone = value),
            child: Column(children: [
              RadioListTile<bool>(contentPadding: EdgeInsets.zero, value: true, title: Text(l.deleteFoundYes)),
              RadioListTile<bool>(contentPadding: EdgeInsets.zero, value: false, title: Text(l.deleteFoundNo)),
            ]),
          ),
          if (_foundSomeone == true && success != null) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(l.successContributionTitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(l.successContributionText),
                  const SizedBox(height: 12),
                  AsyncButton(
                    outlined: true,
                    icon: Icons.volunteer_activism_outlined,
                    label: l.successContributionButton(success.price),
                    onPressed: () => ref.read(storeProvider).buy(success),
                  ),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _feedback,
            maxLines: 4,
            maxLength: 1000,
            decoration: InputDecoration(labelText: l.deleteFeedback),
          ),
          const SizedBox(height: 16),
          InfoBanner(text: l.deleteWarning, icon: Icons.warning_amber, warning: true),
          const SizedBox(height: 24),
          AsyncButton(label: l.deleteConfirm, onPressed: _foundSomeone == null ? null : _delete),
        ]),
      ),
    );
  }
}
