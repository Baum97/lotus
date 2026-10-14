import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../../widgets/common.dart';

final _metricsProvider = FutureProvider.autoDispose.family<BetaMetrics, int>(
  (ref, days) => ref.watch(apiProvider).adminMetrics(days: days),
);
final _invitesProvider = FutureProvider.autoDispose((ref) => ref.watch(apiProvider).adminInvites());
final _waitlistProvider = FutureProvider.autoDispose((ref) => ref.watch(apiProvider).adminWaitlist());
final _feedbackProvider = FutureProvider.autoDispose((ref) => ref.watch(apiProvider).adminFeedback());

String _genderLabel(AppLocalizations l, Gender g) => switch (g) {
  Gender.woman => l.genderWoman,
  Gender.man => l.genderMan,
  Gender.diverse => l.genderDiverse,
};

String _percent(int part, int whole) => whole == 0 ? '–' : '${(100 * part / whole).round()} %';

// --- Kennzahlen ----------------------------------------------------------------

/// Kennzahlen der Beta: Wachstum, Gleichgewicht, Like→Match→Gespräch, offene Aufgaben.
class MetricsTab extends ConsumerStatefulWidget {
  const MetricsTab({super.key});

  @override
  ConsumerState<MetricsTab> createState() => _MetricsTabState();
}

class _MetricsTabState extends ConsumerState<MetricsTab> {
  var _days = 30;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ref
        .watch(_metricsProvider(_days))
        .when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(_metricsProvider(_days))),
          data: (m) => RefreshIndicator(
            onRefresh: () => ref.refresh(_metricsProvider(_days).future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<int>(
                  segments: [
                    for (final d in const [7, 30, 90]) ButtonSegment(value: d, label: Text(l.metricsDays(d))),
                  ],
                  selected: {_days},
                  onSelectionChanged: (s) => setState(() => _days = s.first),
                ),
                _Section(
                  title: l.metricsUsers,
                  children: [
                    _Stat(value: m.profiles, label: l.metricsProfiles),
                    _Stat(value: m.newInPeriod, label: l.metricsNew),
                    _Stat(value: m.active7d, label: l.metricsActive7d, note: _percent(m.active7d, m.profiles)),
                    _Stat(value: m.discoverable, label: l.metricsDiscoverable),
                    _Stat(value: m.verified, label: l.metricsVerified, note: _percent(m.verified, m.profiles)),
                    _Stat(value: m.withPlus, label: l.metricsPlus),
                  ],
                ),
                _FunnelSection(metrics: m),
                _Section(
                  title: l.metricsLimits,
                  children: [
                    _Stat(
                      value: m.daysUsedUp,
                      label: l.metricsBudgetUsedUp,
                      note: _percent(m.daysUsedUp, m.daysWithLikes),
                    ),
                    _Stat(value: m.undos, label: l.metricsUndos),
                    _Stat(value: m.closedStale, label: l.metricsClosedStale),
                    _Stat(value: m.closedEnded, label: l.metricsClosedEnded),
                    _Stat(value: m.closedBlocked, label: l.metricsClosedBlocked),
                  ],
                ),
                _BalanceSection(rows: m.balance),
                _Section(
                  title: l.metricsOutcome,
                  children: [
                    _Stat(value: m.deletions, label: l.metricsDeletions),
                    _Stat(value: m.foundSomeone, label: l.metricsFoundSomeone, highlight: true),
                  ],
                ),
                _Section(
                  title: l.metricsOpen,
                  children: [
                    _Stat(value: m.openVerifications, label: l.adminVerifications),
                    _Stat(value: m.openReports, label: l.adminReports),
                    _Stat(value: m.openFeedback, label: l.adminFeedback),
                    _Stat(value: m.waitlist, label: l.adminWaitlist),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l.metricsPrivacyNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
              ],
            ),
          ),
        );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          // Kacheln füllen die Zeile: 2 Spalten auf dem Handy, mehr auf breiten Bildschirmen
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 12.0;
              final columns = ((constraints.maxWidth + gap) ~/ (160 + gap)).clamp(2, 6);
              final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [for (final child in children) SizedBox(width: width, child: child)],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Eine Zahl mit Beschriftung; `note` z. B. als Anteil.
class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.note, this.highlight = false});

  final int value;
  final String label;
  final String? note;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? scheme.primaryContainer : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          if (note != null) Text(note!, style: theme.textTheme.labelSmall?.copyWith(color: scheme.primary)),
        ],
      ),
    );
  }
}

/// Like → Match → Gespräch → längeres Gespräch, als Balken relativ zu den Likes.
class _FunnelSection extends StatelessWidget {
  const _FunnelSection({required this.metrics});

  final BetaMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = metrics;
    final steps = [
      (l.metricsLikes, m.likes, null),
      (l.metricsLikesWithComment, m.likesWithComment, _percent(m.likesWithComment, m.likes)),
      (l.metricsMatches, m.matches, _percent(m.matches, m.likes)),
      (l.metricsConversations, m.conversations, _percent(m.conversations, m.matches)),
      (l.metricsDeepConversations, m.deepConversations, _percent(m.deepConversations, m.conversations)),
    ];
    final max = m.likes == 0 ? 1 : m.likes;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.metricsFunnel, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l.metricsFunnelHint, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 12),
          for (final (label, value, share) in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(label)),
                      Text('$value', style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
                      if (share != null)
                        SizedBox(
                          width: 56,
                          child: Text(
                            share,
                            textAlign: TextAlign.end,
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value / max,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.surfaceContainer,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Wer sucht wen – je Region. Zeigt, wo gezielt eingeladen werden sollte.
class _BalanceSection extends StatelessWidget {
  const _BalanceSection({required this.rows});

  final List<BalanceRow> rows;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final regions = {for (final r in rows) r.region};
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.metricsBalance, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l.metricsBalanceHint, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
          if (rows.isEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(l.adminNothing)),
          for (final region in regions) ...[
            const SizedBox(height: 12),
            Text(region, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
            for (final r in rows.where((r) => r.region == region))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.metricsSeeks(_genderLabel(l, r.gender), r.seeking.map((g) => _genderLabel(l, g)).join(', ')),
                      ),
                    ),
                    Text('${r.count}', style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// --- Einladungen & Warteliste -----------------------------------------------------

class InvitesTab extends ConsumerWidget {
  const InvitesTab({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final codes = await showDialog<List<String>>(context: context, builder: (_) => const _CreateInvitesDialog());
    if (codes == null || !context.mounted) return;
    ref.invalidate(_invitesProvider);
    await showDialog<void>(
      context: context,
      builder: (_) => _NewCodesDialog(codes: codes),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final required = ref.watch(accessStatusProvider).value?.required;
    final waitlist = ref.watch(_waitlistProvider);
    final invites = ref.watch(_invitesProvider);
    final now = DateTime.now();
    final date = MaterialLocalizations.of(context).formatMediumDate;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(_waitlistProvider);
        ref.invalidate(_invitesProvider);
        await ref.read(_invitesProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (required != null)
            InfoBanner(
              text: required ? l.invitesRequiredOn : l.invitesRequiredOff,
              icon: required ? Icons.lock_outline : Icons.lock_open,
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _create(context, ref),
            icon: const Icon(Icons.add),
            label: Text(l.invitesCreate),
          ),
          const SizedBox(height: 24),
          Text(l.adminWaitlist, style: theme.textTheme.titleMedium),
          ...waitlist.when(
            loading: () => [const Padding(padding: EdgeInsets.all(16), child: LoadingView())],
            error: (e, _) => [Text(errorText(context, e))],
            data: (entries) => entries.isEmpty
                ? [Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(l.waitlistEmpty))]
                : [
                    for (final w in entries)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(w.email),
                        subtitle: Text('${w.city} · ${date(w.createdAt)}'),
                        trailing: AsyncButton(
                          outlined: true,
                          label: l.waitlistAdmit,
                          onPressed: () async {
                            await ref.read(apiProvider).adminAdmitFromWaitlist(w.userId);
                            ref.invalidate(_waitlistProvider);
                          },
                        ),
                      ),
                  ],
          ),
          const SizedBox(height: 24),
          Text(l.invitesCodes, style: theme.textTheme.titleMedium),
          ...invites.when(
            loading: () => [const Padding(padding: EdgeInsets.all(16), child: LoadingView())],
            error: (e, _) => [Text(errorText(context, e))],
            data: (codes) => codes.isEmpty
                ? [Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(l.invitesNone))]
                : [
                    for (final c in codes)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        enabled: !c.usedUp && !c.isExpired(now),
                        title: Text(
                          c.formatted,
                          style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          [
                            l.invitesUses(c.uses, c.maxUses),
                            if (c.region != null) c.region!,
                            if (c.note != null) c.note!,
                            if (c.expiresAt != null)
                              c.isExpired(now) ? l.invitesExpired : l.invitesValidUntil(date(c.expiresAt!)),
                          ].join(' · '),
                        ),
                        trailing: IconButton(
                          tooltip: l.copy,
                          icon: const Icon(Icons.copy),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: c.formatted));
                            if (context.mounted) showMessage(context, l.copied);
                          },
                        ),
                      ),
                  ],
          ),
        ],
      ),
    );
  }
}

class _CreateInvitesDialog extends ConsumerStatefulWidget {
  const _CreateInvitesDialog();

  @override
  ConsumerState<_CreateInvitesDialog> createState() => _CreateInvitesDialogState();
}

class _CreateInvitesDialogState extends ConsumerState<_CreateInvitesDialog> {
  final _note = TextEditingController();
  var _count = 5;
  var _maxUses = 1;
  String? _region = 'Stuttgart';

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    DropdownMenuItem<int> item(int v) => DropdownMenuItem(value: v, child: Text('$v'));
    return AlertDialog(
      title: Text(l.invitesCreate),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _count,
              decoration: InputDecoration(labelText: l.invitesCount),
              items: [
                for (final v in const [1, 5, 10, 25]) item(v),
              ],
              onChanged: (v) => setState(() => _count = v ?? 1),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _maxUses,
              decoration: InputDecoration(labelText: l.invitesMaxUses),
              items: [
                for (final v in const [1, 5, 20, 100]) item(v),
              ],
              onChanged: (v) => setState(() => _maxUses = v ?? 1),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _region,
              decoration: InputDecoration(labelText: l.invitesRegion),
              items: [
                for (final r in const ['Stuttgart', 'Ulm']) DropdownMenuItem(value: r, child: Text(r)),
                DropdownMenuItem(value: null, child: Text(l.invitesNoRegion)),
              ],
              onChanged: (v) => setState(() => _region = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLength: 80,
              decoration: InputDecoration(labelText: l.invitesNote, hintText: l.invitesNoteHint),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        AsyncButton(
          label: l.invitesCreateShort,
          onPressed: () async {
            final codes = await ref
                .read(apiProvider)
                .adminCreateInvites(count: _count, maxUses: _maxUses, region: _region, note: _note.text);
            if (context.mounted) Navigator.pop(context, codes);
          },
        ),
      ],
    );
  }
}

class _NewCodesDialog extends StatelessWidget {
  const _NewCodesDialog({required this.codes});

  final List<String> codes;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formatted = [for (final c in codes) '${c.substring(0, 4)}-${c.substring(4)}'];
    final text = formatted.join('\n');
    return AlertDialog(
      title: Text(l.invitesCreated(codes.length)),
      content: SelectableText(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 18, height: 1.6)),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: text));
            if (context.mounted) showMessage(context, l.copied);
          },
          child: Text(l.copy),
        ),
        TextButton(
          onPressed: () => SharePlus.instance.share(
            ShareParams(text: codes.length == 1 ? l.inviteShareText(formatted.single) : text),
          ),
          child: Text(l.share),
        ),
        FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.done)),
      ],
    );
  }
}

// --- Feedback -------------------------------------------------------------------

class FeedbackTab extends ConsumerWidget {
  const FeedbackTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final date = MaterialLocalizations.of(context).formatMediumDate;
    String category(FeedbackCategory c) => switch (c) {
      FeedbackCategory.bug => l.feedbackBug,
      FeedbackCategory.idea => l.feedbackIdea,
      FeedbackCategory.other => l.feedbackOther,
    };
    return ref
        .watch(_feedbackProvider)
        .when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(_feedbackProvider)),
          data: (items) => items.isEmpty
              ? EmptyState(icon: Icons.check_circle_outline, title: l.adminNothing)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final f = items[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '${category(f.category)} · ${f.displayName ?? l.feedbackNoProfile}',
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              [date(f.createdAt), ?f.platform, ?f.appVersion].join(' · '),
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                            ),
                            const SizedBox(height: 8),
                            SelectableText(f.message),
                            Align(
                              alignment: Alignment.centerRight,
                              child: AsyncButton(
                                outlined: true,
                                label: l.feedbackResolve,
                                onPressed: () async {
                                  await ref.read(apiProvider).adminResolveFeedback(f.id);
                                  ref.invalidate(_feedbackProvider);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
  }
}
