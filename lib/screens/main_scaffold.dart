// lib/screens/main_scaffold.dart
//
// The app shell: a bottom navigation bar with three tabs — Matches, Americano,
// Stats. ONE Scaffold/AppBar/FAB for the whole app; each tab provides only its
// body content. The floating action button changes depending on the tab.

import 'package:flutter/material.dart';

import 'home_screen.dart' show MatchesBody;
import 'americano_list_screen.dart' show AmericanoBody;
import 'stats_screen.dart' show StatsBody;
import 'scoreboard_screen.dart';
import 'americano_setup_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;

  static const _titles = ['Matches', 'Americano', 'Stats'];

  // The FAB depends on which tab is open.
  Widget? _fab(BuildContext context) {
    switch (_index) {
      case 0:
        return FloatingActionButton.extended(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ScoreboardScreen())),
          icon: const Icon(Icons.add),
          label: const Text('Log a match'),
        );
      case 1:
        return FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AmericanoSetupScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('New session'),
        );
      default:
        return null; // Stats tab: no FAB
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_index],
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      // IndexedStack keeps all three tabs alive and just shows the selected one,
      // so scroll position / state is preserved when you switch tabs.
      body: IndexedStack(
        index: _index,
        children: const [MatchesBody(), AmericanoBody(), StatsBody()],
      ),
      floatingActionButton: _fab(context),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_tennis_outlined),
            selectedIcon: Icon(Icons.sports_tennis),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Americano',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}
