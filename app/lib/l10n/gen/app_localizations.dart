import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('de')];

  /// No description provided for @appName.
  ///
  /// In de, this message translates to:
  /// **'Lotus'**
  String get appName;

  /// No description provided for @ok.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert'**
  String get saved;

  /// No description provided for @next.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get next;

  /// No description provided for @back.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get back;

  /// No description provided for @retry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @loginTitle.
  ///
  /// In de, this message translates to:
  /// **'Willkommen bei Lotus'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Weniger wischen, mehr kennenlernen.'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In de, this message translates to:
  /// **'E-Mail-Adresse'**
  String get emailLabel;

  /// No description provided for @sendCode.
  ///
  /// In de, this message translates to:
  /// **'Code senden'**
  String get sendCode;

  /// No description provided for @codeSentTo.
  ///
  /// In de, this message translates to:
  /// **'Wir haben dir einen 6-stelligen Code an {email} geschickt.'**
  String codeSentTo(String email);

  /// No description provided for @codeLabel.
  ///
  /// In de, this message translates to:
  /// **'Code'**
  String get codeLabel;

  /// No description provided for @verifyCode.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get verifyCode;

  /// No description provided for @changeEmail.
  ///
  /// In de, this message translates to:
  /// **'Andere E-Mail verwenden'**
  String get changeEmail;

  /// No description provided for @invalidEmail.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib eine gültige E-Mail-Adresse ein.'**
  String get invalidEmail;

  /// No description provided for @loginLegal.
  ///
  /// In de, this message translates to:
  /// **'Mit der Anmeldung bestätigst du, dass du mindestens 18 Jahre alt bist.'**
  String get loginLegal;

  /// No description provided for @notConfigured.
  ///
  /// In de, this message translates to:
  /// **'Die App ist noch nicht mit einem Server verbunden. Starte sie mit --dart-define=SUPABASE_URL=… und --dart-define=SUPABASE_KEY=… (siehe README).'**
  String get notConfigured;

  /// No description provided for @onboardingTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Profil'**
  String get onboardingTitle;

  /// No description provided for @stepBasics.
  ///
  /// In de, this message translates to:
  /// **'Über dich'**
  String get stepBasics;

  /// No description provided for @stepPreferences.
  ///
  /// In de, this message translates to:
  /// **'Wen suchst du?'**
  String get stepPreferences;

  /// No description provided for @stepPhotos.
  ///
  /// In de, this message translates to:
  /// **'Deine Fotos'**
  String get stepPhotos;

  /// No description provided for @stepPrompts.
  ///
  /// In de, this message translates to:
  /// **'Deine Prompts'**
  String get stepPrompts;

  /// No description provided for @stepLocation.
  ///
  /// In de, this message translates to:
  /// **'Dein Standort'**
  String get stepLocation;

  /// No description provided for @stepOf.
  ///
  /// In de, this message translates to:
  /// **'Schritt {step} von {total}'**
  String stepOf(int step, int total);

  /// No description provided for @nameLabel.
  ///
  /// In de, this message translates to:
  /// **'Vorname'**
  String get nameLabel;

  /// No description provided for @birthdateLabel.
  ///
  /// In de, this message translates to:
  /// **'Geburtsdatum'**
  String get birthdateLabel;

  /// No description provided for @birthdateHint.
  ///
  /// In de, this message translates to:
  /// **'Wird nie angezeigt – andere sehen nur dein Alter.'**
  String get birthdateHint;

  /// No description provided for @genderLabel.
  ///
  /// In de, this message translates to:
  /// **'Ich bin'**
  String get genderLabel;

  /// No description provided for @genderWoman.
  ///
  /// In de, this message translates to:
  /// **'Frau'**
  String get genderWoman;

  /// No description provided for @genderMan.
  ///
  /// In de, this message translates to:
  /// **'Mann'**
  String get genderMan;

  /// No description provided for @genderDiverse.
  ///
  /// In de, this message translates to:
  /// **'Divers'**
  String get genderDiverse;

  /// No description provided for @cityLabel.
  ///
  /// In de, this message translates to:
  /// **'Stadt'**
  String get cityLabel;

  /// No description provided for @cityHint.
  ///
  /// In de, this message translates to:
  /// **'Wird im Profil angezeigt, z. B. Stuttgart'**
  String get cityHint;

  /// No description provided for @bioLabel.
  ///
  /// In de, this message translates to:
  /// **'Über mich (optional)'**
  String get bioLabel;

  /// No description provided for @interestedInLabel.
  ///
  /// In de, this message translates to:
  /// **'Ich möchte kennenlernen'**
  String get interestedInLabel;

  /// No description provided for @interestedInHint.
  ///
  /// In de, this message translates to:
  /// **'Bleibt privat und wird nur für passende Vorschläge verwendet.'**
  String get interestedInHint;

  /// No description provided for @intentionLabel.
  ///
  /// In de, this message translates to:
  /// **'Was suchst du?'**
  String get intentionLabel;

  /// No description provided for @intentionRelationship.
  ///
  /// In de, this message translates to:
  /// **'Eine feste Beziehung'**
  String get intentionRelationship;

  /// No description provided for @intentionOpen.
  ///
  /// In de, this message translates to:
  /// **'Offen für eine Beziehung'**
  String get intentionOpen;

  /// No description provided for @intentionUnsure.
  ///
  /// In de, this message translates to:
  /// **'Bin mir noch nicht sicher'**
  String get intentionUnsure;

  /// No description provided for @intentionPublicLabel.
  ///
  /// In de, this message translates to:
  /// **'Im Profil anzeigen'**
  String get intentionPublicLabel;

  /// No description provided for @intentionPublicHint.
  ///
  /// In de, this message translates to:
  /// **'Dein Ziel zählt immer fürs Matching. Du entscheidest, ob andere es sehen.'**
  String get intentionPublicHint;

  /// No description provided for @ageRangeLabel.
  ///
  /// In de, this message translates to:
  /// **'Alter: {min}–{max}'**
  String ageRangeLabel(int min, int max);

  /// No description provided for @distanceLabel.
  ///
  /// In de, this message translates to:
  /// **'Entfernung: bis {km} km'**
  String distanceLabel(int km);

  /// No description provided for @photosHint.
  ///
  /// In de, this message translates to:
  /// **'Mindestens 1, höchstens 6 Fotos. Auf dem ersten Foto sollte man dich gut erkennen.'**
  String get photosHint;

  /// No description provided for @addPhoto.
  ///
  /// In de, this message translates to:
  /// **'Foto hinzufügen'**
  String get addPhoto;

  /// No description provided for @deletePhotoTitle.
  ///
  /// In de, this message translates to:
  /// **'Foto löschen?'**
  String get deletePhotoTitle;

  /// No description provided for @promptsHint.
  ///
  /// In de, this message translates to:
  /// **'Beantworte 1 bis 3 Prompts – sie sind der beste Gesprächseinstieg.'**
  String get promptsHint;

  /// No description provided for @addPrompt.
  ///
  /// In de, this message translates to:
  /// **'Prompt hinzufügen'**
  String get addPrompt;

  /// No description provided for @choosePrompt.
  ///
  /// In de, this message translates to:
  /// **'Prompt auswählen'**
  String get choosePrompt;

  /// No description provided for @answerLabel.
  ///
  /// In de, this message translates to:
  /// **'Deine Antwort'**
  String get answerLabel;

  /// No description provided for @locationHint.
  ///
  /// In de, this message translates to:
  /// **'Lotus braucht deinen ungefähren Standort, um dir Menschen in deiner Nähe vorzuschlagen. Andere sehen nur die gerundete Entfernung.'**
  String get locationHint;

  /// No description provided for @locationButton.
  ///
  /// In de, this message translates to:
  /// **'Standort freigeben'**
  String get locationButton;

  /// No description provided for @locationDenied.
  ///
  /// In de, this message translates to:
  /// **'Ohne Standort können wir dir keine Vorschläge zeigen. Du kannst ihn in den Einstellungen deines Handys freigeben.'**
  String get locationDenied;

  /// No description provided for @locationSaved.
  ///
  /// In de, this message translates to:
  /// **'Standort gespeichert'**
  String get locationSaved;

  /// No description provided for @finishOnboarding.
  ///
  /// In de, this message translates to:
  /// **'Los geht\'s'**
  String get finishOnboarding;

  /// No description provided for @nameRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib deinen Vornamen ein.'**
  String get nameRequired;

  /// No description provided for @birthdateRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib dein Geburtsdatum an.'**
  String get birthdateRequired;

  /// No description provided for @interestedInRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte wähle mindestens eine Option.'**
  String get interestedInRequired;

  /// No description provided for @photoRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte füge mindestens ein Foto hinzu.'**
  String get photoRequired;

  /// No description provided for @promptRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte beantworte mindestens einen Prompt.'**
  String get promptRequired;

  /// No description provided for @tabDiscover.
  ///
  /// In de, this message translates to:
  /// **'Entdecken'**
  String get tabDiscover;

  /// No description provided for @tabLikes.
  ///
  /// In de, this message translates to:
  /// **'Likes'**
  String get tabLikes;

  /// No description provided for @tabChats.
  ///
  /// In de, this message translates to:
  /// **'Chats'**
  String get tabChats;

  /// No description provided for @tabMe.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get tabMe;

  /// No description provided for @likesLeft.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine Likes mehr} =1{1 Like übrig} other{{count} Likes übrig}}'**
  String likesLeft(int count);

  /// No description provided for @undoButton.
  ///
  /// In de, this message translates to:
  /// **'Rückgängig ({count})'**
  String undoButton(int count);

  /// No description provided for @undoDone.
  ///
  /// In de, this message translates to:
  /// **'Rückgängig gemacht'**
  String get undoDone;

  /// No description provided for @likesUsedUpTitle.
  ///
  /// In de, this message translates to:
  /// **'Für heute ist Schluss'**
  String get likesUsedUpTitle;

  /// No description provided for @likesUsedUpBody.
  ///
  /// In de, this message translates to:
  /// **'Du hast heute alle 20 Likes vergeben. Morgen gibt es neue – bis dahin kannst du deine Likes und Chats ansehen.'**
  String get likesUsedUpBody;

  /// No description provided for @noCandidatesTitle.
  ///
  /// In de, this message translates to:
  /// **'Gerade niemand Neues'**
  String get noCandidatesTitle;

  /// No description provided for @noCandidatesBody.
  ///
  /// In de, this message translates to:
  /// **'Du hast alle passenden Profile in deiner Nähe gesehen. Schau später wieder vorbei oder vergrößere deinen Suchradius.'**
  String get noCandidatesBody;

  /// No description provided for @pass.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get pass;

  /// No description provided for @likeSheetTitle.
  ///
  /// In de, this message translates to:
  /// **'Was gefällt dir?'**
  String get likeSheetTitle;

  /// No description provided for @likeCommentHint.
  ///
  /// In de, this message translates to:
  /// **'Schreib etwas dazu (optional)'**
  String get likeCommentHint;

  /// No description provided for @likeSend.
  ///
  /// In de, this message translates to:
  /// **'Like senden'**
  String get likeSend;

  /// No description provided for @likeThis.
  ///
  /// In de, this message translates to:
  /// **'Gefällt mir'**
  String get likeThis;

  /// No description provided for @matchTitle.
  ///
  /// In de, this message translates to:
  /// **'Ihr mögt euch! 🌸'**
  String get matchTitle;

  /// No description provided for @matchBody.
  ///
  /// In de, this message translates to:
  /// **'Du und {name} habt ein Match.'**
  String matchBody(String name);

  /// No description provided for @matchQueued.
  ///
  /// In de, this message translates to:
  /// **'Euer Chat öffnet sich, sobald ihr beide einen freien Chat-Platz habt.'**
  String get matchQueued;

  /// No description provided for @openChats.
  ///
  /// In de, this message translates to:
  /// **'Zu den Chats'**
  String get openChats;

  /// No description provided for @keepDiscovering.
  ///
  /// In de, this message translates to:
  /// **'Weiter entdecken'**
  String get keepDiscovering;

  /// No description provided for @distanceKm.
  ///
  /// In de, this message translates to:
  /// **'{km} km entfernt'**
  String distanceKm(int km);

  /// No description provided for @verifiedBadge.
  ///
  /// In de, this message translates to:
  /// **'Verifiziert'**
  String get verifiedBadge;

  /// No description provided for @ageAndCity.
  ///
  /// In de, this message translates to:
  /// **'{age} · {city}'**
  String ageAndCity(int age, String city);

  /// No description provided for @likesTitle.
  ///
  /// In de, this message translates to:
  /// **'Wer dich mag'**
  String get likesTitle;

  /// No description provided for @likesSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Zurück-liken kostet keine Likes.'**
  String get likesSubtitle;

  /// No description provided for @likesEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Likes. Gute Dinge brauchen manchmal etwas Zeit.'**
  String get likesEmpty;

  /// No description provided for @likedYourPhoto.
  ///
  /// In de, this message translates to:
  /// **'mag dein Foto'**
  String get likedYourPhoto;

  /// No description provided for @likedYourPrompt.
  ///
  /// In de, this message translates to:
  /// **'mag deine Antwort'**
  String get likedYourPrompt;

  /// No description provided for @likedYou.
  ///
  /// In de, this message translates to:
  /// **'mag dich'**
  String get likedYou;

  /// No description provided for @likeBack.
  ///
  /// In de, this message translates to:
  /// **'Zurück-liken'**
  String get likeBack;

  /// No description provided for @decline.
  ///
  /// In de, this message translates to:
  /// **'Ablehnen'**
  String get decline;

  /// No description provided for @chatsTitle.
  ///
  /// In de, this message translates to:
  /// **'Chats'**
  String get chatsTitle;

  /// No description provided for @chatsEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Matches. Wenn ihr euch gegenseitig mögt, erscheint der Chat hier.'**
  String get chatsEmpty;

  /// No description provided for @chatQueued.
  ///
  /// In de, this message translates to:
  /// **'Wartet auf einen freien Chat-Platz'**
  String get chatQueued;

  /// No description provided for @chatClosed.
  ///
  /// In de, this message translates to:
  /// **'Gespräch beendet'**
  String get chatClosed;

  /// No description provided for @chatClosedStale.
  ///
  /// In de, this message translates to:
  /// **'Eingeschlafen'**
  String get chatClosedStale;

  /// No description provided for @chatNoMessages.
  ///
  /// In de, this message translates to:
  /// **'Sagt Hallo 👋'**
  String get chatNoMessages;

  /// No description provided for @chatYou.
  ///
  /// In de, this message translates to:
  /// **'Du: {message}'**
  String chatYou(String message);

  /// No description provided for @chatSlots.
  ///
  /// In de, this message translates to:
  /// **'{count} von 6 Chats aktiv'**
  String chatSlots(int count);

  /// No description provided for @messageHint.
  ///
  /// In de, this message translates to:
  /// **'Nachricht schreiben …'**
  String get messageHint;

  /// No description provided for @verifyToChat.
  ///
  /// In de, this message translates to:
  /// **'Bitte verifiziere dich, bevor du schreibst – so wissen alle, dass du echt bist.'**
  String get verifyToChat;

  /// No description provided for @verifyNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt verifizieren'**
  String get verifyNow;

  /// No description provided for @chatClosedBanner.
  ///
  /// In de, this message translates to:
  /// **'Dieses Gespräch ist beendet.'**
  String get chatClosedBanner;

  /// No description provided for @chatQueuedBanner.
  ///
  /// In de, this message translates to:
  /// **'Ihr habt ein Match! Der Chat öffnet sich, sobald ihr beide einen freien Platz habt.'**
  String get chatQueuedBanner;

  /// No description provided for @safetyMoney.
  ///
  /// In de, this message translates to:
  /// **'Vorsicht: Hier geht es um Geld. Überweise niemals Geld an Menschen, die du nicht persönlich kennst.'**
  String get safetyMoney;

  /// No description provided for @safetyLink.
  ///
  /// In de, this message translates to:
  /// **'Diese Nachricht enthält einen Link. Öffne nur Links, denen du vertraust.'**
  String get safetyLink;

  /// No description provided for @safetyOffPlatform.
  ///
  /// In de, this message translates to:
  /// **'Die Person möchte die App wechseln. Lerne sie lieber erst hier kennen.'**
  String get safetyOffPlatform;

  /// No description provided for @endChat.
  ///
  /// In de, this message translates to:
  /// **'Gespräch beenden'**
  String get endChat;

  /// No description provided for @endChatTitle.
  ///
  /// In de, this message translates to:
  /// **'Gespräch beenden?'**
  String get endChatTitle;

  /// No description provided for @endChatBody.
  ///
  /// In de, this message translates to:
  /// **'Ihr könnt danach nicht mehr schreiben. Eine freundliche Nachricht zum Abschied ist optional.'**
  String get endChatBody;

  /// No description provided for @goodbyeDefault.
  ///
  /// In de, this message translates to:
  /// **'Danke für das nette Gespräch – ich glaube, wir passen nicht ganz zusammen. Alles Gute dir!'**
  String get goodbyeDefault;

  /// No description provided for @goodbyeLabel.
  ///
  /// In de, this message translates to:
  /// **'Abschiedsnachricht (optional)'**
  String get goodbyeLabel;

  /// No description provided for @block.
  ///
  /// In de, this message translates to:
  /// **'Blockieren'**
  String get block;

  /// No description provided for @blockTitle.
  ///
  /// In de, this message translates to:
  /// **'{name} blockieren?'**
  String blockTitle(String name);

  /// No description provided for @blockBody.
  ///
  /// In de, this message translates to:
  /// **'Ihr seht euch nicht mehr und euer Chat wird beendet.'**
  String get blockBody;

  /// No description provided for @report.
  ///
  /// In de, this message translates to:
  /// **'Melden'**
  String get report;

  /// No description provided for @reportTitle.
  ///
  /// In de, this message translates to:
  /// **'{name} melden'**
  String reportTitle(String name);

  /// No description provided for @reportReasonFake.
  ///
  /// In de, this message translates to:
  /// **'Fake-Profil'**
  String get reportReasonFake;

  /// No description provided for @reportReasonScam.
  ///
  /// In de, this message translates to:
  /// **'Betrug / fragt nach Geld'**
  String get reportReasonScam;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In de, this message translates to:
  /// **'Belästigung'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonInappropriate.
  ///
  /// In de, this message translates to:
  /// **'Unangemessene Inhalte'**
  String get reportReasonInappropriate;

  /// No description provided for @reportReasonUnderage.
  ///
  /// In de, this message translates to:
  /// **'Wirkt minderjährig'**
  String get reportReasonUnderage;

  /// No description provided for @reportReasonOther.
  ///
  /// In de, this message translates to:
  /// **'Etwas anderes'**
  String get reportReasonOther;

  /// No description provided for @reportDetails.
  ///
  /// In de, this message translates to:
  /// **'Details (optional)'**
  String get reportDetails;

  /// No description provided for @reportSend.
  ///
  /// In de, this message translates to:
  /// **'Meldung senden'**
  String get reportSend;

  /// No description provided for @reportSent.
  ///
  /// In de, this message translates to:
  /// **'Danke. Wir sehen uns die Meldung an.'**
  String get reportSent;

  /// No description provided for @viewProfile.
  ///
  /// In de, this message translates to:
  /// **'Profil ansehen'**
  String get viewProfile;

  /// No description provided for @meTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Profil'**
  String get meTitle;

  /// No description provided for @previewProfile.
  ///
  /// In de, this message translates to:
  /// **'So sehen dich andere'**
  String get previewProfile;

  /// No description provided for @editProfile.
  ///
  /// In de, this message translates to:
  /// **'Über dich'**
  String get editProfile;

  /// No description provided for @editPreferences.
  ///
  /// In de, this message translates to:
  /// **'Suche & Privatsphäre'**
  String get editPreferences;

  /// No description provided for @editPhotos.
  ///
  /// In de, this message translates to:
  /// **'Fotos'**
  String get editPhotos;

  /// No description provided for @editPrompts.
  ///
  /// In de, this message translates to:
  /// **'Prompts'**
  String get editPrompts;

  /// No description provided for @updateLocation.
  ///
  /// In de, this message translates to:
  /// **'Standort aktualisieren'**
  String get updateLocation;

  /// No description provided for @verification.
  ///
  /// In de, this message translates to:
  /// **'Verifizierung'**
  String get verification;

  /// No description provided for @verified.
  ///
  /// In de, this message translates to:
  /// **'Du bist verifiziert'**
  String get verified;

  /// No description provided for @verificationPending.
  ///
  /// In de, this message translates to:
  /// **'Dein Selfie wird geprüft.'**
  String get verificationPending;

  /// No description provided for @verificationRejected.
  ///
  /// In de, this message translates to:
  /// **'Dein Selfie konnte nicht bestätigt werden. Versuch es gern noch einmal.'**
  String get verificationRejected;

  /// No description provided for @notVerified.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht verifiziert – nötig, um zu chatten.'**
  String get notVerified;

  /// No description provided for @adminArea.
  ///
  /// In de, this message translates to:
  /// **'Admin-Bereich'**
  String get adminArea;

  /// No description provided for @signOut.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In de, this message translates to:
  /// **'Konto löschen'**
  String get deleteAccount;

  /// No description provided for @accountRestricted.
  ///
  /// In de, this message translates to:
  /// **'Dein Konto ist eingeschränkt: Du wirst gerade niemandem vorgeschlagen und kannst keine Links senden.'**
  String get accountRestricted;

  /// No description provided for @verificationTitle.
  ///
  /// In de, this message translates to:
  /// **'Selfie-Verifizierung'**
  String get verificationTitle;

  /// No description provided for @verificationIntro.
  ///
  /// In de, this message translates to:
  /// **'Mach ein Selfie mit dieser Geste. Wir vergleichen es mit deinen Fotos – das Selfie sieht niemand außer dem Lotus-Team.'**
  String get verificationIntro;

  /// No description provided for @takeSelfie.
  ///
  /// In de, this message translates to:
  /// **'Selfie aufnehmen'**
  String get takeSelfie;

  /// No description provided for @verificationSubmitted.
  ///
  /// In de, this message translates to:
  /// **'Danke! Wir prüfen dein Selfie so schnell wie möglich.'**
  String get verificationSubmitted;

  /// No description provided for @deleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Konto löschen'**
  String get deleteTitle;

  /// No description provided for @deleteFoundQuestion.
  ///
  /// In de, this message translates to:
  /// **'Hast du jemanden gefunden?'**
  String get deleteFoundQuestion;

  /// No description provided for @deleteFoundYes.
  ///
  /// In de, this message translates to:
  /// **'Ja, ich habe jemanden gefunden 🎉'**
  String get deleteFoundYes;

  /// No description provided for @deleteFoundNo.
  ///
  /// In de, this message translates to:
  /// **'Nein, aus einem anderen Grund'**
  String get deleteFoundNo;

  /// No description provided for @deleteFeedback.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du uns noch etwas sagen? (optional)'**
  String get deleteFeedback;

  /// No description provided for @deleteWarning.
  ///
  /// In de, this message translates to:
  /// **'Alle deine Daten, Fotos, Matches und Nachrichten werden unwiderruflich gelöscht.'**
  String get deleteWarning;

  /// No description provided for @deleteConfirm.
  ///
  /// In de, this message translates to:
  /// **'Endgültig löschen'**
  String get deleteConfirm;

  /// No description provided for @deleteCongrats.
  ///
  /// In de, this message translates to:
  /// **'Wie schön! Genau dafür gibt es Lotus. Alles Gute euch beiden!'**
  String get deleteCongrats;

  /// No description provided for @adminTitle.
  ///
  /// In de, this message translates to:
  /// **'Admin'**
  String get adminTitle;

  /// No description provided for @adminVerifications.
  ///
  /// In de, this message translates to:
  /// **'Selfies'**
  String get adminVerifications;

  /// No description provided for @adminReports.
  ///
  /// In de, this message translates to:
  /// **'Meldungen'**
  String get adminReports;

  /// No description provided for @adminPhotos.
  ///
  /// In de, this message translates to:
  /// **'Fotos'**
  String get adminPhotos;

  /// No description provided for @adminNothing.
  ///
  /// In de, this message translates to:
  /// **'Nichts zu tun 🎉'**
  String get adminNothing;

  /// No description provided for @approve.
  ///
  /// In de, this message translates to:
  /// **'Bestätigen'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In de, this message translates to:
  /// **'Ablehnen'**
  String get reject;

  /// No description provided for @gestureLabel.
  ///
  /// In de, this message translates to:
  /// **'Geste: {gesture}'**
  String gestureLabel(String gesture);

  /// No description provided for @selfieLabel.
  ///
  /// In de, this message translates to:
  /// **'Selfie'**
  String get selfieLabel;

  /// No description provided for @profilePhotosLabel.
  ///
  /// In de, this message translates to:
  /// **'Profilfotos'**
  String get profilePhotosLabel;

  /// No description provided for @reportsAgainst.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Meldung gegen diese Person} other{{count} Meldungen gegen diese Person}}'**
  String reportsAgainst(int count);

  /// No description provided for @reportedBy.
  ///
  /// In de, this message translates to:
  /// **'gemeldet von {name}'**
  String reportedBy(String name);

  /// No description provided for @dismiss.
  ///
  /// In de, this message translates to:
  /// **'Verwerfen'**
  String get dismiss;

  /// No description provided for @restrict.
  ///
  /// In de, this message translates to:
  /// **'Einschränken'**
  String get restrict;

  /// No description provided for @suspend.
  ///
  /// In de, this message translates to:
  /// **'Sperren'**
  String get suspend;

  /// No description provided for @errorGeneric.
  ///
  /// In de, this message translates to:
  /// **'Etwas ist schiefgelaufen. Bitte versuch es noch einmal.'**
  String get errorGeneric;

  /// No description provided for @errorDailyLikeLimit.
  ///
  /// In de, this message translates to:
  /// **'Deine 20 Likes für heute sind aufgebraucht.'**
  String get errorDailyLikeLimit;

  /// No description provided for @errorMonthlyUndoLimit.
  ///
  /// In de, this message translates to:
  /// **'Du hast diesen Monat schon 3-mal rückgängig gemacht.'**
  String get errorMonthlyUndoLimit;

  /// No description provided for @errorNothingToUndo.
  ///
  /// In de, this message translates to:
  /// **'Es gibt nichts rückgängig zu machen.'**
  String get errorNothingToUndo;

  /// No description provided for @errorProfileNotAvailable.
  ///
  /// In de, this message translates to:
  /// **'Dieses Profil ist nicht mehr verfügbar.'**
  String get errorProfileNotAvailable;

  /// No description provided for @errorAlreadyLiked.
  ///
  /// In de, this message translates to:
  /// **'Du hast diese Person schon geliked.'**
  String get errorAlreadyLiked;

  /// No description provided for @errorTooYoung.
  ///
  /// In de, this message translates to:
  /// **'Lotus ist erst ab 18 Jahren.'**
  String get errorTooYoung;

  /// No description provided for @errorSuspended.
  ///
  /// In de, this message translates to:
  /// **'Dein Konto wurde gesperrt.'**
  String get errorSuspended;

  /// No description provided for @errorSlowDown.
  ///
  /// In de, this message translates to:
  /// **'Mach mal kurz Pause – du warst sehr schnell unterwegs.'**
  String get errorSlowDown;

  /// No description provided for @errorLinksNotAllowed.
  ///
  /// In de, this message translates to:
  /// **'Dein Konto darf aktuell keine Links senden.'**
  String get errorLinksNotAllowed;

  /// No description provided for @errorAlreadyVerified.
  ///
  /// In de, this message translates to:
  /// **'Du bist bereits verifiziert.'**
  String get errorAlreadyVerified;

  /// No description provided for @errorNotAllowed.
  ///
  /// In de, this message translates to:
  /// **'Das ist gerade nicht möglich.'**
  String get errorNotAllowed;

  /// No description provided for @errorInvalidCode.
  ///
  /// In de, this message translates to:
  /// **'Der Code ist falsch oder abgelaufen.'**
  String get errorInvalidCode;

  /// No description provided for @errorRateLimit.
  ///
  /// In de, this message translates to:
  /// **'Zu viele Versuche. Bitte warte kurz.'**
  String get errorRateLimit;

  /// No description provided for @supportTitle.
  ///
  /// In de, this message translates to:
  /// **'Lotus Plus & Unterstützen'**
  String get supportTitle;

  /// No description provided for @supportIntro.
  ///
  /// In de, this message translates to:
  /// **'Lotus ist kostenlos und bleibt fair: Geld kauft hier keine Likes, keine Sichtbarkeit und keine Vorteile beim Matching. Mit Plus oder einer Spende hilfst du, die Server zu bezahlen – und bekommst ein bisschen Komfort.'**
  String get supportIntro;

  /// No description provided for @plusTitle.
  ///
  /// In de, this message translates to:
  /// **'Lotus Plus'**
  String get plusTitle;

  /// No description provided for @plusFeatureTravel.
  ///
  /// In de, this message translates to:
  /// **'Reisemodus: Profile in einer anderen Stadt sehen, z. B. vor einem Umzug'**
  String get plusFeatureTravel;

  /// No description provided for @plusFeatureStats.
  ///
  /// In de, this message translates to:
  /// **'Statistiken über dein Profil: Welche Fotos und Antworten gut ankommen'**
  String get plusFeatureStats;

  /// No description provided for @plusFeatureFair.
  ///
  /// In de, this message translates to:
  /// **'Kein Einfluss auf deine Sichtbarkeit oder deine Likes – versprochen'**
  String get plusFeatureFair;

  /// No description provided for @plusPerMonth.
  ///
  /// In de, this message translates to:
  /// **'{price} pro Monat'**
  String plusPerMonth(String price);

  /// No description provided for @plusSubscribe.
  ///
  /// In de, this message translates to:
  /// **'Lotus Plus abonnieren'**
  String get plusSubscribe;

  /// No description provided for @plusActiveUntil.
  ///
  /// In de, this message translates to:
  /// **'Aktiv bis {date}'**
  String plusActiveUntil(String date);

  /// No description provided for @plusManageHint.
  ///
  /// In de, this message translates to:
  /// **'Kündigen kannst du jederzeit in Google Play unter „Abos“.'**
  String get plusManageHint;

  /// No description provided for @plusRequired.
  ///
  /// In de, this message translates to:
  /// **'Diese Funktion gehört zu Lotus Plus.'**
  String get plusRequired;

  /// No description provided for @restorePurchases.
  ///
  /// In de, this message translates to:
  /// **'Käufe wiederherstellen'**
  String get restorePurchases;

  /// No description provided for @donateTitle.
  ///
  /// In de, this message translates to:
  /// **'Spenden'**
  String get donateTitle;

  /// No description provided for @donateText.
  ///
  /// In de, this message translates to:
  /// **'Einmalig und freiwillig. Jeder Beitrag hält Lotus werbefrei.'**
  String get donateText;

  /// No description provided for @donateThanks.
  ///
  /// In de, this message translates to:
  /// **'Danke für deine Unterstützung! 🌸'**
  String get donateThanks;

  /// No description provided for @purchasePending.
  ///
  /// In de, this message translates to:
  /// **'Zahlung wird bearbeitet …'**
  String get purchasePending;

  /// No description provided for @purchaseFailed.
  ///
  /// In de, this message translates to:
  /// **'Der Kauf konnte nicht abgeschlossen werden. Dir wird nichts berechnet, wenn er nicht bestätigt wird.'**
  String get purchaseFailed;

  /// No description provided for @storeUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Käufe sind in dieser Version noch nicht möglich. In der Beta ist Lotus Plus kostenlos – frag einfach nach.'**
  String get storeUnavailable;

  /// No description provided for @successContributionTitle.
  ///
  /// In de, this message translates to:
  /// **'Danke sagen?'**
  String get successContributionTitle;

  /// No description provided for @successContributionText.
  ///
  /// In de, this message translates to:
  /// **'Wenn Lotus dir geholfen hat: Ein einmaliger Beitrag hilft, dass andere auch jemanden finden. Ganz freiwillig.'**
  String get successContributionText;

  /// No description provided for @successContributionButton.
  ///
  /// In de, this message translates to:
  /// **'Beitrag leisten ({price})'**
  String successContributionButton(String price);

  /// No description provided for @travelTitle.
  ///
  /// In de, this message translates to:
  /// **'Reisemodus'**
  String get travelTitle;

  /// No description provided for @travelIntro.
  ///
  /// In de, this message translates to:
  /// **'Sieh Profile an einem anderen Ort – z. B. vor einem Umzug oder einer längeren Reise. Dort wirst du mit dem Hinweis „zu Besuch“ angezeigt, nicht häufiger als andere.'**
  String get travelIntro;

  /// No description provided for @travelCity.
  ///
  /// In de, this message translates to:
  /// **'Ziel'**
  String get travelCity;

  /// No description provided for @travelDays.
  ///
  /// In de, this message translates to:
  /// **'Dauer: {days} Tage'**
  String travelDays(int days);

  /// No description provided for @travelStart.
  ///
  /// In de, this message translates to:
  /// **'Reisemodus starten'**
  String get travelStart;

  /// No description provided for @travelActive.
  ///
  /// In de, this message translates to:
  /// **'Du bist gerade in {city} – bis {date}.'**
  String travelActive(String city, String date);

  /// No description provided for @travelEnd.
  ///
  /// In de, this message translates to:
  /// **'Reisemodus beenden'**
  String get travelEnd;

  /// No description provided for @travelVisiting.
  ///
  /// In de, this message translates to:
  /// **'zu Besuch'**
  String get travelVisiting;

  /// No description provided for @statsTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine Statistiken'**
  String get statsTitle;

  /// No description provided for @statsImpressions.
  ///
  /// In de, this message translates to:
  /// **'So oft wurdest du in den letzten 7 Tagen gezeigt'**
  String get statsImpressions;

  /// No description provided for @statsLikes.
  ///
  /// In de, this message translates to:
  /// **'Likes in den letzten 30 Tagen'**
  String get statsLikes;

  /// No description provided for @statsComments.
  ///
  /// In de, this message translates to:
  /// **'davon mit Kommentar'**
  String get statsComments;

  /// No description provided for @statsMatches.
  ///
  /// In de, this message translates to:
  /// **'Matches in den letzten 30 Tagen'**
  String get statsMatches;

  /// No description provided for @statsElements.
  ///
  /// In de, this message translates to:
  /// **'Was gut ankommt'**
  String get statsElements;

  /// No description provided for @statsElementLine.
  ///
  /// In de, this message translates to:
  /// **'{likes} Likes · {comments} Kommentare'**
  String statsElementLine(int likes, int comments);

  /// No description provided for @notificationsTitle.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen'**
  String get notificationsTitle;

  /// No description provided for @notificationsIntro.
  ///
  /// In de, this message translates to:
  /// **'Lotus schickt nur das Nötigste – nie Werbung und nie Nachrichtentexte.'**
  String get notificationsIntro;

  /// No description provided for @notifyMessages.
  ///
  /// In de, this message translates to:
  /// **'Neue Nachrichten'**
  String get notifyMessages;

  /// No description provided for @notifyMatches.
  ///
  /// In de, this message translates to:
  /// **'Neue Matches & freie Chats'**
  String get notifyMatches;

  /// No description provided for @notifyLikes.
  ///
  /// In de, this message translates to:
  /// **'Jemand mag dich (höchstens alle 6 Stunden)'**
  String get notifyLikes;

  /// No description provided for @pushOpen.
  ///
  /// In de, this message translates to:
  /// **'Öffnen'**
  String get pushOpen;

  /// No description provided for @imprint.
  ///
  /// In de, this message translates to:
  /// **'Impressum'**
  String get imprint;

  /// No description provided for @imprintIncomplete.
  ///
  /// In de, this message translates to:
  /// **'Impressum unvollständig – bitte app/lib/legal/legal_info.dart ausfüllen.'**
  String get imprintIncomplete;

  /// No description provided for @imprintProvider.
  ///
  /// In de, this message translates to:
  /// **'Angaben gemäß § 5 DDG'**
  String get imprintProvider;

  /// No description provided for @imprintContact.
  ///
  /// In de, this message translates to:
  /// **'Kontakt'**
  String get imprintContact;

  /// No description provided for @imprintPhone.
  ///
  /// In de, this message translates to:
  /// **'Telefon'**
  String get imprintPhone;

  /// No description provided for @imprintEmail.
  ///
  /// In de, this message translates to:
  /// **'E-Mail'**
  String get imprintEmail;

  /// No description provided for @imprintVat.
  ///
  /// In de, this message translates to:
  /// **'Umsatzsteuer-Identifikationsnummer gemäß § 27a UStG'**
  String get imprintVat;

  /// No description provided for @imprintEconomicId.
  ///
  /// In de, this message translates to:
  /// **'Wirtschafts-Identifikationsnummer gemäß § 139c AO'**
  String get imprintEconomicId;

  /// No description provided for @imprintResponsible.
  ///
  /// In de, this message translates to:
  /// **'Verantwortlich für den Inhalt nach § 18 Abs. 2 MStV'**
  String get imprintResponsible;

  /// No description provided for @imprintDsa.
  ///
  /// In de, this message translates to:
  /// **'Zentrale Kontaktstelle nach Art. 11 und 12 DSA'**
  String get imprintDsa;

  /// No description provided for @imprintDsaText.
  ///
  /// In de, this message translates to:
  /// **'Für Behörden, die EU-Kommission, das Gremium für digitale Dienste sowie für Nutzer:innen: {email}. Wir kommunizieren auf Deutsch und Englisch. Anfragen werden von einem Menschen bearbeitet.'**
  String imprintDsaText(String email);

  /// No description provided for @imprintDispute.
  ///
  /// In de, this message translates to:
  /// **'Verbraucherstreitbeilegung'**
  String get imprintDispute;

  /// No description provided for @imprintDisputeText.
  ///
  /// In de, this message translates to:
  /// **'Wir sind nicht bereit und nicht verpflichtet, an Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen.'**
  String get imprintDisputeText;

  /// No description provided for @adminGrantPlus.
  ///
  /// In de, this message translates to:
  /// **'Lotus Plus vergeben'**
  String get adminGrantPlus;

  /// No description provided for @adminGrantPlusHint.
  ///
  /// In de, this message translates to:
  /// **'E-Mail-Adresse des Kontos'**
  String get adminGrantPlusHint;

  /// No description provided for @adminGrantPlusDone.
  ///
  /// In de, this message translates to:
  /// **'Plus aktiv bis {date}'**
  String adminGrantPlusDone(String date);

  /// No description provided for @errorPlusRequired.
  ///
  /// In de, this message translates to:
  /// **'Diese Funktion gehört zu Lotus Plus.'**
  String get errorPlusRequired;

  /// No description provided for @errorPurchase.
  ///
  /// In de, this message translates to:
  /// **'Der Kauf konnte nicht bestätigt werden.'**
  String get errorPurchase;

  /// No description provided for @errorProfileNotFound.
  ///
  /// In de, this message translates to:
  /// **'Kein Profil mit dieser E-Mail-Adresse gefunden.'**
  String get errorProfileNotFound;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
