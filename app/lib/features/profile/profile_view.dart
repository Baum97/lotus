import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../widgets/common.dart';
import 'profile_forms.dart';

/// Wird aufgerufen, wenn ein Foto oder Prompt geliked werden soll.
typedef LikeElementCallback = void Function(LikeTarget type, String id, String preview);

/// Vollständiges Profil: Fotos und Prompts im Wechsel, damit man wirklich hinschaut.
/// Mit [onLike] bekommt jedes Element ein Herz.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key, required this.profile, this.onLike, this.footer, this.highlightId});

  final FullProfile profile;
  final LikeElementCallback? onLike;
  final Widget? footer;

  /// Element, das hervorgehoben wird (z. B. das Foto, das jemand geliked hat).
  final String? highlightId;

  @override
  Widget build(BuildContext context) {
    final s = profile.summary;
    final photos = profile.photos;
    final prompts = profile.prompts;

    // Reihenfolge: Foto, Kopfbereich, dann abwechselnd Prompt und Foto
    final items = <Widget>[];
    if (photos.isNotEmpty) items.add(_photo(photos.first));
    items.add(_Header(summary: s));
    final rest = photos.skip(1).toList();
    for (var i = 0; i < prompts.length || i < rest.length; i++) {
      if (i < prompts.length) items.add(_prompt(context, prompts[i]));
      if (i < rest.length) items.add(_photo(rest[i]));
    }
    if (footer != null) items.add(footer!);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, i) => Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: items[i]),
      ),
    );
  }

  Widget _photo(Photo photo) => _Likeable(
        highlighted: photo.id == highlightId,
        onLike: onLike == null ? null : () => onLike!(LikeTarget.photo, photo.id, ''),
        child: RoundedPhoto(url: photo.url),
      );

  Widget _prompt(BuildContext context, PromptAnswer prompt) {
    final theme = Theme.of(context);
    return _Likeable(
      highlighted: prompt.id == highlightId,
      onLike: onLike == null ? null : () => onLike!(LikeTarget.prompt, prompt.id, prompt.answer),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 64, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(prompt.promptText,
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            Text(prompt.answer, style: theme.textTheme.headlineSmall?.copyWith(height: 1.3)),
          ]),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.summary});

  final ProfileSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Flexible(child: Text(summary.displayName, style: theme.textTheme.headlineMedium)),
          if (summary.verified) ...[const SizedBox(width: 8), const VerifiedBadge()],
        ]),
        const SizedBox(height: 4),
        Text(
          [
            summary.age.toString(),
            if (summary.gender != null) genderLabel(l, summary.gender!),
            if (summary.city != null) summary.city!,
            if (summary.traveling) l.travelVisiting,
            if (summary.distanceKm != null) l.distanceKm(summary.distanceKm!),
          ].join(' · '),
          style: muted,
        ),
        if (summary.intention != null) ...[
          const SizedBox(height: 12),
          Pill(icon: Icons.favorite_border, label: intentionLabel(l, summary.intention!)),
        ],
        if (summary.bio != null) ...[
          const SizedBox(height: 12),
          Text(summary.bio!, style: theme.textTheme.bodyLarge),
        ],
      ]),
    );
  }
}

/// Element mit Herz-Button unten rechts.
class _Likeable extends StatelessWidget {
  const _Likeable({required this.child, required this.onLike, this.highlighted = false});

  final Widget child;
  final VoidCallback? onLike;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = highlighted
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: scheme.primary, width: 3),
            ),
            child: Padding(padding: const EdgeInsets.all(3), child: child),
          )
        : child;
    if (onLike == null) return content;
    return Stack(children: [
      content,
      Positioned(
        right: 12,
        bottom: 12,
        child: Material(
          color: scheme.surfaceContainerLowest,
          shape: const CircleBorder(),
          elevation: 2,
          child: IconButton(
            tooltip: AppLocalizations.of(context).likeThis,
            icon: Icon(Icons.favorite_border, color: scheme.primary),
            onPressed: onLike,
          ),
        ),
      ),
    ]);
  }
}
