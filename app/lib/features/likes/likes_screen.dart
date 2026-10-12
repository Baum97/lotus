import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../../widgets/common.dart';
import '../profile/profile_view.dart';

/// "Wer dich mag" – für alle gratis, Zurück-Liken kostet keine Likes.
class LikesScreen extends ConsumerWidget {
  const LikesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final likes = ref.watch(incomingLikesProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.likesTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(incomingLikesProvider.future),
        child: likes.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(incomingLikesProvider)),
          data: (likes) => likes.isEmpty
              ? ListView(children: [
                  SizedBox(
                    height: 400,
                    child: EmptyState(icon: Icons.favorite_border, title: l.likesEmpty),
                  ),
                ])
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: likes.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Text(l.likesSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant));
                    }
                    final like = likes[i - 1];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(like.displayName.characters.first,
                              style: TextStyle(color: theme.colorScheme.primary)),
                        ),
                        title: Text('${like.displayName}, ${like.age}'),
                        subtitle: Text(
                          like.comment ?? switch (like.targetType) {
                            LikeTarget.photo => l.likedYourPhoto,
                            LikeTarget.prompt => l.likedYourPrompt,
                            null => l.likedYou,
                          },
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: like.comment != null ? const TextStyle(fontStyle: FontStyle.italic) : null,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: (_) => IncomingLikeScreen(like: like)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/// Profil einer Person, die mich geliked hat – mit Zurück-Liken oder Ablehnen.
class IncomingLikeScreen extends ConsumerWidget {
  const IncomingLikeScreen({super.key, required this.like});

  final IncomingLike like;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final profile = ref.watch(fullProfileProvider(like.fromUser));
    final api = ref.read(apiProvider);

    void done() {
      ref.invalidate(incomingLikesProvider);
      ref.invalidate(matchesProvider);
      ref.invalidate(myStatusProvider);
      Navigator.pop(context);
    }

    return Scaffold(
      appBar: AppBar(title: Text(like.displayName)),
      body: profile.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(fullProfileProvider(like.fromUser))),
        data: (profile) => profile == null
            ? EmptyState(icon: Icons.person_off_outlined, title: l.errorProfileNotAvailable)
            : ProfileView(
                profile: profile,
                highlightId: like.targetId,
                footer: like.comment == null
                    ? null
                    : InfoBanner(text: '„${like.comment}“', icon: Icons.format_quote),
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(children: [
            Expanded(
              child: AsyncButton(
                outlined: true,
                label: l.decline,
                onPressed: () async {
                  await api.pass(like.fromUser);
                  done();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AsyncButton(
                icon: Icons.favorite,
                label: l.likeBack,
                onPressed: () async {
                  final result = await api.like(like.fromUser);
                  if (result.isMatch && context.mounted) {
                    await showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        icon: const LotusLogo(size: 64),
                        title: Text(l.matchTitle, textAlign: TextAlign.center),
                        content: Text(l.matchBody(like.displayName), textAlign: TextAlign.center),
                        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.ok))],
                      ),
                    );
                  }
                  done();
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
