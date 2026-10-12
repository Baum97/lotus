# Lotus – App (Flutter)

Android-first, läuft auch auf iOS. Sprache: Deutsch (Texte in `lib/l10n/app_de.arb`).

## Starten

Die App braucht die Supabase-Adresse und den **Publishable Key** (Dashboard → Project Settings → API):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<projekt>.supabase.co \
  --dart-define=SUPABASE_KEY=sb_publishable_...
```

Lokal gegen `supabase start` (siehe Haupt-README): `SUPABASE_URL=http://10.0.2.2:54321` im Android-Emulator
(`127.0.0.1` zeigt dort auf den Emulator selbst).

### Push-Benachrichtigungen (optional)

Ohne diese Werte läuft die App einfach ohne Push. Werte aus der Firebase-Konsole (Android-App anlegen):

```bash
--dart-define=FIREBASE_API_KEY=... --dart-define=FIREBASE_APP_ID=... \
--dart-define=FIREBASE_SENDER_ID=... --dart-define=FIREBASE_PROJECT_ID=...
```

## APK bauen

```bash
flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
# → build/app/outputs/flutter-apk/app-release.apk
```

Für den Play Store: `flutter build appbundle` und vorher einen eigenen Signaturschlüssel einrichten
(<https://docs.flutter.dev/deployment/android>). Die App-ID ist `app.lotusdating.lotus` – vor dem ersten
Upload festlegen, sie lässt sich danach nicht mehr ändern.

## Aufbau

```
lib/
  main.dart, app.dart        Start, Theme, Anmelde-Gate (Login → Onboarding → Home)
  config.dart                --dart-define-Werte, angezeigte Limits
  theme.dart                 "Ruhig & warm": Rosé, Salbei, Creme
  data/models.dart           Datenmodelle (entsprechen den SQL-Funktionen)
  data/lotus_api.dart        Alle Aufrufe an Supabase; Fehler als LotusException(key)
  providers.dart             Riverpod-Provider
  features/
    auth/                    Login per 6-stelligem E-Mail-Code
    onboarding/              5 Schritte: Über dich, Suche, Fotos, Prompts, Standort
    discover/                Profile ansehen, Like auf Foto/Prompt mit Kommentar, Weiter, Rückgängig
    likes/                   "Wer dich mag" + Zurück-Liken (gratis)
    chats/                   Chat-Übersicht (6 Plätze, Warteschlange), Chat, Beenden, Blockieren, Melden
    me/                      Profil bearbeiten, Verifizierung, Konto löschen
    admin/                   Selfies prüfen, Meldungen, Fotos moderieren
  services/push.dart         Firebase Cloud Messaging (optional)
```

Alle Regeln (Like-Budget, Rückgängig, Chat-Limit, Sichtbarkeit) setzt die Datenbank durch –
die App zeigt sie nur an.

## Prüfen

```bash
flutter analyze
flutter test
```
