import 'package:flutter/material.dart';

import 'cinemas_screen.dart';
import 'home_screen.dart';
import 'movies_screen.dart';
import 'profile_screen.dart';
import 'tickets_screen.dart';
import '../l10n.dart';

/// Currently selected bottom tab. Any screen can switch tabs through this.
final shellTab = ValueNotifier<int>(0);

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  // Tabs are built lazily on first visit, then kept alive.
  final _visited = <int>{0};

  static const _pages = <Widget>[
    HomeScreen(),
    MoviesScreen(),
    CinemasScreen(),
    TicketsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: shellTab,
      builder: (context, index, _) {
        _visited.add(index);
        // Back button: return to Home first, and only exit from Home.
        return PopScope(
          canPop: index == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) shellTab.value = 0;
          },
          child: Scaffold(
            body: IndexedStack(
              index: index,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  _visited.contains(i) ? _pages[i] : SizedBox.shrink(),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => shellTab.value = i,
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: tr('Home'),
                ),
                NavigationDestination(
                  icon: Icon(Icons.movie_outlined),
                  selectedIcon: Icon(Icons.movie_rounded),
                  label: tr('Movies'),
                ),
                NavigationDestination(
                  icon: Icon(Icons.theaters_outlined),
                  selectedIcon: Icon(Icons.theaters_rounded),
                  label: tr('Cinemas'),
                ),
                NavigationDestination(
                  icon: Icon(Icons.confirmation_number_outlined),
                  selectedIcon: Icon(Icons.confirmation_number_rounded),
                  label: tr('Tickets'),
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: tr('Profile'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
