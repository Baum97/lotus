import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../legal/consent.dart';
import '../../providers.dart';
import '../../widgets/common.dart';
import '../profile/profile_forms.dart';

/// Grundangaben oder Suche & Privatsphäre bearbeiten.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, this.preferencesOnly = false});

  final bool preferencesOnly;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  ProfileDraft? _draft;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiProvider);
      final profile = await api.ownProfile();
      final preferences = await api.ownPreferences();
      if (mounted) setState(() => _draft = ProfileDraft.from(profile!, preferences));
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final draft = _draft!;
    final needsConsent = await ref.read(matchingConsentProvider.future) == null;
    if (!mounted) return;
    final problem =
        draft.validateBasics(l, needsBirthdate: false) ?? draft.validatePreferences(l, needsConsent: needsConsent);
    if (problem != null) {
      showMessage(context, problem);
      return;
    }
    if (needsConsent) {
      await ref.read(apiProvider).giveConsent(MatchingConsent.kind, MatchingConsent.version);
      ref.invalidate(matchingConsentProvider);
    }
    await ref
        .read(apiProvider)
        .saveProfile(
          displayName: draft.name.trim(),
          gender: draft.gender!,
          bio: draft.bio,
          city: draft.city,
          preferences: draft.toPreferences(),
        );
    ref.invalidate(myStatusProvider);
    ref.invalidate(fullProfileProvider);
    if (mounted) {
      showMessage(context, l.saved);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final draft = _draft;
    return Scaffold(
      appBar: AppBar(title: Text(widget.preferencesOnly ? l.editPreferences : l.editProfile)),
      body: _error != null
          ? ErrorView(error: _error!, onRetry: _load)
          : draft == null
          ? const LoadingView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: widget.preferencesOnly
                  ? PreferencesSection(
                      draft: draft,
                      onChanged: () {},
                      showConsent: ref.watch(matchingConsentProvider).value == null,
                    )
                  : BasicsSection(draft: draft, onChanged: () {}, showBirthdate: false),
            ),
      bottomNavigationBar: draft == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: AsyncButton(label: l.save, onPressed: _save),
              ),
            ),
    );
  }
}
