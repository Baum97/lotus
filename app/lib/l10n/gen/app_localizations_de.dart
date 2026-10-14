// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Lotus';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get saved => 'Gespeichert';

  @override
  String get next => 'Weiter';

  @override
  String get back => 'Zurück';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get close => 'Schließen';

  @override
  String get delete => 'Löschen';

  @override
  String get loginTitle => 'Willkommen bei Lotus';

  @override
  String get loginSubtitle => 'Weniger wischen, mehr kennenlernen.';

  @override
  String get emailLabel => 'E-Mail-Adresse';

  @override
  String get sendCode => 'Code senden';

  @override
  String codeSentTo(String email) {
    return 'Wir haben dir einen 6-stelligen Code an $email geschickt.';
  }

  @override
  String get codeLabel => 'Code';

  @override
  String get verifyCode => 'Anmelden';

  @override
  String get changeEmail => 'Andere E-Mail verwenden';

  @override
  String get invalidEmail => 'Bitte gib eine gültige E-Mail-Adresse ein.';

  @override
  String get loginLegal => 'Mit der Anmeldung bestätigst du, dass du mindestens 18 Jahre alt bist.';

  @override
  String get notConfigured =>
      'Die App ist noch nicht mit einem Server verbunden. Starte sie mit --dart-define=SUPABASE_URL=… und --dart-define=SUPABASE_KEY=… (siehe README).';

  @override
  String get onboardingTitle => 'Dein Profil';

  @override
  String get stepBasics => 'Über dich';

  @override
  String get stepPreferences => 'Wen suchst du?';

  @override
  String get stepPhotos => 'Deine Fotos';

  @override
  String get stepPrompts => 'Deine Prompts';

  @override
  String get stepLocation => 'Dein Standort';

  @override
  String stepOf(int step, int total) {
    return 'Schritt $step von $total';
  }

  @override
  String get nameLabel => 'Vorname';

  @override
  String get birthdateLabel => 'Geburtsdatum';

  @override
  String get birthdateHint => 'Wird nie angezeigt – andere sehen nur dein Alter.';

  @override
  String get genderLabel => 'Ich bin';

  @override
  String get genderWoman => 'Frau';

  @override
  String get genderMan => 'Mann';

  @override
  String get genderDiverse => 'Divers';

  @override
  String get cityLabel => 'Stadt';

  @override
  String get cityHint => 'Wird im Profil angezeigt, z. B. Stuttgart';

  @override
  String get bioLabel => 'Über mich (optional)';

  @override
  String get interestedInLabel => 'Ich möchte kennenlernen';

  @override
  String get interestedInHint => 'Bleibt privat und wird nur für passende Vorschläge verwendet.';

  @override
  String get intentionLabel => 'Was suchst du?';

  @override
  String get intentionRelationship => 'Eine feste Beziehung';

  @override
  String get intentionOpen => 'Offen für eine Beziehung';

  @override
  String get intentionUnsure => 'Bin mir noch nicht sicher';

  @override
  String get intentionPublicLabel => 'Im Profil anzeigen';

  @override
  String get intentionPublicHint => 'Dein Ziel zählt immer fürs Matching. Du entscheidest, ob andere es sehen.';

  @override
  String ageRangeLabel(int min, int max) {
    return 'Alter: $min–$max';
  }

  @override
  String distanceLabel(int km) {
    return 'Entfernung: bis $km km';
  }

  @override
  String get photosHint => 'Mindestens 1, höchstens 6 Fotos. Auf dem ersten Foto sollte man dich gut erkennen.';

  @override
  String get addPhoto => 'Foto hinzufügen';

  @override
  String get deletePhotoTitle => 'Foto löschen?';

  @override
  String get promptsHint => 'Beantworte 1 bis 3 Prompts – sie sind der beste Gesprächseinstieg.';

  @override
  String get addPrompt => 'Prompt hinzufügen';

  @override
  String get choosePrompt => 'Prompt auswählen';

  @override
  String get answerLabel => 'Deine Antwort';

  @override
  String get locationHint =>
      'Lotus braucht deinen ungefähren Standort, um dir Menschen in deiner Nähe vorzuschlagen. Andere sehen nur die gerundete Entfernung.';

  @override
  String get locationButton => 'Standort freigeben';

  @override
  String get locationDenied =>
      'Ohne Standort können wir dir keine Vorschläge zeigen. Du kannst ihn in den Einstellungen deines Handys freigeben.';

  @override
  String get locationSaved => 'Standort gespeichert';

  @override
  String get finishOnboarding => 'Los geht\'s';

  @override
  String get nameRequired => 'Bitte gib deinen Vornamen ein.';

  @override
  String get birthdateRequired => 'Bitte gib dein Geburtsdatum an.';

  @override
  String get interestedInRequired => 'Bitte wähle mindestens eine Option.';

  @override
  String get photoRequired => 'Bitte füge mindestens ein Foto hinzu.';

  @override
  String get promptRequired => 'Bitte beantworte mindestens einen Prompt.';

  @override
  String get tabDiscover => 'Entdecken';

  @override
  String get tabLikes => 'Likes';

  @override
  String get tabChats => 'Chats';

  @override
  String get tabMe => 'Profil';

  @override
  String likesLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Likes übrig',
      one: '1 Like übrig',
      zero: 'Keine Likes mehr',
    );
    return '$_temp0';
  }

  @override
  String undoButton(int count) {
    return 'Rückgängig ($count)';
  }

  @override
  String get undoDone => 'Rückgängig gemacht';

  @override
  String get likesUsedUpTitle => 'Für heute ist Schluss';

  @override
  String get likesUsedUpBody =>
      'Du hast heute alle 20 Likes vergeben. Morgen gibt es neue – bis dahin kannst du deine Likes und Chats ansehen.';

  @override
  String get noCandidatesTitle => 'Gerade niemand Neues';

  @override
  String get noCandidatesBody =>
      'Du hast alle passenden Profile in deiner Nähe gesehen. Schau später wieder vorbei oder vergrößere deinen Suchradius.';

  @override
  String get pass => 'Weiter';

  @override
  String get likeSheetTitle => 'Was gefällt dir?';

  @override
  String get likeCommentHint => 'Schreib etwas dazu (optional)';

  @override
  String get likeSend => 'Like senden';

  @override
  String get likeThis => 'Gefällt mir';

  @override
  String get matchTitle => 'Ihr mögt euch! 🌸';

  @override
  String matchBody(String name) {
    return 'Du und $name habt ein Match.';
  }

  @override
  String get matchQueued => 'Euer Chat öffnet sich, sobald ihr beide einen freien Chat-Platz habt.';

  @override
  String get openChats => 'Zu den Chats';

  @override
  String get keepDiscovering => 'Weiter entdecken';

  @override
  String distanceKm(int km) {
    return '$km km entfernt';
  }

  @override
  String get verifiedBadge => 'Verifiziert';

  @override
  String ageAndCity(int age, String city) {
    return '$age · $city';
  }

  @override
  String get likesTitle => 'Wer dich mag';

  @override
  String get likesSubtitle => 'Zurück-liken kostet keine Likes.';

  @override
  String get likesEmpty => 'Noch keine Likes. Gute Dinge brauchen manchmal etwas Zeit.';

  @override
  String get likedYourPhoto => 'mag dein Foto';

  @override
  String get likedYourPrompt => 'mag deine Antwort';

  @override
  String get likedYou => 'mag dich';

  @override
  String get likeBack => 'Zurück-liken';

  @override
  String get decline => 'Ablehnen';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get chatsEmpty => 'Noch keine Matches. Wenn ihr euch gegenseitig mögt, erscheint der Chat hier.';

  @override
  String get chatQueued => 'Wartet auf einen freien Chat-Platz';

  @override
  String get chatClosed => 'Gespräch beendet';

  @override
  String get chatClosedStale => 'Eingeschlafen';

  @override
  String get chatNoMessages => 'Sagt Hallo 👋';

  @override
  String chatYou(String message) {
    return 'Du: $message';
  }

  @override
  String chatSlots(int count) {
    return '$count von 6 Chats aktiv';
  }

  @override
  String get messageHint => 'Nachricht schreiben …';

  @override
  String get verifyToChat => 'Bitte verifiziere dich, bevor du schreibst – so wissen alle, dass du echt bist.';

  @override
  String get verifyNow => 'Jetzt verifizieren';

  @override
  String get chatClosedBanner => 'Dieses Gespräch ist beendet.';

  @override
  String get chatQueuedBanner => 'Ihr habt ein Match! Der Chat öffnet sich, sobald ihr beide einen freien Platz habt.';

  @override
  String get safetyMoney =>
      'Vorsicht: Hier geht es um Geld. Überweise niemals Geld an Menschen, die du nicht persönlich kennst.';

  @override
  String get safetyLink => 'Diese Nachricht enthält einen Link. Öffne nur Links, denen du vertraust.';

  @override
  String get safetyOffPlatform => 'Die Person möchte die App wechseln. Lerne sie lieber erst hier kennen.';

  @override
  String get endChat => 'Gespräch beenden';

  @override
  String get endChatTitle => 'Gespräch beenden?';

  @override
  String get endChatBody =>
      'Ihr könnt danach nicht mehr schreiben. Eine freundliche Nachricht zum Abschied ist optional.';

  @override
  String get goodbyeDefault =>
      'Danke für das nette Gespräch – ich glaube, wir passen nicht ganz zusammen. Alles Gute dir!';

  @override
  String get goodbyeLabel => 'Abschiedsnachricht (optional)';

  @override
  String get block => 'Blockieren';

  @override
  String blockTitle(String name) {
    return '$name blockieren?';
  }

  @override
  String get blockBody => 'Ihr seht euch nicht mehr und euer Chat wird beendet.';

  @override
  String get report => 'Melden';

  @override
  String reportTitle(String name) {
    return '$name melden';
  }

  @override
  String get reportReasonFake => 'Fake-Profil';

  @override
  String get reportReasonScam => 'Betrug / fragt nach Geld';

  @override
  String get reportReasonHarassment => 'Belästigung';

  @override
  String get reportReasonInappropriate => 'Unangemessene Inhalte';

  @override
  String get reportReasonUnderage => 'Wirkt minderjährig';

  @override
  String get reportReasonOther => 'Etwas anderes';

  @override
  String get reportDetails => 'Details (optional)';

  @override
  String get reportSend => 'Meldung senden';

  @override
  String get reportSent => 'Danke. Wir sehen uns die Meldung an.';

  @override
  String get viewProfile => 'Profil ansehen';

  @override
  String get meTitle => 'Dein Profil';

  @override
  String get previewProfile => 'So sehen dich andere';

  @override
  String get editProfile => 'Über dich';

  @override
  String get editPreferences => 'Suche & Privatsphäre';

  @override
  String get editPhotos => 'Fotos';

  @override
  String get editPrompts => 'Prompts';

  @override
  String get updateLocation => 'Standort aktualisieren';

  @override
  String get verification => 'Verifizierung';

  @override
  String get verified => 'Du bist verifiziert';

  @override
  String get verificationPending => 'Dein Selfie wird geprüft.';

  @override
  String get verificationRejected => 'Dein Selfie konnte nicht bestätigt werden. Versuch es gern noch einmal.';

  @override
  String get notVerified => 'Noch nicht verifiziert – nötig, um zu chatten.';

  @override
  String get adminArea => 'Admin-Bereich';

  @override
  String get signOut => 'Abmelden';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get accountRestricted =>
      'Dein Konto ist eingeschränkt: Du wirst gerade niemandem vorgeschlagen und kannst keine Links senden.';

  @override
  String get verificationTitle => 'Selfie-Verifizierung';

  @override
  String get verificationIntro =>
      'Mach ein Selfie mit dieser Geste. Wir vergleichen es mit deinen Fotos – das Selfie sieht niemand außer dem Lotus-Team.';

  @override
  String get takeSelfie => 'Selfie aufnehmen';

  @override
  String get verificationSubmitted => 'Danke! Wir prüfen dein Selfie so schnell wie möglich.';

  @override
  String get deleteTitle => 'Konto löschen';

  @override
  String get deleteFoundQuestion => 'Hast du jemanden gefunden?';

  @override
  String get deleteFoundYes => 'Ja, ich habe jemanden gefunden 🎉';

  @override
  String get deleteFoundNo => 'Nein, aus einem anderen Grund';

  @override
  String get deleteFeedback => 'Möchtest du uns noch etwas sagen? (optional)';

  @override
  String get deleteWarning => 'Alle deine Daten, Fotos, Matches und Nachrichten werden unwiderruflich gelöscht.';

  @override
  String get deleteConfirm => 'Endgültig löschen';

  @override
  String get deleteCongrats => 'Wie schön! Genau dafür gibt es Lotus. Alles Gute euch beiden!';

  @override
  String get adminTitle => 'Admin';

  @override
  String get adminVerifications => 'Selfies';

  @override
  String get adminReports => 'Meldungen';

  @override
  String get adminPhotos => 'Fotos';

  @override
  String get adminNothing => 'Nichts zu tun 🎉';

  @override
  String get approve => 'Bestätigen';

  @override
  String get reject => 'Ablehnen';

  @override
  String gestureLabel(String gesture) {
    return 'Geste: $gesture';
  }

  @override
  String get selfieLabel => 'Selfie';

  @override
  String get profilePhotosLabel => 'Profilfotos';

  @override
  String reportsAgainst(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Meldungen gegen diese Person',
      one: '1 Meldung gegen diese Person',
    );
    return '$_temp0';
  }

  @override
  String reportedBy(String name) {
    return 'gemeldet von $name';
  }

  @override
  String get dismiss => 'Verwerfen';

  @override
  String get restrict => 'Einschränken';

  @override
  String get suspend => 'Sperren';

  @override
  String get errorGeneric => 'Etwas ist schiefgelaufen. Bitte versuch es noch einmal.';

  @override
  String get errorDailyLikeLimit => 'Deine 20 Likes für heute sind aufgebraucht.';

  @override
  String get errorMonthlyUndoLimit => 'Du hast diesen Monat schon 3-mal rückgängig gemacht.';

  @override
  String get errorNothingToUndo => 'Es gibt nichts rückgängig zu machen.';

  @override
  String get errorProfileNotAvailable => 'Dieses Profil ist nicht mehr verfügbar.';

  @override
  String get errorAlreadyLiked => 'Du hast diese Person schon geliked.';

  @override
  String get errorTooYoung => 'Lotus ist erst ab 18 Jahren.';

  @override
  String get errorSuspended => 'Dein Konto wurde gesperrt.';

  @override
  String get errorSlowDown => 'Mach mal kurz Pause – du warst sehr schnell unterwegs.';

  @override
  String get errorLinksNotAllowed => 'Dein Konto darf aktuell keine Links senden.';

  @override
  String get errorAlreadyVerified => 'Du bist bereits verifiziert.';

  @override
  String get errorNotAllowed => 'Das ist gerade nicht möglich.';

  @override
  String get errorInvalidCode => 'Der Code ist falsch oder abgelaufen.';

  @override
  String get errorRateLimit => 'Zu viele Versuche. Bitte warte kurz.';

  @override
  String get supportTitle => 'Lotus Plus & Unterstützen';

  @override
  String get supportIntro =>
      'Lotus ist kostenlos und bleibt fair: Geld kauft hier keine Likes, keine Sichtbarkeit und keine Vorteile beim Matching. Mit Plus oder einer Spende hilfst du, die Server zu bezahlen – und bekommst ein bisschen Komfort.';

  @override
  String get plusTitle => 'Lotus Plus';

  @override
  String get plusFeatureTravel => 'Reisemodus: Profile in einer anderen Stadt sehen, z. B. vor einem Umzug';

  @override
  String get plusFeatureStats => 'Statistiken über dein Profil: Welche Fotos und Antworten gut ankommen';

  @override
  String get plusFeatureFair => 'Kein Einfluss auf deine Sichtbarkeit oder deine Likes – versprochen';

  @override
  String plusPerMonth(String price) {
    return '$price pro Monat';
  }

  @override
  String get plusSubscribe => 'Lotus Plus abonnieren';

  @override
  String plusActiveUntil(String date) {
    return 'Aktiv bis $date';
  }

  @override
  String get plusManageHint => 'Kündigen kannst du jederzeit in Google Play unter „Abos“.';

  @override
  String get plusRequired => 'Diese Funktion gehört zu Lotus Plus.';

  @override
  String get restorePurchases => 'Käufe wiederherstellen';

  @override
  String get donateTitle => 'Spenden';

  @override
  String get donateText => 'Einmalig und freiwillig. Jeder Beitrag hält Lotus werbefrei.';

  @override
  String get donateThanks => 'Danke für deine Unterstützung! 🌸';

  @override
  String get purchasePending => 'Zahlung wird bearbeitet …';

  @override
  String get purchaseFailed =>
      'Der Kauf konnte nicht abgeschlossen werden. Dir wird nichts berechnet, wenn er nicht bestätigt wird.';

  @override
  String get storeUnavailable =>
      'Käufe sind in dieser Version noch nicht möglich. In der Beta ist Lotus Plus kostenlos – frag einfach nach.';

  @override
  String get successContributionTitle => 'Danke sagen?';

  @override
  String get successContributionText =>
      'Wenn Lotus dir geholfen hat: Ein einmaliger Beitrag hilft, dass andere auch jemanden finden. Ganz freiwillig.';

  @override
  String successContributionButton(String price) {
    return 'Beitrag leisten ($price)';
  }

  @override
  String get travelTitle => 'Reisemodus';

  @override
  String get travelIntro =>
      'Sieh Profile an einem anderen Ort – z. B. vor einem Umzug oder einer längeren Reise. Dort wirst du mit dem Hinweis „zu Besuch“ angezeigt, nicht häufiger als andere.';

  @override
  String get travelCity => 'Ziel';

  @override
  String travelDays(int days) {
    return 'Dauer: $days Tage';
  }

  @override
  String get travelStart => 'Reisemodus starten';

  @override
  String travelActive(String city, String date) {
    return 'Du bist gerade in $city – bis $date.';
  }

  @override
  String get travelEnd => 'Reisemodus beenden';

  @override
  String get travelVisiting => 'zu Besuch';

  @override
  String get statsTitle => 'Deine Statistiken';

  @override
  String get statsImpressions => 'So oft wurdest du in den letzten 7 Tagen gezeigt';

  @override
  String get statsLikes => 'Likes in den letzten 30 Tagen';

  @override
  String get statsComments => 'davon mit Kommentar';

  @override
  String get statsMatches => 'Matches in den letzten 30 Tagen';

  @override
  String get statsElements => 'Was gut ankommt';

  @override
  String statsElementLine(int likes, int comments) {
    return '$likes Likes · $comments Kommentare';
  }

  @override
  String get notificationsTitle => 'Benachrichtigungen';

  @override
  String get notificationsIntro => 'Lotus schickt nur das Nötigste – nie Werbung und nie Nachrichtentexte.';

  @override
  String get notifyMessages => 'Neue Nachrichten';

  @override
  String get notifyMatches => 'Neue Matches & freie Chats';

  @override
  String get notifyLikes => 'Jemand mag dich (höchstens alle 6 Stunden)';

  @override
  String get pushOpen => 'Öffnen';

  @override
  String get imprint => 'Impressum';

  @override
  String get imprintIncomplete => 'Impressum unvollständig – bitte app/lib/legal/legal_info.dart ausfüllen.';

  @override
  String get imprintProvider => 'Angaben gemäß § 5 DDG';

  @override
  String get imprintContact => 'Kontakt';

  @override
  String get imprintPhone => 'Telefon';

  @override
  String get imprintEmail => 'E-Mail';

  @override
  String get imprintVat => 'Umsatzsteuer-Identifikationsnummer gemäß § 27a UStG';

  @override
  String get imprintEconomicId => 'Wirtschafts-Identifikationsnummer gemäß § 139c AO';

  @override
  String get imprintResponsible => 'Verantwortlich für den Inhalt nach § 18 Abs. 2 MStV';

  @override
  String get imprintDsa => 'Zentrale Kontaktstelle nach Art. 11 und 12 DSA';

  @override
  String imprintDsaText(String email) {
    return 'Für Behörden, die EU-Kommission, das Gremium für digitale Dienste sowie für Nutzer:innen: $email. Wir kommunizieren auf Deutsch und Englisch. Anfragen werden von einem Menschen bearbeitet.';
  }

  @override
  String get imprintDispute => 'Verbraucherstreitbeilegung';

  @override
  String get imprintDisputeText =>
      'Wir sind nicht bereit und nicht verpflichtet, an Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen.';

  @override
  String get adminGrantPlus => 'Lotus Plus vergeben';

  @override
  String get adminGrantPlusHint => 'E-Mail-Adresse des Kontos';

  @override
  String adminGrantPlusDone(String date) {
    return 'Plus aktiv bis $date';
  }

  @override
  String get errorPlusRequired => 'Diese Funktion gehört zu Lotus Plus.';

  @override
  String get errorPurchase => 'Der Kauf konnte nicht bestätigt werden.';

  @override
  String get errorProfileNotFound => 'Kein Profil mit dieser E-Mail-Adresse gefunden.';

  @override
  String get optionalHint => 'Optional – tippe erneut, um die Auswahl aufzuheben.';

  @override
  String get childrenLabel => 'Kinderwunsch';

  @override
  String get childrenWant => 'Möchte Kinder';

  @override
  String get childrenDontWant => 'Möchte keine Kinder';

  @override
  String get childrenOpen => 'Offen';

  @override
  String get childrenHave => 'Habe Kinder';

  @override
  String get childrenDealbreaker => 'Nur Menschen mit passendem Kinderwunsch zeigen';

  @override
  String get smokingLabel => 'Rauchen';

  @override
  String get smokingNever => 'Nichtraucher:in';

  @override
  String get smokingSometimes => 'Gelegentlich';

  @override
  String get smokingRegularly => 'Raucher:in';

  @override
  String get smokingDealbreaker => 'Keine Raucher:innen zeigen';

  @override
  String get lifestylePublicLabel => 'Kinderwunsch & Rauchen im Profil anzeigen';

  @override
  String get lifestylePublicHint => 'Zählt immer fürs Matching. Ausschlusskriterien wirken in beide Richtungen.';

  @override
  String get consentTitle => 'Deine Einwilligung';

  @override
  String get consentText =>
      'Ich willige ausdrücklich ein, dass Lotus meine Angabe, wen ich kennenlernen möchte, verarbeitet. Diese Angabe kann Rückschlüsse auf meine sexuelle Orientierung zulassen. Sie wird ausschließlich genutzt, um mir passende Menschen vorzuschlagen, und niemandem angezeigt. Ich kann die Einwilligung jederzeit unter Profil → Datenschutz widerrufen; dann werden meine Suchangaben gelöscht und ich bekomme keine Vorschläge mehr.';

  @override
  String get consentRequired => 'Ohne diese Einwilligung kann Lotus dir keine passenden Menschen vorschlagen.';

  @override
  String get privacyTitle => 'Datenschutz';

  @override
  String privacyConsentGiven(String date, String version) {
    return 'Eingewilligt am $date (Version $version)';
  }

  @override
  String get privacyConsentMissing => 'Keine Einwilligung – du bekommst keine Vorschläge.';

  @override
  String get privacyWithdraw => 'Einwilligung widerrufen';

  @override
  String get privacyWithdrawTitle => 'Einwilligung widerrufen?';

  @override
  String get privacyWithdrawBody =>
      'Deine Suchangaben (wen du kennenlernen möchtest, Alter, Entfernung, Dating-Ziel, Kinderwunsch, Rauchen) werden sofort gelöscht. Du wirst niemandem mehr vorgeschlagen und bekommst keine Vorschläge, bis du erneut einwilligst. Deine Matches und Chats bleiben erhalten.';

  @override
  String get privacyGiveConsent => 'Einwilligen und Suche einrichten';

  @override
  String get privacyExport => 'Meine Daten herunterladen';

  @override
  String get privacyExportHint =>
      'Alle Daten, die Lotus über dich gespeichert hat, als JSON-Datei (Art. 15 und 20 DSGVO) – inklusive Download-Links zu deinen Fotos, 24 Stunden gültig.';

  @override
  String get privacyExportDone => 'Deine Datei ist bereit.';

  @override
  String get privacyWithdrawn => 'Einwilligung widerrufen. Deine Suchangaben wurden gelöscht.';

  @override
  String get errorConsentRequired => 'Bitte bestätige zuerst die Einwilligung.';

  @override
  String get copy => 'Kopieren';

  @override
  String get copied => 'Kopiert';

  @override
  String get share => 'Teilen';

  @override
  String get done => 'Fertig';

  @override
  String get errorInvalidInvite => 'Dieser Code ist ungültig, abgelaufen oder schon aufgebraucht.';

  @override
  String get errorInviteRequired => 'Lotus ist gerade nur mit Einladung offen.';

  @override
  String get inviteTitle => 'Lotus ist gerade in der Beta';

  @override
  String get inviteBody =>
      'Damit es in Stuttgart und Ulm von Anfang an passende Menschen gibt, laden wir schrittweise ein. Hast du einen Einladungscode?';

  @override
  String get inviteCodeLabel => 'Einladungscode';

  @override
  String get inviteCodeMissing => 'Bitte gib deinen Einladungscode ein.';

  @override
  String get inviteRedeem => 'Code einlösen';

  @override
  String get waitlistTitle => 'Noch keinen Code?';

  @override
  String get waitlistBody =>
      'Trag dich auf die Warteliste ein. Wir schalten dich frei, sobald es in deiner Gegend genug Leute gibt.';

  @override
  String get waitlistJoin => 'Auf die Warteliste';

  @override
  String get waitlistCityMissing => 'Bitte gib deine Stadt an.';

  @override
  String get waitlistJoined =>
      'Du stehst auf der Warteliste. Wir melden uns, sobald du loslegen kannst – schau einfach ab und zu vorbei.';

  @override
  String get feedbackTitle => 'Feedback & Fehler melden';

  @override
  String get feedbackHint => 'Was hakt, was fehlt, was gefällt dir? Wir lesen alles.';

  @override
  String get feedbackBug => 'Fehler';

  @override
  String get feedbackIdea => 'Idee';

  @override
  String get feedbackOther => 'Sonstiges';

  @override
  String get feedbackMessage => 'Deine Nachricht';

  @override
  String get feedbackSend => 'Senden';

  @override
  String get feedbackEmpty => 'Schreib uns kurz, worum es geht.';

  @override
  String get feedbackThanks => 'Danke! Dein Feedback ist angekommen.';

  @override
  String get feedbackNoProfile => 'ohne Profil';

  @override
  String get feedbackResolve => 'Erledigt';

  @override
  String get adminMetrics => 'Kennzahlen';

  @override
  String get adminInvites => 'Einladungen';

  @override
  String get adminFeedback => 'Feedback';

  @override
  String get adminWaitlist => 'Warteliste';

  @override
  String metricsDays(int days) {
    return '$days Tage';
  }

  @override
  String get metricsUsers => 'Menschen';

  @override
  String get metricsProfiles => 'Profile';

  @override
  String get metricsNew => 'neu im Zeitraum';

  @override
  String get metricsActive7d => 'aktiv (7 Tage)';

  @override
  String get metricsDiscoverable => 'auffindbar';

  @override
  String get metricsVerified => 'verifiziert';

  @override
  String get metricsPlus => 'mit Plus';

  @override
  String get metricsFunnel => 'Vom Like zum Gespräch';

  @override
  String get metricsFunnelHint => 'Prozent jeweils bezogen auf die Stufe davor (Kommentare und Matches auf Likes).';

  @override
  String get metricsLikes => 'Likes';

  @override
  String get metricsLikesWithComment => 'davon mit Kommentar';

  @override
  String get metricsMatches => 'Matches';

  @override
  String get metricsConversations => 'Gespräche (beide geschrieben)';

  @override
  String get metricsDeepConversations => 'längere Gespräche (20+ Nachrichten)';

  @override
  String get metricsLimits => 'Grenzen & Abschlüsse';

  @override
  String get metricsBudgetUsedUp => 'Tage mit aufgebrauchtem Like-Budget';

  @override
  String get metricsUndos => 'rückgängig gemacht';

  @override
  String get metricsClosedStale => 'eingeschlafen';

  @override
  String get metricsClosedEnded => 'beendet';

  @override
  String get metricsClosedBlocked => 'blockiert';

  @override
  String get metricsBalance => 'Wer sucht wen';

  @override
  String get metricsBalanceHint => 'Auffindbare Profile je Region – zeigt, wen du gezielt einladen solltest.';

  @override
  String metricsSeeks(String gender, String seeking) {
    return '$gender sucht $seeking';
  }

  @override
  String get metricsOutcome => 'Ergebnis';

  @override
  String get metricsDeletions => 'Konten gelöscht';

  @override
  String get metricsFoundSomeone => '„jemanden gefunden“';

  @override
  String get metricsOpen => 'Offen';

  @override
  String get metricsPrivacyNote => 'Nur Summen – keine Einzelpersonen. Gelöschte Konten zählen nur anonym.';

  @override
  String get invitesRequiredOn =>
      'Einladungspflicht ist aktiv: Neue Konten brauchen einen Code oder eine Freischaltung von der Warteliste.';

  @override
  String get invitesRequiredOff => 'Einladungspflicht ist aus – jede:r kann sich registrieren.';

  @override
  String get invitesCreate => 'Einladungscodes erstellen';

  @override
  String get invitesCreateShort => 'Erstellen';

  @override
  String get invitesCount => 'Anzahl Codes';

  @override
  String get invitesMaxUses => 'Nutzungen pro Code';

  @override
  String get invitesRegion => 'Region';

  @override
  String get invitesNoRegion => 'keine';

  @override
  String get invitesNote => 'Notiz';

  @override
  String get invitesNoteHint => 'z. B. Uni-Gruppe, Kletterhalle';

  @override
  String invitesCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Codes erstellt',
      one: '1 Code erstellt',
    );
    return '$_temp0';
  }

  @override
  String get invitesCodes => 'Codes';

  @override
  String get invitesNone => 'Noch keine Codes.';

  @override
  String invitesUses(int uses, int max) {
    return '$uses/$max genutzt';
  }

  @override
  String get invitesExpired => 'abgelaufen';

  @override
  String invitesValidUntil(String date) {
    return 'gültig bis $date';
  }

  @override
  String inviteShareText(String code) {
    return 'Du bist zur Beta von Lotus eingeladen 🌸 Dein Code: $code';
  }

  @override
  String get waitlistEmpty => 'Niemand wartet.';

  @override
  String get waitlistAdmit => 'Freischalten';
}
