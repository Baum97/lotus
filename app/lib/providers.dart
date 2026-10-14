import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/lotus_api.dart';
import 'data/models.dart';
import 'legal/consent.dart';
import 'services/store.dart';

final apiProvider = Provider<LotusApi>((ref) => LotusApi(Supabase.instance.client));

/// Aktuelle Sitzung; ändert sich bei An- und Abmeldung.
final sessionProvider = NotifierProvider<SessionNotifier, Session?>(SessionNotifier.new);

class SessionNotifier extends Notifier<Session?> {
  @override
  Session? build() {
    final auth = Supabase.instance.client.auth;
    final subscription = auth.onAuthStateChange.listen((event) => state = event.session);
    ref.onDispose(subscription.cancel);
    return auth.currentSession;
  }
}

final myStatusProvider = FutureProvider<MyStatus>((ref) {
  ref.watch(sessionProvider);
  return ref.watch(apiProvider).myStatus();
});

final ownProfileProvider = FutureProvider<OwnProfile?>((ref) => ref.watch(apiProvider).ownProfile());

final ownPreferencesProvider = FutureProvider<MatchPreferences?>((ref) => ref.watch(apiProvider).ownPreferences());

final ownPhotosProvider = FutureProvider<List<Photo>>((ref) {
  final api = ref.watch(apiProvider);
  return api.photosOf(api.currentUserId!);
});

final ownPromptAnswersProvider = FutureProvider<List<PromptAnswer>>((ref) {
  final api = ref.watch(apiProvider);
  return api.promptAnswersOf(api.currentUserId!);
});

final promptCatalogProvider = FutureProvider<List<Prompt>>((ref) => ref.watch(apiProvider).prompts());

final incomingLikesProvider = FutureProvider<List<IncomingLike>>((ref) => ref.watch(apiProvider).incomingLikes());

final matchesProvider = FutureProvider<List<MatchSummary>>((ref) => ref.watch(apiProvider).matches());

/// Vollständiges Profil einer anderen Person (null, wenn nicht sichtbar).
final fullProfileProvider = FutureProvider.family<FullProfile?, String>((ref, userId) async {
  final api = ref.watch(apiProvider);
  final summary = await api.profileSummary(userId);
  return summary == null ? null : api.fullProfile(summary);
});

final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>(
  (ref, matchId) => ref.watch(apiProvider).messages(matchId),
);

final storeProvider = Provider<Store>((ref) {
  final store = Store(ref.watch(apiProvider));
  ref.onDispose(store.dispose);
  return store;
});

final storeProductsProvider = FutureProvider((ref) => ref.watch(storeProvider).products());

final matchingConsentProvider = FutureProvider<Consent?>(
  (ref) => ref.watch(apiProvider).activeConsent(MatchingConsent.kind),
);

final myStatsProvider = FutureProvider<MyStats>((ref) => ref.watch(apiProvider).myStats());

final notificationSettingsProvider = FutureProvider<NotificationSettings>(
  (ref) => ref.watch(apiProvider).notificationSettings(),
);
