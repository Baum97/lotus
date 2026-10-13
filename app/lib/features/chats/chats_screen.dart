import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
import '../../data/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../../widgets/common.dart';
import 'chat_screen.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final matches = ref.watch(matchesProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.chatsTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(matchesProvider.future),
        child: matches.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(matchesProvider)),
          data: (matches) {
            if (matches.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: 400,
                    child: EmptyState(icon: Icons.chat_bubble_outline, title: l.chatsEmpty),
                  ),
                ],
              );
            }
            final active = matches.where((m) => m.state == MatchState.active).length;
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      for (var i = 0; i < AppConfig.maxActiveChats; i++)
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < active ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHigh,
                          ),
                        ),
                      const SizedBox(width: 6),
                      Text(
                        l.chatSlots(active),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                for (final match in matches) _MatchTile(match: match),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MatchTile extends ConsumerWidget {
  const _MatchTile({required this.match});

  final MatchSummary match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final subtitle = switch (match.state) {
      MatchState.queued => l.chatQueued,
      MatchState.closed => match.closeReason == CloseReason.stale ? l.chatClosedStale : l.chatClosed,
      MatchState.active =>
        match.lastMessage == null
            ? l.chatNoMessages
            : match.lastMessageMine
            ? l.chatYou(match.lastMessage!)
            : match.lastMessage!,
    };
    return Opacity(
      opacity: match.state == MatchState.closed ? 0.55 : 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: match.state == MatchState.queued
              ? theme.colorScheme.surfaceContainer
              : theme.colorScheme.primaryContainer,
          child: match.state == MatchState.queued
              ? Icon(Icons.hourglass_empty, color: muted)
              : Text(
                  match.displayName.characters.first,
                  style: TextStyle(fontSize: 20, color: theme.colorScheme.primary),
                ),
        ),
        title: Row(
          children: [
            Flexible(child: Text(match.displayName, style: theme.textTheme.titleMedium)),
            if (match.verified) ...[const SizedBox(width: 6), const VerifiedBadge(small: true)],
          ],
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: muted),
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ChatScreen(match: match))),
      ),
    );
  }
}
