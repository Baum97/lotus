import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../../widgets/common.dart';

/// Anmeldung per 6-stelligem E-Mail-Code – kein Passwort, keine SMS-Kosten.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final l = AppLocalizations.of(context);
    if (!_emailPattern.hasMatch(_email.text.trim())) {
      showMessage(context, l.invalidEmail);
      return;
    }
    await ref.read(apiProvider).sendLoginCode(_email.text);
    setState(() => _codeSent = true);
  }

  Future<void> _verify() async {
    await ref.read(apiProvider).verifyLoginCode(_email.text, _code.text);
    // AuthGate reagiert auf die neue Sitzung.
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Center(child: LotusLogo(size: 80)),
                const SizedBox(height: 32),
                Text(l.loginTitle, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(l.loginSubtitle,
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
                const SizedBox(height: 40),
                if (!_codeSent) ...[
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    decoration: InputDecoration(labelText: l.emailLabel),
                    onSubmitted: (_) => _sendCode(),
                  ),
                  const SizedBox(height: 16),
                  AsyncButton(label: l.sendCode, onPressed: _sendCode),
                ] else ...[
                  Text(l.codeSentTo(_email.text.trim()), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 8),
                    decoration: InputDecoration(labelText: l.codeLabel),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  AsyncButton(label: l.verifyCode, onPressed: _code.text.length == 6 ? _verify : null),
                  TextButton(
                    onPressed: () => setState(() {
                      _codeSent = false;
                      _code.clear();
                    }),
                    child: Text(l.changeEmail),
                  ),
                ],
                const SizedBox(height: 24),
                Text(l.loginLegal,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
