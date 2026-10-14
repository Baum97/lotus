// Datenmodelle, die den Rückgaben der Supabase-Funktionen entsprechen
// (siehe supabase/migrations). Enum-Werte nutzen die Datenbank-Schlüssel.

enum Gender {
  woman,
  man,
  diverse;

  static Gender fromDb(String value) => Gender.values.byName(value);
}

enum Intention {
  relationship,
  openToRelationship,
  unsure;

  String get db => switch (this) {
    Intention.relationship => 'relationship',
    Intention.openToRelationship => 'open_to_relationship',
    Intention.unsure => 'unsure',
  };

  static Intention fromDb(String value) => values.firstWhere((i) => i.db == value);
  static Intention? tryFromDb(Object? value) => value == null ? null : fromDb(value as String);
}

enum ChildrenWish {
  want,
  dontWant,
  open,
  haveKids;

  String get db => switch (this) {
    ChildrenWish.want => 'want',
    ChildrenWish.dontWant => 'dont_want',
    ChildrenWish.open => 'open',
    ChildrenWish.haveKids => 'have_kids',
  };

  static ChildrenWish? tryFromDb(Object? value) => value == null ? null : values.firstWhere((c) => c.db == value);
}

enum Smoking {
  never,
  sometimes,
  regularly;

  static Smoking? tryFromDb(Object? value) => value == null ? null : Smoking.values.byName(value as String);
}

enum LikeTarget {
  photo,
  prompt;

  static LikeTarget? tryFromDb(Object? value) => value == null ? null : LikeTarget.values.byName(value as String);
}

enum MatchState {
  queued,
  active,
  closed;

  static MatchState fromDb(String value) => MatchState.values.byName(value);
}

enum VerificationStatus {
  awaitingSelfie,
  pending,
  approved,
  rejected;

  static VerificationStatus? tryFromDb(Object? value) => switch (value) {
    'awaiting_selfie' => VerificationStatus.awaitingSelfie,
    'pending' => VerificationStatus.pending,
    'approved' => VerificationStatus.approved,
    'rejected' => VerificationStatus.rejected,
    _ => null,
  };
}

enum ReportReason { fake, scam, harassment, inappropriate, underage, other }

enum TrustStatus {
  active,
  restricted,
  suspended;

  static TrustStatus? tryFromDb(Object? value) => value == null ? null : TrustStatus.values.byName(value as String);
}

DateTime? _date(Object? value) => value == null ? null : DateTime.parse(value as String).toLocal();

class MyStatus {
  const MyStatus({
    required this.hasProfile,
    required this.hasPreferences,
    required this.hasLocation,
    required this.photoCount,
    required this.promptCount,
    required this.displayName,
    required this.verified,
    required this.verificationStatus,
    required this.trustStatus,
    required this.isAdmin,
    required this.likesRemaining,
    required this.undosRemaining,
    required this.activeChats,
    this.plusUntil,
    this.travelCity,
    this.travelUntil,
  });

  final bool hasProfile;
  final bool hasPreferences;
  final bool hasLocation;
  final int photoCount;
  final int promptCount;
  final String? displayName;
  final bool verified;
  final VerificationStatus? verificationStatus;
  final TrustStatus? trustStatus;
  final bool isAdmin;
  final int likesRemaining;
  final int undosRemaining;
  final int activeChats;
  final DateTime? plusUntil;
  final String? travelCity;
  final DateTime? travelUntil;

  bool get hasPlus => plusUntil != null;

  /// Onboarding ist abgeschlossen, wenn alles für Vorschläge Nötige vorhanden ist.
  bool get onboardingComplete => hasProfile && hasPreferences && hasLocation && photoCount > 0 && promptCount > 0;

  factory MyStatus.fromJson(Map<String, dynamic> json) => MyStatus(
    hasProfile: json['has_profile'] as bool,
    hasPreferences: json['has_preferences'] as bool,
    hasLocation: json['has_location'] as bool,
    photoCount: json['photo_count'] as int,
    promptCount: json['prompt_count'] as int,
    displayName: json['display_name'] as String?,
    verified: json['verified'] as bool,
    verificationStatus: VerificationStatus.tryFromDb(json['verification_status']),
    trustStatus: TrustStatus.tryFromDb(json['trust_status']),
    isAdmin: json['is_admin'] as bool,
    likesRemaining: json['likes_remaining'] as int,
    undosRemaining: json['undos_remaining'] as int,
    activeChats: json['active_chats'] as int,
    plusUntil: _date(json['plus_until']),
    travelCity: json['travel_city'] as String?,
    travelUntil: _date(json['travel_until']),
  );
}

/// Öffentliche Profilangaben (Vorschlag oder Profilkarte).
class ProfileSummary {
  const ProfileSummary({
    required this.id,
    required this.displayName,
    required this.age,
    this.gender,
    this.city,
    this.intention,
    this.bio,
    this.distanceKm,
    required this.verified,
    this.traveling = false,
    this.children,
    this.smoking,
  });

  final String id;
  final String displayName;
  final int age;
  final Gender? gender;
  final String? city;
  final Intention? intention;
  final String? bio;
  final int? distanceKm;
  final bool verified;

  /// Ist gerade im Reisemodus hier ("zu Besuch").
  final bool traveling;

  /// Nur gesetzt, wenn die Person diese Angaben öffentlich gemacht hat.
  final ChildrenWish? children;
  final Smoking? smoking;

  factory ProfileSummary.fromJson(Map<String, dynamic> json) => ProfileSummary(
    id: json['id'] as String,
    displayName: json['display_name'] as String,
    age: json['age'] as int,
    gender: json['gender'] == null ? null : Gender.fromDb(json['gender'] as String),
    city: json['city'] as String?,
    intention: Intention.tryFromDb(json['intention']),
    bio: json['bio'] as String?,
    distanceKm: json['distance_km'] as int?,
    verified: json['verified'] as bool? ?? false,
    traveling: json['traveling'] as bool? ?? false,
    children: ChildrenWish.tryFromDb(json['children']),
    smoking: Smoking.tryFromDb(json['smoking']),
  );
}

class Photo {
  const Photo({required this.id, required this.storagePath, required this.position, this.url});

  final String id;
  final String storagePath;
  final int position;
  final String? url;

  Photo withUrl(String? url) => Photo(id: id, storagePath: storagePath, position: position, url: url);

  factory Photo.fromJson(Map<String, dynamic> json) =>
      Photo(id: json['id'] as String, storagePath: json['storage_path'] as String, position: json['position'] as int);
}

class Prompt {
  const Prompt({required this.id, required this.text});

  final int id;
  final String text;

  factory Prompt.fromJson(Map<String, dynamic> json) => Prompt(id: json['id'] as int, text: json['text'] as String);
}

class PromptAnswer {
  const PromptAnswer({
    required this.id,
    required this.promptId,
    required this.promptText,
    required this.answer,
    required this.position,
  });

  final String id;
  final int promptId;
  final String promptText;
  final String answer;
  final int position;

  factory PromptAnswer.fromJson(Map<String, dynamic> json) => PromptAnswer(
    id: json['id'] as String,
    promptId: json['prompt_id'] as int,
    promptText: (json['prompts'] as Map<String, dynamic>)['text'] as String,
    answer: json['answer'] as String,
    position: json['position'] as int,
  );
}

/// Vollständiges Profil zum Anzeigen: Angaben, Fotos und Prompt-Antworten.
class FullProfile {
  const FullProfile({required this.summary, required this.photos, required this.prompts});

  final ProfileSummary summary;
  final List<Photo> photos;
  final List<PromptAnswer> prompts;
}

class MatchPreferences {
  const MatchPreferences({
    required this.interestedIn,
    required this.intention,
    required this.intentionPublic,
    required this.ageMin,
    required this.ageMax,
    required this.maxDistanceKm,
    this.children,
    this.smoking,
    this.lifestylePublic = true,
    this.childrenDealbreaker = false,
    this.smokingDealbreaker = false,
  });

  final Set<Gender> interestedIn;
  final Intention intention;
  final bool intentionPublic;
  final int ageMin;
  final int ageMax;
  final int maxDistanceKm;
  final ChildrenWish? children;
  final Smoking? smoking;
  final bool lifestylePublic;
  final bool childrenDealbreaker;
  final bool smokingDealbreaker;

  factory MatchPreferences.fromJson(Map<String, dynamic> json) => MatchPreferences(
    interestedIn: (json['interested_in'] as List).map((g) => Gender.fromDb(g as String)).toSet(),
    intention: Intention.fromDb(json['intention'] as String),
    intentionPublic: json['intention_public'] as bool,
    ageMin: json['age_min'] as int,
    ageMax: json['age_max'] as int,
    maxDistanceKm: json['max_distance_km'] as int,
    children: ChildrenWish.tryFromDb(json['children']),
    smoking: Smoking.tryFromDb(json['smoking']),
    lifestylePublic: json['lifestyle_public'] as bool? ?? true,
    childrenDealbreaker: json['children_dealbreaker'] as bool? ?? false,
    smokingDealbreaker: json['smoking_dealbreaker'] as bool? ?? false,
  );
}

/// Eigene Profildaten zum Bearbeiten.
class OwnProfile {
  const OwnProfile({required this.displayName, required this.gender, this.bio, this.city, this.age});

  final String displayName;
  final Gender gender;
  final String? bio;
  final String? city;
  final int? age;
}

class IncomingLike {
  const IncomingLike({
    required this.fromUser,
    required this.displayName,
    required this.age,
    this.targetType,
    this.targetId,
    this.comment,
    required this.createdAt,
  });

  final String fromUser;
  final String displayName;
  final int age;
  final LikeTarget? targetType;
  final String? targetId;
  final String? comment;
  final DateTime createdAt;

  factory IncomingLike.fromJson(Map<String, dynamic> json) => IncomingLike(
    fromUser: json['from_user'] as String,
    displayName: json['display_name'] as String,
    age: json['age'] as int,
    targetType: LikeTarget.tryFromDb(json['target_type']),
    targetId: json['target_id'] as String?,
    comment: json['comment'] as String?,
    createdAt: _date(json['created_at'])!,
  );
}

enum CloseReason {
  ended,
  stale,
  blocked;

  static CloseReason? tryFromDb(Object? value) => value == null ? null : CloseReason.values.byName(value as String);
}

class MatchSummary {
  const MatchSummary({
    required this.matchId,
    required this.state,
    this.closeReason,
    required this.otherUser,
    required this.displayName,
    required this.verified,
    required this.lastActivityAt,
    this.lastMessage,
    required this.lastMessageMine,
  });

  final String matchId;
  final MatchState state;
  final CloseReason? closeReason;
  final String otherUser;
  final String displayName;
  final bool verified;
  final DateTime lastActivityAt;
  final String? lastMessage;
  final bool lastMessageMine;

  factory MatchSummary.fromJson(Map<String, dynamic> json) => MatchSummary(
    matchId: json['match_id'] as String,
    state: MatchState.fromDb(json['state'] as String),
    closeReason: CloseReason.tryFromDb(json['close_reason']),
    otherUser: json['other_user'] as String,
    displayName: json['display_name'] as String,
    verified: json['verified'] as bool,
    lastActivityAt: _date(json['last_activity_at'])!,
    lastMessage: json['last_message'] as String?,
    lastMessageMine: json['last_message_mine'] as bool? ?? false,
  );
}

enum SafetyFlag { money, link, offPlatform }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.safetyFlag,
  });

  final String id;
  final String senderId;
  final String body;
  final DateTime createdAt;
  final SafetyFlag? safetyFlag;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    senderId: json['sender_id'] as String,
    body: json['body'] as String,
    createdAt: _date(json['created_at'])!,
    safetyFlag: switch (json['safety_flag']) {
      'money' => SafetyFlag.money,
      'link' => SafetyFlag.link,
      'off_platform' => SafetyFlag.offPlatform,
      _ => null,
    },
  );
}

class VerificationRequest {
  const VerificationRequest({required this.id, required this.gesture, required this.status});

  final String id;
  final String gesture;
  final VerificationStatus status;

  factory VerificationRequest.fromJson(Map<String, dynamic> json) => VerificationRequest(
    id: json['request_id'] as String,
    gesture: json['gesture'] as String,
    status: VerificationStatus.tryFromDb(json['status'])!,
  );
}

// --- Admin -----------------------------------------------------------------

class PendingVerification {
  const PendingVerification({
    required this.requestId,
    required this.userId,
    required this.displayName,
    required this.gesture,
    required this.selfiePath,
    required this.photoPaths,
  });

  final String requestId;
  final String userId;
  final String displayName;
  final String gesture;
  final String selfiePath;
  final List<String> photoPaths;

  factory PendingVerification.fromJson(Map<String, dynamic> json) => PendingVerification(
    requestId: json['request_id'] as String,
    userId: json['user_id'] as String,
    displayName: json['display_name'] as String,
    gesture: json['gesture'] as String,
    selfiePath: json['selfie_path'] as String,
    photoPaths: (json['photo_paths'] as List).cast<String>(),
  );
}

class AdminPhoto {
  const AdminPhoto({required this.photoId, required this.userId, required this.displayName, required this.storagePath});

  final String photoId;
  final String userId;
  final String displayName;
  final String storagePath;

  factory AdminPhoto.fromJson(Map<String, dynamic> json) => AdminPhoto(
    photoId: json['photo_id'] as String,
    userId: json['user_id'] as String,
    displayName: json['display_name'] as String,
    storagePath: json['storage_path'] as String,
  );
}

class AdminReport {
  const AdminReport({
    required this.reportId,
    required this.reported,
    required this.reportedName,
    required this.reporterName,
    required this.reason,
    this.details,
    required this.reportsAgainstUser,
    this.trustStatus,
  });

  final String reportId;
  final String reported;
  final String reportedName;
  final String reporterName;
  final ReportReason reason;
  final String? details;
  final int reportsAgainstUser;
  final TrustStatus? trustStatus;

  factory AdminReport.fromJson(Map<String, dynamic> json) => AdminReport(
    reportId: json['report_id'] as String,
    reported: json['reported'] as String,
    reportedName: json['reported_name'] as String,
    reporterName: json['reporter_name'] as String,
    reason: ReportReason.values.byName(json['reason'] as String),
    details: json['details'] as String?,
    reportsAgainstUser: json['reports_against_user'] as int,
    trustStatus: TrustStatus.tryFromDb(json['trust_status']),
  );
}

// --- Lotus Plus & Benachrichtigungen -----------------------------------------

class StatElement {
  const StatElement({required this.isPhoto, required this.label, required this.likes, required this.comments});

  final bool isPhoto;
  final String label;
  final int likes;
  final int comments;
}

class MyStats {
  const MyStats({
    required this.impressions7d,
    required this.likes30d,
    required this.comments30d,
    required this.matches30d,
    required this.elements,
  });

  final int impressions7d;
  final int likes30d;
  final int comments30d;
  final int matches30d;
  final List<StatElement> elements;

  factory MyStats.fromJson(Map<String, dynamic> json) => MyStats(
    impressions7d: json['impressions_7d'] as int,
    likes30d: json['likes_30d'] as int,
    comments30d: json['comments_30d'] as int,
    matches30d: json['matches_30d'] as int,
    elements: [
      for (final e in json['elements'] as List)
        StatElement(
          isPhoto: (e as Map)['type'] == 'photo',
          label: e['label'] as String,
          likes: e['likes'] as int,
          comments: e['comments'] as int,
        ),
    ],
  );
}

class Consent {
  const Consent({required this.version, required this.grantedAt});

  final String version;
  final DateTime grantedAt;

  factory Consent.fromJson(Map<String, dynamic> json) =>
      Consent(version: json['version'] as String, grantedAt: _date(json['granted_at'])!);
}

class NotificationSettings {
  const NotificationSettings({this.messages = true, this.matches = true, this.likes = true});

  final bool messages;
  final bool matches;
  final bool likes;

  NotificationSettings copyWith({bool? messages, bool? matches, bool? likes}) => NotificationSettings(
    messages: messages ?? this.messages,
    matches: matches ?? this.matches,
    likes: likes ?? this.likes,
  );

  Map<String, bool> toJson() => {'messages': messages, 'matches': matches, 'likes': likes};

  factory NotificationSettings.fromJson(Map<String, dynamic> json) => NotificationSettings(
    messages: json['messages'] as bool,
    matches: json['matches'] as bool,
    likes: json['likes'] as bool,
  );
}

// --- Beta: Einladungen, Feedback, Kennzahlen ---------------------------------

/// Ob die Beta gerade nur mit Einladung offen ist und ob man selbst Zugang hat.
class AccessStatus {
  const AccessStatus({required this.required, required this.hasAccess, required this.onWaitlist});

  final bool required;
  final bool hasAccess;
  final bool onWaitlist;

  factory AccessStatus.fromJson(Map<String, dynamic> json) => AccessStatus(
    required: json['required'] as bool,
    hasAccess: json['has_access'] as bool,
    onWaitlist: json['on_waitlist'] as bool,
  );
}

enum FeedbackCategory { bug, idea, other }

class Invite {
  const Invite({
    required this.code,
    this.region,
    this.note,
    required this.uses,
    required this.maxUses,
    this.expiresAt,
    required this.createdAt,
  });

  final String code;
  final String? region;
  final String? note;
  final int uses;
  final int maxUses;
  final DateTime? expiresAt;
  final DateTime createdAt;

  bool get usedUp => uses >= maxUses;
  bool isExpired(DateTime now) => expiresAt != null && expiresAt!.isBefore(now);

  /// Lesbarer: "K7M2-PQ4X"
  String get formatted => code.length == 8 ? '${code.substring(0, 4)}-${code.substring(4)}' : code;

  factory Invite.fromJson(Map<String, dynamic> json) => Invite(
    code: json['code'] as String,
    region: json['region'] as String?,
    note: json['note'] as String?,
    uses: json['uses'] as int,
    maxUses: json['max_uses'] as int,
    expiresAt: json['expires_at'] == null ? null : DateTime.parse(json['expires_at'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class WaitlistEntry {
  const WaitlistEntry({required this.userId, required this.email, required this.city, required this.createdAt});

  final String userId;
  final String email;
  final String city;
  final DateTime createdAt;

  factory WaitlistEntry.fromJson(Map<String, dynamic> json) => WaitlistEntry(
    userId: json['user_id'] as String,
    email: json['email'] as String,
    city: json['city'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class FeedbackItem {
  const FeedbackItem({
    required this.id,
    this.displayName,
    required this.category,
    required this.message,
    this.appVersion,
    this.platform,
    required this.createdAt,
  });

  final String id;
  final String? displayName;
  final FeedbackCategory category;
  final String message;
  final String? appVersion;
  final String? platform;
  final DateTime createdAt;

  factory FeedbackItem.fromJson(Map<String, dynamic> json) => FeedbackItem(
    id: json['id'] as String,
    displayName: json['display_name'] as String?,
    category: FeedbackCategory.values.byName(json['category'] as String),
    message: json['message'] as String,
    appVersion: json['app_version'] as String?,
    platform: json['platform'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

/// Wer sucht wen in einer Region (nur auffindbare Profile).
class BalanceRow {
  const BalanceRow({required this.region, required this.gender, required this.seeking, required this.count});

  final String region;
  final Gender gender;
  final List<Gender> seeking;
  final int count;

  factory BalanceRow.fromJson(Map<String, dynamic> json) => BalanceRow(
    region: json['region'] as String,
    gender: Gender.fromDb(json['gender'] as String),
    seeking: [
      for (final g in (json['seeking'] as String).split('+'))
        if (g.isNotEmpty) Gender.fromDb(g),
    ],
    count: json['count'] as int,
  );
}

/// Kennzahlen für die Beta – nur Summen, keine Einzelpersonen (siehe `admin_metrics`).
class BetaMetrics {
  const BetaMetrics(this._json);

  final Map<String, dynamic> _json;

  int _int(String section, String key) => ((_json[section] as Map<String, dynamic>?)?[key] as num?)?.toInt() ?? 0;

  int get periodDays => (_json['period_days'] as num).toInt();

  int get profiles => _int('users', 'profiles');
  int get active7d => _int('users', 'active_7d');
  int get discoverable => _int('users', 'discoverable');
  int get verified => _int('users', 'verified');
  int get withPlus => _int('users', 'with_plus');
  int get newInPeriod => _int('users', 'new_in_period');

  int get likes => _int('funnel', 'likes');
  int get likesWithComment => _int('funnel', 'likes_with_comment');
  int get matches => _int('funnel', 'matches');
  int get conversations => _int('funnel', 'conversations');
  int get deepConversations => _int('funnel', 'deep_conversations');
  int get closedEnded => _int('funnel', 'closed_ended');
  int get closedStale => _int('funnel', 'closed_stale');
  int get closedBlocked => _int('funnel', 'closed_blocked');

  int get daysWithLikes => _int('like_budget', 'days_with_likes');
  int get daysUsedUp => _int('like_budget', 'days_used_up');
  int get undos => (_json['undos'] as num?)?.toInt() ?? 0;

  int get deletions => _int('deletions', 'total');
  int get foundSomeone => _int('deletions', 'found_someone');

  int get openReports => _int('open', 'reports');
  int get openVerifications => _int('open', 'verifications');
  int get openFeedback => _int('open', 'feedback');
  int get waitlist => _int('open', 'waitlist');

  bool get invitesRequired => (_json['invites'] as Map<String, dynamic>?)?['required'] as bool? ?? false;
  int get inviteCodes => _int('invites', 'codes');
  int get invitesRedeemed => _int('invites', 'redeemed');
  int get admittedFromWaitlist => _int('invites', 'from_waitlist');

  List<BalanceRow> get balance => [
    for (final row in (_json['balance'] as List? ?? const [])) BalanceRow.fromJson(row as Map<String, dynamic>),
  ];
}
