import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
import '../../data/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../../widgets/common.dart';

Future<void> showFeedbackSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => const FeedbackSheet(),
);

String get _platform => kIsWeb
    ? 'web'
    : defaultTargetPlatform == TargetPlatform.iOS
    ? 'ios'
    : 'android';

/// Fehler melden oder Ideen schicken – landet im Admin-Bereich.
class FeedbackSheet extends ConsumerStatefulWidget {
  const FeedbackSheet({super.key});

  @override
  ConsumerState<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends ConsumerState<FeedbackSheet> {
  final _message = TextEditingController();
  var _category = FeedbackCategory.bug;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context);
    if (_message.text.trim().isEmpty) {
      showMessage(context, l.feedbackEmpty);
      return;
    }
    await ref
        .read(apiProvider)
        .sendFeedback(_category, _message.text, appVersion: AppConfig.appVersion, platform: _platform);
    if (!mounted) return;
    Navigator.pop(context);
    showMessage(context, l.feedbackThanks);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    String label(FeedbackCategory c) => switch (c) {
      FeedbackCategory.bug => l.feedbackBug,
      FeedbackCategory.idea => l.feedbackIdea,
      FeedbackCategory.other => l.feedbackOther,
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.feedbackTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(l.feedbackHint, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final c in FeedbackCategory.values)
                ChoiceChip(
                  label: Text(label(c)),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _message,
            minLines: 4,
            maxLines: 8,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l.feedbackMessage, alignLabelWithHint: true),
          ),
          const SizedBox(height: 8),
          AsyncButton(label: l.feedbackSend, onPressed: _send),
        ],
      ),
    );
  }
}
