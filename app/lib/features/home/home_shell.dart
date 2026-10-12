import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../../services/push.dart';
import '../chats/chats_screen.dart';
import '../discover/discover_screen.dart';
import '../likes/likes_screen.dart';
import '../me/me_screen.dart';

enum HomeTab { discover, likes, chats, me }

final homeTabProvider = NotifierProvider<HomeTabNotifier, HomeTab>(HomeTabNotifier.new);

class HomeTabNotifier extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.discover;

  void select(HomeTab tab) => state = tab;
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  void initState() {
    super.initState();
    // Profil ist vollständig → Gerät für Push-Benachrichtigungen anmelden (falls konfiguriert)
    Push.registerToken(ref.read(apiProvider));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tab = ref.watch(homeTabProvider);
    final likes = ref.watch(incomingLikesProvider).value?.length ?? 0;
    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: const [DiscoverScreen(), LikesScreen(), ChatsScreen(), MeScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (index) {
          final selected = HomeTab.values[index];
          ref.read(homeTabProvider.notifier).select(selected);
          // Beim Wechsel frisch laden
          if (selected == HomeTab.likes) ref.invalidate(incomingLikesProvider);
          if (selected == HomeTab.chats) ref.invalidate(matchesProvider);
          ref.invalidate(myStatusProvider);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.spa_outlined),
            selectedIcon: const Icon(Icons.spa),
            label: l.tabDiscover,
          ),
          NavigationDestination(
            icon: Badge.count(count: likes, isLabelVisible: likes > 0, child: const Icon(Icons.favorite_border)),
            selectedIcon: const Icon(Icons.favorite),
            label: l.tabLikes,
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: l.tabChats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l.tabMe,
          ),
        ],
      ),
    );
  }
}
