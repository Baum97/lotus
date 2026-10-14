import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../legal/consent.dart';
import '../../providers.dart';
import '../../widgets/common.dart';
import '../profile/location_section.dart';
import '../profile/photos_editor.dart';
import '../profile/profile_forms.dart';
import '../profile/prompts_editor.dart';

/// Profil in 5 Schritten anlegen. Steigt nach einem Abbruch beim ersten fehlenden Schritt wieder ein.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.status});

  final MyStatus status;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _steps = 5;
  final _draft = ProfileDraft();
  late int _step = _firstOpenStep(widget.status);

  @override
  void initState() {
    super.initState();
    // Profil existiert schon (z. B. nach Widerruf der Einwilligung): Grundangaben übernehmen
    if (widget.status.hasProfile) {
      ref.read(apiProvider).ownProfile().then((profile) {
        if (profile == null || !mounted) return;
        setState(() {
          _draft
            ..name = profile.displayName
            ..gender = profile.gender
            ..city = profile.city ?? ''
            ..bio = profile.bio ?? '';
        });
      });
    }
  }

  static int _firstOpenStep(MyStatus s) {
    if (!s.hasProfile) return 0;
    if (!s.hasPreferences) return 1;
    if (s.photoCount == 0) return 2;
    if (s.promptCount == 0) return 3;
    return 4;
  }

  String _title(AppLocalizations l) => switch (_step) {
    0 => l.stepBasics,
    1 => l.stepPreferences,
    2 => l.stepPhotos,
    3 => l.stepPrompts,
    _ => l.stepLocation,
  };

  /// Prüft den aktuellen Schritt; nach Schritt 2 wird das Profil gespeichert.
  Future<void> _next() async {
    final l = AppLocalizations.of(context);
    final status = ref.read(myStatusProvider).value ?? widget.status;
    String? problem;
    switch (_step) {
      case 0:
        problem = _draft.validateBasics(l, needsBirthdate: !status.hasProfile);
      case 1:
        final needsConsent = await ref.read(matchingConsentProvider.future) == null;
        problem =
            _draft.validateBasics(l, needsBirthdate: !status.hasProfile) ??
            _draft.validatePreferences(l, needsConsent: needsConsent);
        if (problem == null) {
          if (needsConsent) {
            await ref.read(apiProvider).giveConsent(MatchingConsent.kind, MatchingConsent.version);
            ref.invalidate(matchingConsentProvider);
          }
          await ref
              .read(apiProvider)
              .saveProfile(
                displayName: _draft.name.trim(),
                birthdate: _draft.birthdate,
                gender: _draft.gender!,
                bio: _draft.bio,
                city: _draft.city,
                preferences: _draft.toPreferences(),
              );
          // Sind Fotos, Prompts und Standort schon da (z. B. nach erneuter Einwilligung), geht es direkt in die App
          ref.invalidate(myStatusProvider);
        }
      case 2:
        if (status.photoCount == 0) problem = l.photoRequired;
      case 3:
        if (status.promptCount == 0) problem = l.promptRequired;
      case 4:
        if (!status.hasLocation) problem = l.locationDenied;
    }
    if (!mounted) return;
    if (problem != null) {
      showMessage(context, problem);
      return;
    }
    if (_step == _steps - 1) {
      ref.invalidate(myStatusProvider);
    } else {
      setState(() => _step++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final status = ref.watch(myStatusProvider).value ?? widget.status;
    final theme = Theme.of(context);
    final content = switch (_step) {
      0 => BasicsSection(draft: _draft, onChanged: () {}, showBirthdate: !status.hasProfile),
      1 => PreferencesSection(
        draft: _draft,
        onChanged: () {},
        showConsent: ref.watch(matchingConsentProvider).value == null,
      ),
      2 => const PhotosEditor(),
      3 => const PromptsEditor(),
      _ => LocationSection(hasLocation: status.hasLocation),
    };
    return Scaffold(
      appBar: AppBar(
        leading: _step > 0 && _step <= 1 ? BackButton(onPressed: () => setState(() => _step--)) : null,
        automaticallyImplyLeading: false,
        title: Text(l.onboardingTitle),
        actions: [TextButton(onPressed: () => ref.read(apiProvider).signOut(), child: Text(l.signOut))],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_step + 1) / _steps, backgroundColor: theme.colorScheme.surfaceContainer),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.stepOf(_step + 1, _steps),
                          style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(_title(l), style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 24),
                        content,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SizedBox(
                  width: double.infinity,
                  child: AsyncButton(label: _step == _steps - 1 ? l.finishOnboarding : l.next, onPressed: _next),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
