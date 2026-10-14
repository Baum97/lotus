import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../../widgets/common.dart';
import '../../legal/impressum_screen.dart';
import '../admin/admin_screen.dart';
import '../beta/feedback_sheet.dart';
import '../privacy/privacy_screen.dart';
import '../settings/notification_settings_screen.dart';
import '../support/support_screen.dart';
import '../profile/location_section.dart';
import '../profile/photos_editor.dart';
import '../profile/profile_view.dart';
import '../profile/prompts_editor.dart';
import 'delete_account_screen.dart';
import 'edit_profile_screen.dart';
import 'verification_screen.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  void _open(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final status = ref.watch(myStatusProvider).value;
    final theme = Theme.of(context);
    if (status == null) return const Scaffold(body: LoadingView());

    final (verificationText, verificationIcon) = status.verified
        ? (l.verified, Icons.verified)
        : switch (status.verificationStatus) {
            VerificationStatus.pending => (l.verificationPending, Icons.hourglass_empty),
            VerificationStatus.rejected => (l.verificationRejected, Icons.error_outline),
            _ => (l.notVerified, Icons.verified_outlined),
          };

    return Scaffold(
      appBar: AppBar(title: Text(l.meTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                const LotusLogo(size: 56),
                const SizedBox(width: 16),
                Expanded(child: Text(status.displayName ?? '', style: theme.textTheme.headlineSmall)),
                if (status.verified) const VerifiedBadge(),
              ],
            ),
          ),
          if (status.trustStatus == TrustStatus.restricted)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: InfoBanner(text: l.accountRestricted, warning: true),
            ),
          _Tile(
            icon: Icons.visibility_outlined,
            title: l.previewProfile,
            onTap: () => _open(context, const _OwnPreviewScreen()),
          ),
          _Tile(
            icon: verificationIcon,
            title: l.verification,
            subtitle: verificationText,
            onTap: status.verified ? null : () => _open(context, const VerificationScreen()),
          ),
          const Divider(height: 24),
          _Tile(
            icon: Icons.person_outline,
            title: l.editProfile,
            onTap: () => _open(context, const EditProfileScreen()),
          ),
          _Tile(
            icon: Icons.tune,
            title: l.editPreferences,
            onTap: () => _open(context, const EditProfileScreen(preferencesOnly: true)),
          ),
          _Tile(
            icon: Icons.photo_library_outlined,
            title: l.editPhotos,
            onTap: () => _open(context, _EditorScreen(title: l.editPhotos, child: const PhotosEditor())),
          ),
          _Tile(
            icon: Icons.format_quote_outlined,
            title: l.editPrompts,
            onTap: () => _open(context, _EditorScreen(title: l.editPrompts, child: const PromptsEditor())),
          ),
          _Tile(
            icon: Icons.my_location,
            title: l.updateLocation,
            onTap: () async {
              try {
                await updateLocation(context, ref);
              } catch (e) {
                if (context.mounted) showError(context, e);
              }
            },
          ),
          const Divider(height: 24),
          _Tile(
            icon: Icons.spa_outlined,
            title: l.supportTitle,
            subtitle: status.hasPlus
                ? l.plusActiveUntil(MaterialLocalizations.of(context).formatMediumDate(status.plusUntil!))
                : null,
            onTap: () => _open(context, const SupportScreen()),
          ),
          _Tile(
            icon: Icons.notifications_outlined,
            title: l.notificationsTitle,
            onTap: () => _open(context, const NotificationSettingsScreen()),
          ),
          _Tile(icon: Icons.feedback_outlined, title: l.feedbackTitle, onTap: () => showFeedbackSheet(context)),
          if (status.isAdmin) ...[
            const Divider(height: 24),
            _Tile(
              icon: Icons.admin_panel_settings_outlined,
              title: l.adminArea,
              onTap: () => _open(context, const AdminScreen()),
            ),
          ],
          const Divider(height: 24),
          _Tile(icon: Icons.shield_outlined, title: l.privacyTitle, onTap: () => _open(context, const PrivacyScreen())),
          _Tile(icon: Icons.info_outline, title: l.imprint, onTap: () => _open(context, const ImpressumScreen())),
          _Tile(icon: Icons.logout, title: l.signOut, onTap: () => ref.read(apiProvider).signOut()),
          _Tile(
            icon: Icons.delete_outline,
            title: l.deleteAccount,
            onTap: () => _open(context, const DeleteAccountScreen()),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, this.subtitle, this.onTap});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _EditorScreen extends StatelessWidget {
  const _EditorScreen({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: child),
    );
  }
}

/// Eigenes Profil so, wie andere es sehen.
class _OwnPreviewScreen extends ConsumerWidget {
  const _OwnPreviewScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final profile = ref.watch(fullProfileProvider(ref.read(apiProvider).currentUserId!));
    return Scaffold(
      appBar: AppBar(title: Text(l.previewProfile)),
      body: profile.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(fullProfileProvider)),
        data: (profile) => profile == null ? const SizedBox() : ProfileView(profile: profile),
      ),
    );
  }
}
