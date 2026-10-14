import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/data/models.dart';
import 'package:lotus/features/profile/profile_forms.dart';

void main() {
  group('Datenbank-Werte', () {
    test('Intention nutzt die Schlüssel der Datenbank', () {
      expect(Intention.openToRelationship.db, 'open_to_relationship');
      expect(Intention.fromDb('open_to_relationship'), Intention.openToRelationship);
      expect(Intention.tryFromDb(null), isNull);
    });

    test('Geschlecht "divers" wird als diverse gespeichert', () {
      expect(Gender.fromDb('diverse'), Gender.diverse);
      expect(Gender.diverse.name, 'diverse');
    });

    test('Kinderwunsch und Rauchen nutzen die Datenbank-Schlüssel', () {
      expect(ChildrenWish.dontWant.db, 'dont_want');
      expect(ChildrenWish.tryFromDb('have_kids'), ChildrenWish.haveKids);
      expect(Smoking.tryFromDb('regularly'), Smoking.regularly);
      expect(Smoking.tryFromDb(null), isNull);
    });

    test('Verifizierungsstatus wird gelesen', () {
      expect(VerificationStatus.tryFromDb('awaiting_selfie'), VerificationStatus.awaitingSelfie);
      expect(VerificationStatus.tryFromDb(null), isNull);
    });
  });

  group('JSON aus den RPC-Funktionen', () {
    test('MyStatus: Onboarding erst mit Profil, Foto, Prompt und Standort fertig', () {
      final json = {
        'has_profile': true,
        'has_preferences': true,
        'has_location': false,
        'photo_count': 2,
        'prompt_count': 1,
        'display_name': 'Nina',
        'verified': false,
        'verification_status': null,
        'trust_status': 'active',
        'is_admin': false,
        'likes_remaining': 20,
        'undos_remaining': 3,
        'active_chats': 0,
      };
      expect(MyStatus.fromJson(json).onboardingComplete, isFalse);
      expect(MyStatus.fromJson({...json, 'has_location': true}).onboardingComplete, isTrue);
      expect(MyStatus.fromJson(json).trustStatus, TrustStatus.active);
      expect(MyStatus.fromJson(json).hasPlus, isFalse);
      final plus = MyStatus.fromJson({...json, 'plus_until': '2026-11-12T10:00:00Z', 'travel_city': 'München'});
      expect(plus.hasPlus, isTrue);
      expect(plus.travelCity, 'München');
    });

    test('Vorschlag ohne öffentliches Dating-Ziel', () {
      final summary = ProfileSummary.fromJson({
        'id': 'a',
        'display_name': 'Ben',
        'age': 32,
        'city': 'Ulm',
        'intention': null,
        'bio': null,
        'distance_km': 3,
        'verified': true,
      });
      expect(summary.intention, isNull);
      expect(summary.distanceKm, 3);
      expect(summary.verified, isTrue);
    });

    test('Nachricht mit Sicherheitshinweis', () {
      final message = ChatMessage.fromJson({
        'id': 'm',
        'sender_id': 's',
        'body': 'Kannst du mir Geld leihen?',
        'created_at': '2026-10-12T10:00:00Z',
        'safety_flag': 'money',
      });
      expect(message.safetyFlag, SafetyFlag.money);
    });

    test('Match in der Warteschlange', () {
      final match = MatchSummary.fromJson({
        'match_id': 'x',
        'state': 'queued',
        'close_reason': null,
        'other_user': 'u',
        'display_name': 'Mia',
        'verified': false,
        'created_at': '2026-10-12T10:00:00Z',
        'last_activity_at': '2026-10-12T10:00:00Z',
        'last_message': null,
        'last_message_mine': null,
      });
      expect(match.state, MatchState.queued);
      expect(match.lastMessageMine, isFalse);
    });
  });

  group('Altersprüfung', () {
    test('genau 18 ist erlaubt, einen Tag jünger nicht', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      expect(ProfileDraft.isAdult(DateTime(today.year - 18, today.month, today.day)), isTrue);
      expect(ProfileDraft.isAdult(DateTime(today.year - 18, today.month, today.day + 1)), isFalse);
    });
  });

  group('Beta', () {
    test('Kennzahlen und "wer sucht wen" werden gelesen', () {
      final m = BetaMetrics({
        'period_days': 30,
        'users': {'profiles': 40, 'active_7d': 12},
        'funnel': {'likes': 100, 'matches': 9},
        'undos': 3,
        'invites': {'required': true, 'redeemed': 5},
        'balance': [
          {'region': 'Ulm', 'gender': 'woman', 'seeking': 'man+woman', 'count': 4},
        ],
      });
      expect(m.profiles, 40);
      expect(m.active7d, 12);
      expect(m.verified, 0, reason: 'fehlende Werte zählen als 0');
      expect(m.undos, 3);
      expect(m.invitesRequired, isTrue);
      expect(m.balance.single.seeking, [Gender.man, Gender.woman]);
    });

    test('Einladungscode wird lesbar formatiert', () {
      final invite = Invite.fromJson({
        'code': 'K7M2PQ4X',
        'uses': 1,
        'max_uses': 1,
        'expires_at': '2020-01-01T00:00:00Z',
        'created_at': '2019-12-01T00:00:00Z',
      });
      expect(invite.formatted, 'K7M2-PQ4X');
      expect(invite.usedUp, isTrue);
      expect(invite.isExpired(DateTime.now()), isTrue);
    });
  });
}
