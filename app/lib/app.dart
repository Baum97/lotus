import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'l10n/gen/app_localizations.dart';
import 'providers.dart';
import 'theme.dart';
import 'widgets/common.dart';

class LotusApp extends StatelessWidget {
  const LotusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lotus',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AppConfig.hasSupabase ? const AuthGate() : const NotConfiguredScreen(),
    );
  }
}

/// Entscheidet anhand von Anmeldung und Profil-Status, was angezeigt wird.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const LoginScreen();

    final status = ref.watch(myStatusProvider);
    return status.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (error, _) => Scaffold(
        body: ErrorView(error: error, onRetry: () => ref.invalidate(myStatusProvider)),
      ),
      data: (status) => status.onboardingComplete ? const HomeShell() : OnboardingScreen(status: status),
    );
  }
}

class NotConfiguredScreen extends StatelessWidget {
  const NotConfiguredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const LotusLogo(size: 64),
            const SizedBox(height: 24),
            Text(l.notConfigured, textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}
