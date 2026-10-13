import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/data/lotus_api.dart';
import 'package:lotus/data/models.dart';
import 'package:lotus/features/auth/login_screen.dart';
import 'package:lotus/features/profile/profile_forms.dart';
import 'package:lotus/features/profile/profile_view.dart';
import 'package:lotus/legal/impressum_screen.dart';
import 'package:lotus/l10n/gen/app_localizations.dart';
import 'package:lotus/theme.dart';
import 'package:lotus/widgets/common.dart';

Widget wrap(Widget child) => ProviderScope(
  child: MaterialApp(
    theme: buildLightTheme(),
    locale: const Locale('de'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  ),
);

const _profile = FullProfile(
  summary: ProfileSummary(
    id: 'b',
    displayName: 'Ben',
    age: 32,
    gender: Gender.man,
    city: 'Stuttgart',
    intention: Intention.relationship,
    distanceKm: 4,
    verified: true,
  ),
  photos: [Photo(id: 'p1', storagePath: 'b/1.jpg', position: 0)],
  prompts: [
    PromptAnswer(
      id: 'q1',
      promptId: 4,
      promptText: 'Mein liebster Ort in der Stadt:',
      answer: 'Der Feuersee',
      position: 0,
    ),
  ],
);

void main() {
  testWidgets('Login zeigt E-Mail-Feld und Code-Button', (tester) async {
    await tester.pumpWidget(wrap(const LoginScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Willkommen bei Lotus'), findsOneWidget);
    expect(find.text('E-Mail-Adresse'), findsOneWidget);
    expect(find.text('Code senden'), findsOneWidget);
  });

  testWidgets('Profilansicht zeigt Angaben, Prompt und Herz pro Element', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final liked = <(LikeTarget, String)>[];
    await tester.pumpWidget(wrap(ProfileView(profile: _profile, onLike: (type, id, _) => liked.add((type, id)))));
    await tester.pump();

    expect(find.text('Ben'), findsOneWidget);
    expect(find.textContaining('32 · Mann · Stuttgart · 4 km entfernt'), findsOneWidget);
    expect(find.text('Eine feste Beziehung'), findsOneWidget);
    expect(find.text('Der Feuersee'), findsOneWidget);
    expect(find.byType(VerifiedBadge), findsOneWidget);

    final hearts = find.byIcon(Icons.favorite_border);
    expect(hearts, findsNWidgets(3)); // Foto, Prompt + Dating-Ziel
    await tester.tap(find.byTooltip('Gefällt mir').last);
    expect(liked.single, (LikeTarget.prompt, 'q1'));
  });

  testWidgets('Profilansicht ohne onLike hat keine Like-Buttons', (tester) async {
    await tester.pumpWidget(wrap(const ProfileView(profile: _profile)));
    await tester.pump();
    expect(find.byTooltip('Gefällt mir'), findsNothing);
  });

  testWidgets('Suchformular: Orientierung ist als privat gekennzeichnet', (tester) async {
    final draft = ProfileDraft();
    await tester.pumpWidget(
      wrap(
        SingleChildScrollView(
          child: PreferencesSection(draft: draft, onChanged: () {}),
        ),
      ),
    );
    expect(find.text('Bleibt privat und wird nur für passende Vorschläge verwendet.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Divers'));
    await tester.tap(find.text('Eine feste Beziehung'));
    await tester.pump();
    expect(draft.interestedIn, {Gender.diverse});
    expect(draft.intention, Intention.relationship);
    expect(draft.intentionPublic, isTrue);
  });

  testWidgets('Fehlerschlüssel werden auf Deutsch angezeigt', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(
      errorText(captured, const LotusException('daily_like_limit_reached')),
      'Deine 20 Likes für heute sind aufgebraucht.',
    );
    expect(
      errorText(captured, const LotusException('monthly_undo_limit_reached')),
      'Du hast diesen Monat schon 3-mal rückgängig gemacht.',
    );
    expect(errorText(captured, Exception('x')), 'Etwas ist schiefgelaufen. Bitte versuch es noch einmal.');
  });

  testWidgets('Suchradius geht von 1 bis 150 km', (tester) async {
    final draft = ProfileDraft();
    await tester.pumpWidget(
      wrap(
        SingleChildScrollView(
          child: PreferencesSection(draft: draft, onChanged: () {}),
        ),
      ),
    );
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.min, 1);
    expect(slider.max, 150);
  });

  testWidgets('Profil im Reisemodus zeigt "zu Besuch"', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const visiting = FullProfile(
      summary: ProfileSummary(id: 'x', displayName: 'Mia', age: 29, city: 'Ulm', verified: false, traveling: true),
      photos: [],
      prompts: [],
    );
    await tester.pumpWidget(wrap(const ProfileView(profile: visiting)));
    expect(find.textContaining('Ulm · zu Besuch'), findsOneWidget);
  });

  testWidgets('Impressum warnt, solange Pflichtangaben fehlen', (tester) async {
    await tester.pumpWidget(wrap(const ImpressumScreen()));
    expect(find.text('Angaben gemäß § 5 DDG'), findsOneWidget);
    expect(find.text('Zentrale Kontaktstelle nach Art. 11 und 12 DSA'), findsOneWidget);
    expect(find.textContaining('Impressum unvollständig'), findsOneWidget);
    expect(find.textContaining('Online-Streitbeilegung'), findsNothing); // OS-Plattform seit 20.07.2025 abgeschaltet
  });

  testWidgets('Kinderwunsch & Rauchen: optional, abwählbar, Ausschluss nur mit Angabe', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final draft = ProfileDraft()
      ..interestedIn = {Gender.man}
      ..intention = Intention.relationship;
    await tester.pumpWidget(
      wrap(
        SingleChildScrollView(
          child: PreferencesSection(draft: draft, onChanged: () {}),
        ),
      ),
    );

    expect(find.text('Nur Menschen mit passendem Kinderwunsch zeigen'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Möchte Kinder'));
    await tester.pump();
    expect(draft.children, ChildrenWish.want);
    await tester.tap(find.text('Nur Menschen mit passendem Kinderwunsch zeigen'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Nichtraucher:in'));
    await tester.pump();
    expect(draft.toPreferences().childrenDealbreaker, isTrue);
    expect(draft.smoking, Smoking.never);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Möchte Kinder')); // abwählen
    await tester.pump();
    expect(draft.children, isNull);
    expect(draft.toPreferences().childrenDealbreaker, isFalse);
  });

  testWidgets('Profil zeigt öffentliche Angaben zu Kinderwunsch und Rauchen', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const profile = FullProfile(
      summary: ProfileSummary(
        id: 'k',
        displayName: 'Lea',
        age: 31,
        verified: false,
        children: ChildrenWish.haveKids,
        smoking: Smoking.never,
      ),
      photos: [],
      prompts: [],
    );
    await tester.pumpWidget(wrap(const ProfileView(profile: profile)));
    expect(find.text('Habe Kinder'), findsOneWidget);
    expect(find.text('Nichtraucher:in'), findsOneWidget);
  });
}
