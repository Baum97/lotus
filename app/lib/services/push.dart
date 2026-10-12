import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';
import '../data/lotus_api.dart';

/// Push-Benachrichtigungen über Firebase Cloud Messaging.
/// Optional: ohne FIREBASE_*-Konfiguration bleibt Push einfach aus.
class Push {
  static bool _enabled = false;

  static Future<void> initialize() async {
    if (!AppConfig.hasFirebase || kIsWeb) return;
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: AppConfig.firebaseApiKey,
          appId: AppConfig.firebaseAppId,
          messagingSenderId: AppConfig.firebaseSenderId,
          projectId: AppConfig.firebaseProjectId,
        ),
      );
      _enabled = true;
    } catch (e) {
      debugPrint('Push deaktiviert: $e');
    }
  }

  /// Reagiert auf Benachrichtigungen: [onForeground] während die App offen ist,
  /// [onOpen] wenn die App über eine Benachrichtigung geöffnet wird (Daten: type = message|match|like).
  static Future<void> listen({
    required void Function(String title, Map<String, dynamic> data) onForeground,
    required void Function(Map<String, dynamic> data) onOpen,
  }) async {
    if (!_enabled) return;
    FirebaseMessaging.onMessage.listen((m) => onForeground(m.notification?.title ?? '', m.data));
    FirebaseMessaging.onMessageOpenedApp.listen((m) => onOpen(m.data));
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) onOpen(initial.data);
  }

  /// Fragt die Berechtigung an und meldet das Gerät beim Server an.
  static Future<void> registerToken(LotusApi api) async {
    if (!_enabled) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
      final token = await messaging.getToken();
      if (token != null) await api.registerDeviceToken(token, platform);
      messaging.onTokenRefresh.listen((token) => api.registerDeviceToken(token, platform));
    } catch (e) {
      // Ohne fertiges Profil schlägt die Registrierung fehl; beim nächsten Start klappt es.
      debugPrint('Push-Registrierung fehlgeschlagen: $e');
    }
  }
}
