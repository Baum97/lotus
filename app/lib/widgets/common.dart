import 'package:flutter/material.dart';

import '../data/lotus_api.dart';
import '../l10n/gen/app_localizations.dart';
import '../theme.dart';

/// Deutsche Fehlermeldung zu einem Fehler aus der API.
String errorText(BuildContext context, Object error) {
  final l = AppLocalizations.of(context);
  if (error is! LotusException) return l.errorGeneric;
  return switch (error.key) {
    'daily_like_limit_reached' => l.errorDailyLikeLimit,
    'monthly_undo_limit_reached' => l.errorMonthlyUndoLimit,
    'nothing_to_undo' => l.errorNothingToUndo,
    'profile_not_available' => l.errorProfileNotAvailable,
    'already_liked' => l.errorAlreadyLiked,
    'too_young' => l.errorTooYoung,
    'account_suspended' => l.errorSuspended,
    'slow_down' => l.errorSlowDown,
    'links_not_allowed' => l.errorLinksNotAllowed,
    'already_verified' => l.errorAlreadyVerified,
    'not_allowed' => l.errorNotAllowed,
    'plus_required' => l.errorPlusRequired,
    'profile_not_found' => l.errorProfileNotFound,
    'purchase_failed' || 'purchase_not_found' || 'purchase_not_active' || 'purchase_account_mismatch' ||
    'purchase_not_completed' || 'invalid_product' => l.errorPurchase,
    'otp_expired' || 'invalid_credentials' => l.errorInvalidCode,
    'over_email_send_rate_limit' || 'over_request_rate_limit' => l.errorRateLimit,
    _ => l.errorGeneric,
  };
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(context, error))));
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class LotusLogo extends StatelessWidget {
  const LotusLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(Icons.spa_outlined, size: size * 0.55, color: scheme.primary),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      title: errorText(context, error),
      action: OutlinedButton(onPressed: onRetry, child: Text(AppLocalizations.of(context).retry)),
    );
  }
}

/// Ruhiger, zentrierter Hinweis für leere oder abgeschlossene Zustände.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.body, this.action});

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer, shape: BoxShape.circle),
            child: Icon(icon, size: 40, color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 24),
          Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
          if (body != null) ...[
            const SizedBox(height: 12),
            Text(body!,
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 24), action!],
        ]),
      ),
    );
  }
}

/// Foto mit abgerundeten Ecken; Platzhalter, solange die URL fehlt oder lädt.
class RoundedPhoto extends StatelessWidget {
  const RoundedPhoto({super.key, required this.url, this.aspectRatio = 4 / 5, this.radius = 20});

  final String? url;
  final double aspectRatio;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainer,
      child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant),
    );
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: url == null
            ? placeholder
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
                loadingBuilder: (context, child, progress) => progress == null ? child : placeholder,
              ),
      ),
    );
  }
}

/// Reine Anzeige im Pillen-Look (statt Chip, der für Screenreader wie eine Checkbox wirkt).
class Pill extends StatelessWidget {
  const Pill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: scheme.primary),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.small = false});

  final bool small;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppLocalizations.of(context).verifiedBadge,
      child: Icon(Icons.verified, size: small ? 16 : 20, color: LotusColors.sage),
    );
  }
}

/// Hinweisbox, z. B. für Sicherheitswarnungen oder Status.
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.text, this.icon = Icons.info_outline, this.warning = false, this.action});

  final String text;
  final IconData icon;
  final bool warning;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = warning ? LotusColors.warningLight : scheme.secondaryContainer;
    final foreground = warning ? LotusColors.warning : scheme.secondary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: foreground, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(text, style: const TextStyle(color: LotusColors.ink)),
            if (action != null) ...[const SizedBox(height: 8), action!],
          ]),
        ),
      ]),
    );
  }
}

/// Button, der während einer asynchronen Aktion einen Ladeindikator zeigt und Fehler meldet.
class AsyncButton extends StatefulWidget {
  const AsyncButton({super.key, required this.label, required this.onPressed, this.outlined = false, this.icon});

  final String label;
  final Future<void> Function()? onPressed;
  final bool outlined;
  final IconData? icon;

  @override
  State<AsyncButton> createState() => _AsyncButtonState();
}

class _AsyncButtonState extends State<AsyncButton> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onPressed = widget.onPressed == null || _busy ? null : _run;
    final child = _busy
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
        : Text(widget.label);
    if (widget.outlined) {
      return widget.icon == null
          ? OutlinedButton(onPressed: onPressed, child: child)
          : OutlinedButton.icon(onPressed: onPressed, icon: Icon(widget.icon), label: child);
    }
    return widget.icon == null
        ? FilledButton(onPressed: onPressed, child: child)
        : FilledButton.icon(onPressed: onPressed, icon: Icon(widget.icon), label: child);
  }
}
