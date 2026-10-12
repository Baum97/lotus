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
      );
}

class Photo {
  const Photo({required this.id, required this.storagePath, required this.position, this.url});

  final String id;
  final String storagePath;
  final int position;
  final String? url;

  Photo withUrl(String? url) => Photo(id: id, storagePath: storagePath, position: position, url: url);

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
        id: json['id'] as String,
        storagePath: json['storage_path'] as String,
        position: json['position'] as int,
      );
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
  });

  final Set<Gender> interestedIn;
  final Intention intention;
  final bool intentionPublic;
  final int ageMin;
  final int ageMax;
  final int maxDistanceKm;

  factory MatchPreferences.fromJson(Map<String, dynamic> json) => MatchPreferences(
        interestedIn: (json['interested_in'] as List).map((g) => Gender.fromDb(g as String)).toSet(),
        intention: Intention.fromDb(json['intention'] as String),
        intentionPublic: json['intention_public'] as bool,
        ageMin: json['age_min'] as int,
        ageMax: json['age_max'] as int,
        maxDistanceKm: json['max_distance_km'] as int,
      );
}

/// Eigene Profildaten zum Bearbeiten.
class OwnProfile {
  const OwnProfile({
    required this.displayName,
    required this.gender,
    this.bio,
    this.city,
    this.age,
  });

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
