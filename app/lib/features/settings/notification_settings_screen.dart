import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../../widgets/common.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(notificationSettingsProvider);

    Future<void> save(NotificationSettings updated) async {
      try {
        await ref.read(apiProvider).saveNotificationSettings(updated);
        ref.invalidate(notificationSettingsProvider);
      } catch (e) {
        if (context.mounted) showError(context, e);
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.notificationsTitle)),
      body: settings.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(notificationSettingsProvider)),
        data: (s) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l.notificationsIntro),
            const SizedBox(height: 8),
            SwitchListTile(
              value: s.messages,
              title: Text(l.notifyMessages),
              onChanged: (v) => save(s.copyWith(messages: v)),
            ),
            SwitchListTile(
              value: s.matches,
              title: Text(l.notifyMatches),
              onChanged: (v) => save(s.copyWith(matches: v)),
            ),
            SwitchListTile(
              value: s.likes,
              title: Text(l.notifyLikes),
              onChanged: (v) => save(s.copyWith(likes: v)),
            ),
          ],
        ),
      ),
    );
  }
}
