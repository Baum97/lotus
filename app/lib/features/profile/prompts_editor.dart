import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
import '../../data/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../../widgets/common.dart';

/// Liste der eigenen Prompt-Antworten (1–3) mit Hinzufügen, Bearbeiten und Löschen.
class PromptsEditor extends ConsumerWidget {
  const PromptsEditor({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, List<PromptAnswer> answers, [PromptAnswer? existing]) async {
    final catalog = await ref.read(promptCatalogProvider.future);
    if (!context.mounted) return;
    final used = answers.where((a) => a.id != existing?.id).map((a) => a.promptId).toSet();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _PromptSheet(
        catalog: catalog.where((p) => !used.contains(p.id)).toList(),
        existing: existing,
        position: existing?.position ?? answers.length,
      ),
    );
    if (saved == true) {
      ref.invalidate(ownPromptAnswersProvider);
      ref.invalidate(myStatusProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final answers = ref.watch(ownPromptAnswersProvider);
    final scheme = Theme.of(context).colorScheme;
    return answers.when(
      loading: () => const SizedBox(height: 200, child: LoadingView()),
      error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(ownPromptAnswersProvider)),
      data: (answers) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.promptsHint, style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        for (final answer in answers)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                title: Text(answer.promptText, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(answer.answer, style: Theme.of(context).textTheme.titleMedium),
                ),
                onTap: () => _edit(context, ref, answers, answer),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l.delete,
                  onPressed: () async {
                    try {
                      await ref.read(apiProvider).deletePromptAnswer(answer.id);
                      ref.invalidate(ownPromptAnswersProvider);
                      ref.invalidate(myStatusProvider);
                    } catch (e) {
                      if (context.mounted) showError(context, e);
                    }
                  },
                ),
              ),
            ),
          ),
        if (answers.length < AppConfig.maxPrompts)
          OutlinedButton.icon(
            onPressed: () => _edit(context, ref, answers),
            icon: const Icon(Icons.add),
            label: Text(l.addPrompt),
          ),
      ]),
    );
  }
}

class _PromptSheet extends ConsumerStatefulWidget {
  const _PromptSheet({required this.catalog, required this.existing, required this.position});

  final List<Prompt> catalog;
  final PromptAnswer? existing;
  final int position;

  @override
  ConsumerState<_PromptSheet> createState() => _PromptSheetState();
}

class _PromptSheetState extends ConsumerState<_PromptSheet> {
  late int? _promptId = widget.existing?.promptId;
  late final _answer = TextEditingController(text: widget.existing?.answer);

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        DropdownButtonFormField<int>(
          initialValue: _promptId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.choosePrompt),
          items: [
            for (final prompt in widget.catalog)
              DropdownMenuItem(value: prompt.id, child: Text(prompt.text, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (value) => setState(() => _promptId = value),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _answer,
          maxLines: 3,
          maxLength: 300,
          decoration: InputDecoration(labelText: l.answerLabel),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        AsyncButton(
          label: l.save,
          onPressed: _promptId == null || _answer.text.trim().isEmpty
              ? null
              : () async {
                  await ref.read(apiProvider).savePromptAnswer(
                        id: widget.existing?.id,
                        promptId: _promptId!,
                        answer: _answer.text,
                        position: widget.position,
                      );
                  if (context.mounted) Navigator.pop(context, true);
                },
        ),
      ]),
    );
  }
}
