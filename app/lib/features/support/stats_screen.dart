import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../../widgets/common.dart';

/// Statistiken nur über das eigene Profil (Lotus Plus).
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stats = ref.watch(myStatsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.statsTitle)),
      body: stats.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myStatsProvider)),
        data: (s) {
          Widget tile(String label, int value) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$value', style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary)),
                  const SizedBox(height: 4),
                  Text(label, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  tile(l.statsImpressions, s.impressions7d),
                  tile(l.statsLikes, s.likes30d),
                  tile(l.statsComments, s.comments30d),
                  tile(l.statsMatches, s.matches30d),
                ],
              ),
              const SizedBox(height: 24),
              Text(l.statsElements, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final e in s.elements)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    e.isPhoto ? Icons.photo_outlined : Icons.format_quote_outlined,
                    color: theme.colorScheme.secondary,
                  ),
                  title: Text(e.label),
                  subtitle: Text(l.statsElementLine(e.likes, e.comments)),
                ),
            ],
          );
        },
      ),
    );
  }
}
