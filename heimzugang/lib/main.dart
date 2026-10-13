import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/einrichtung.dart';
import 'screens/uebersicht.dart';
import 'state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState(await SharedPreferences.getInstance());
  runApp(HeimzugangApp(state: state));
}

class HeimzugangApp extends StatelessWidget {
  const HeimzugangApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F6F5C), brightness: b),
      useMaterial3: true,
    );
    return StateScope(
      state: state,
      child: MaterialApp(
        title: 'Heimzugang',
        debugShowCheckedModeBanner: false,
        theme: theme(Brightness.light),
        darkTheme: theme(Brightness.dark),
        home: ListenableBuilder(
          listenable: state,
          builder: (context, _) => state.profil == null ? const WillkommenScreen() : const UebersichtScreen(),
        ),
      ),
    );
  }
}

/// Stellt den [AppState] im Widget-Baum bereit und baut Abhängige bei Änderungen neu.
class StateScope extends InheritedNotifier<AppState> {
  const StateScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<StateScope>()!.notifier!;
}
