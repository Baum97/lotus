import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

/// Fehler mit stabilem Schlüssel aus der Datenbank (z. B. `daily_like_limit_reached`).
class LotusException implements Exception {
  const LotusException(this.key, [this.cause]);

  final String key;
  final Object? cause;

  @override
  String toString() => 'LotusException($key)';
}

/// Ergebnis eines Likes: bei einem Match die Match-ID.
class LikeResult {
  const LikeResult(this.matchId);

  final String? matchId;
  bool get isMatch => matchId != null;
}

/// Zugriff auf das Lotus-Backend. Alle Regeln (Limits, Sichtbarkeit) setzt der Server durch.
class LotusApi {
  LotusApi(this._client);

  final SupabaseClient _client;

  static const _signedUrlSeconds = 60 * 60;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw LotusException(_errorKey(e), e);
    } on AuthException catch (e) {
      throw LotusException(e.code ?? 'auth_error', e);
    } on StorageException catch (e) {
      throw LotusException('storage_error', e);
    }
  }

  /// Unsere SQL-Funktionen werfen Schlüssel als Fehlermeldung; Check-Constraints haben eigene Namen.
  static String _errorKey(PostgrestException e) {
    final message = e.message;
    if (RegExp(r'^[a-z_]+$').hasMatch(message)) return message;
    if (message.contains('birthdate')) return 'too_young';
    if (e.code == '42501' || message.contains('row-level security')) return 'not_allowed';
    return 'unknown';
  }

  // --- Anmeldung ------------------------------------------------------------

  Future<void> sendLoginCode(String email) =>
      _guard(() => _client.auth.signInWithOtp(email: email.trim(), shouldCreateUser: true));

  Future<void> verifyLoginCode(String email, String code) =>
      _guard(() => _client.auth.verifyOTP(email: email.trim(), token: code.trim(), type: OtpType.email));

  Future<void> signOut() => _client.auth.signOut();

  // --- Status & eigenes Profil ------------------------------------------------

  Future<MyStatus> myStatus() => _guard(() async {
        final rows = await _client.rpc('get_my_status') as List;
        return MyStatus.fromJson(rows.single as Map<String, dynamic>);
      });

  Future<OwnProfile?> ownProfile() => _guard(() async {
        final row = await _client
            .from('profiles')
            .select('display_name, gender, bio, city')
            .eq('id', currentUserId!)
            .maybeSingle();
        if (row == null) return null;
        final card = await profileSummary(currentUserId!);
        return OwnProfile(
          displayName: row['display_name'] as String,
          gender: Gender.fromDb(row['gender'] as String),
          bio: row['bio'] as String?,
          city: row['city'] as String?,
          age: card?.age,
        );
      });

  Future<MatchPreferences?> ownPreferences() => _guard(() async {
        final row = await _client.from('match_preferences').select().eq('user_id', currentUserId!).maybeSingle();
        return row == null ? null : MatchPreferences.fromJson(row);
      });

  /// Legt das Profil an oder aktualisiert es. [birthdate] ist nur beim Anlegen nötig.
  Future<void> saveProfile({
    required String displayName,
    DateTime? birthdate,
    required Gender gender,
    String? bio,
    String? city,
    required MatchPreferences preferences,
  }) =>
      _guard(() => _client.rpc('save_profile', params: {
            'p_display_name': displayName,
            'p_birthdate': birthdate == null ? null : _isoDate(birthdate),
            'p_gender': gender.name,
            'p_bio': bio,
            'p_city': city,
            'p_interested_in': preferences.interestedIn.map((g) => g.name).toList(),
            'p_intention': preferences.intention.db,
            'p_intention_public': preferences.intentionPublic,
            'p_age_min': preferences.ageMin,
            'p_age_max': preferences.ageMax,
            'p_max_distance_km': preferences.maxDistanceKm,
          }));

  /// Speichert den Standort auf ca. 1 km gerundet – genauer braucht ihn niemand.
  Future<void> setLocation(double lat, double lon) => _guard(() => _client.rpc('set_location', params: {
        'p_lat': double.parse(lat.toStringAsFixed(2)),
        'p_lon': double.parse(lon.toStringAsFixed(2)),
      }));

  // --- Fotos & Prompts --------------------------------------------------------

  Future<List<Photo>> photosOf(String userId) => _guard(() async {
        final rows = await _client
            .from('photos')
            .select('id, storage_path, position')
            .eq('user_id', userId)
            .order('position');
        final photos = rows.map(Photo.fromJson).toList();
        final urls = await signedUrls('photos', photos.map((p) => p.storagePath).toList());
        return [for (final p in photos) p.withUrl(urls[p.storagePath])];
      });

  Future<void> uploadPhoto(Uint8List bytes, int position) => _guard(() async {
        final path = '$currentUserId/${_randomId()}.jpg';
        await _client.storage.from('photos').uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        await _client.from('photos').insert({
          'user_id': currentUserId,
          'storage_path': path,
          'position': position,
        });
      });

  Future<void> deletePhoto(Photo photo) => _guard(() async {
        await _client.from('photos').delete().eq('id', photo.id);
        await _client.storage.from('photos').remove([photo.storagePath]);
        // Positionen lückenlos halten
        final rest = await _client
            .from('photos')
            .select('id, position')
            .eq('user_id', currentUserId!)
            .order('position');
        for (var i = 0; i < rest.length; i++) {
          if (rest[i]['position'] != i) {
            await _client.from('photos').update({'position': i}).eq('id', rest[i]['id'] as String);
          }
        }
      });

  Future<List<Prompt>> prompts() => _guard(() async {
        final rows = await _client.from('prompts').select('id, text').order('id');
        return rows.map(Prompt.fromJson).toList();
      });

  Future<List<PromptAnswer>> promptAnswersOf(String userId) => _guard(() async {
        final rows = await _client
            .from('prompt_answers')
            .select('id, prompt_id, answer, position, prompts(text)')
            .eq('user_id', userId)
            .order('position');
        return rows.map(PromptAnswer.fromJson).toList();
      });

  Future<void> savePromptAnswer({String? id, required int promptId, required String answer, required int position}) =>
      _guard(() async {
        if (id == null) {
          await _client.from('prompt_answers').insert({
            'user_id': currentUserId,
            'prompt_id': promptId,
            'answer': answer.trim(),
            'position': position,
          });
        } else {
          await _client.from('prompt_answers').update({'prompt_id': promptId, 'answer': answer.trim()}).eq('id', id);
        }
      });

  Future<void> deletePromptAnswer(String id) => _guard(() async {
        await _client.from('prompt_answers').delete().eq('id', id);
        final rest = await _client
            .from('prompt_answers')
            .select('id, position')
            .eq('user_id', currentUserId!)
            .order('position');
        for (var i = 0; i < rest.length; i++) {
          if (rest[i]['position'] != i) {
            await _client.from('prompt_answers').update({'position': i}).eq('id', rest[i]['id'] as String);
          }
        }
      });

  Future<Map<String, String>> signedUrls(String bucket, List<String> paths) async {
    if (paths.isEmpty) return {};
    final results = await _client.storage.from(bucket).createSignedUrlsResult(paths, _signedUrlSeconds);
    return {
      for (final r in results)
        if (r is SignedUrlSuccess) r.path: r.signedUrl,
    };
  }

  // --- Profile anderer --------------------------------------------------------

  Future<ProfileSummary?> profileSummary(String userId) => _guard(() async {
        final rows = await _client.rpc('get_profile', params: {'p_user': userId}) as List;
        return rows.isEmpty ? null : ProfileSummary.fromJson(rows.single as Map<String, dynamic>);
      });

  Future<FullProfile> fullProfile(ProfileSummary summary) async {
    final results = await Future.wait([photosOf(summary.id), promptAnswersOf(summary.id)]);
    return FullProfile(
      summary: summary,
      photos: results[0] as List<Photo>,
      prompts: results[1] as List<PromptAnswer>,
    );
  }

  // --- Entdecken --------------------------------------------------------------

  Future<List<ProfileSummary>> candidates({int limit = 10}) => _guard(() async {
        final rows = await _client.rpc('get_candidates', params: {'p_limit': limit}) as List;
        return rows.map((r) => ProfileSummary.fromJson(r as Map<String, dynamic>)).toList();
      });

  Future<LikeResult> like(String userId, {LikeTarget? targetType, String? targetId, String? comment}) =>
      _guard(() async {
        final matchId = await _client.rpc('like_profile', params: {
          'p_to': userId,
          'p_target_type': targetType?.name,
          'p_target_id': targetId,
          'p_comment': (comment?.trim().isEmpty ?? true) ? null : comment!.trim(),
        });
        return LikeResult(matchId as String?);
      });

  Future<void> pass(String userId) => _guard(() => _client.rpc('pass_profile', params: {'p_to': userId}));

  /// Gibt die ID des wiederhergestellten Profils zurück.
  Future<String> undoLastPass() => _guard(() async => await _client.rpc('undo_last_pass') as String);

  Future<List<IncomingLike>> incomingLikes() => _guard(() async {
        final rows = await _client.rpc('get_incoming_likes') as List;
        return rows.map((r) => IncomingLike.fromJson(r as Map<String, dynamic>)).toList();
      });

  // --- Matches & Chat ---------------------------------------------------------

  Future<List<MatchSummary>> matches() => _guard(() async {
        final rows = await _client.rpc('get_matches') as List;
        return rows.map((r) => MatchSummary.fromJson(r as Map<String, dynamic>)).toList();
      });

  Stream<List<ChatMessage>> messages(String matchId) => _client
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('match_id', matchId)
      .order('created_at', ascending: true)
      .map((rows) => rows.map(ChatMessage.fromJson).toList());

  Future<void> sendMessage(String matchId, String body) => _guard(() => _client.from('messages').insert({
        'match_id': matchId,
        'sender_id': currentUserId,
        'body': body.trim(),
      }));

  Future<void> closeMatch(String matchId, {String? goodbye}) => _guard(() => _client.rpc('close_match', params: {
        'p_match': matchId,
        'p_goodbye': (goodbye?.trim().isEmpty ?? true) ? null : goodbye!.trim(),
      }));

  Future<void> block(String userId) =>
      _guard(() => _client.from('blocks').insert({'blocker': currentUserId, 'blocked': userId}));

  Future<void> report(String userId, ReportReason reason, {String? details}) =>
      _guard(() => _client.from('reports').insert({
            'reporter': currentUserId,
            'reported': userId,
            'reason': reason.name,
            'details': (details?.trim().isEmpty ?? true) ? null : details!.trim(),
          }));

  // --- Verifizierung ----------------------------------------------------------

  Future<VerificationRequest> startVerification() => _guard(() async {
        final rows = await _client.rpc('start_verification') as List;
        return VerificationRequest.fromJson(rows.single as Map<String, dynamic>);
      });

  Future<void> submitVerification(String requestId, Uint8List selfie) => _guard(() async {
        final path = '$currentUserId/${_randomId()}.jpg';
        await _client.storage.from('selfies').uploadBinary(
              path,
              selfie,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        await _client.rpc('submit_verification', params: {'p_request': requestId, 'p_selfie_path': path});
      });

  // --- Push -------------------------------------------------------------------

  Future<void> registerDeviceToken(String token, String platform) => _guard(
      () => _client.rpc('register_device_token', params: {'p_token': token, 'p_platform': platform}));

  // --- Konto ------------------------------------------------------------------

  /// Löscht zuerst die eigenen Dateien, dann alle Daten. Speichert nur anonym, ob jemand gefunden wurde.
  Future<void> deleteAccount({required bool foundSomeone, String? feedback}) => _guard(() async {
        for (final bucket in ['photos', 'selfies']) {
          final files = await _client.storage.from(bucket).list(path: currentUserId);
          if (files.isNotEmpty) {
            await _client.storage.from(bucket).remove([for (final f in files) '$currentUserId/${f.name}']);
          }
        }
        await _client.rpc('delete_my_account', params: {'p_found_someone': foundSomeone, 'p_feedback': feedback});
        // Das Konto existiert nicht mehr – nur noch die lokale Sitzung entfernen.
        await _client.auth.signOut(scope: SignOutScope.local);
      });

  // --- Admin ------------------------------------------------------------------

  Future<List<PendingVerification>> adminPendingVerifications() => _guard(() async {
        final rows = await _client.rpc('admin_pending_verifications') as List;
        return rows.map((r) => PendingVerification.fromJson(r as Map<String, dynamic>)).toList();
      });

  Future<void> adminReviewVerification(String requestId, {required bool approve}) => _guard(() =>
      _client.rpc('admin_review_verification', params: {'p_request': requestId, 'p_approve': approve}));

  Future<List<AdminPhoto>> adminRecentPhotos() => _guard(() async {
        final rows = await _client.rpc('admin_recent_photos', params: {'p_limit': 100}) as List;
        return rows.map((r) => AdminPhoto.fromJson(r as Map<String, dynamic>)).toList();
      });

  Future<void> adminSetPhotoModeration(String photoId, {required bool approve}) => _guard(() => _client.rpc(
      'admin_set_photo_moderation',
      params: {'p_photo': photoId, 'p_state': approve ? 'approved' : 'rejected'}));

  Future<List<AdminReport>> adminOpenReports() => _guard(() async {
        final rows = await _client.rpc('admin_open_reports') as List;
        return rows.map((r) => AdminReport.fromJson(r as Map<String, dynamic>)).toList();
      });

  Future<void> adminResolveReport(String reportId, {TrustStatus? status}) => _guard(() => _client.rpc(
      'admin_resolve_report',
      params: {'p_report': reportId, 'p_status': status?.name, 'p_reason': null}));

  // --- Hilfen -----------------------------------------------------------------

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static final _random = Random.secure();

  static String _randomId() =>
      List.generate(16, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}
