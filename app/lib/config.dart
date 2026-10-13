/// Konfiguration über --dart-define (siehe app/README.md).
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Publishable (früher "anon") Key aus dem Supabase-Dashboard – darf in der App stehen.
  static const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

  // Optional: Push-Benachrichtigungen (Firebase Cloud Messaging)
  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseSenderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
  static bool get hasFirebase =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseSenderId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;

  // Spiegeln die Regeln aus supabase/migrations – nur für die Anzeige, durchgesetzt wird serverseitig.
  static const dailyLikes = 20;
  static const monthlyUndos = 3;
  static const maxActiveChats = 6;
  static const maxPhotos = 6;
  static const maxPrompts = 3;
}
