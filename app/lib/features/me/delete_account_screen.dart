import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../../widgets/common.dart';

/// Konto löschen – mit der wichtigsten Frage: Hast du jemanden gefunden?
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  bool? _foundSomeone;
  final _feedback = TextEditingController();

  @override
  void dispose() {
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
