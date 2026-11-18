import 'package:material_ui/material_ui.dart';

import '../state/app_state.dart';
import 'history_screen.dart';
import 'search/search_screen.dart';
import 'settings_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tab = 0;

  void _openSearch() => setState(() => _tab = 0);

  @override
  Widget build(BuildContext context) {
    final state = VaneStateScope.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(
            index: _tab,
            children: [
              SearchScreen(),
              HistoryScreen(onOpenSearch: _openSearch),
              SettingsScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (index) => setState(() => _tab = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.blur_on_outlined),
                selectedIcon: Icon(Icons.blur_on),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
