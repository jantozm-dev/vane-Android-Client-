import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_ui/material_ui.dart';

import 'screens/root_shell.dart';
import 'services/settings_service.dart';
import 'storage/history_store.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsService();
  await settings.load();
  final history = HistoryStore();
  await history.init();
  final state = VaneAppState(settings: settings, historyStore: history);
  runApp(VaneApp(state: state));
  state.bootstrap();
}

class VaneApp extends StatelessWidget {
  const VaneApp({super.key, required this.state});

  final VaneAppState state;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return ListenableBuilder(
          listenable: state,
          builder: (context, _) {
            return MaterialApp(
              title: 'Vane',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(lightDynamic),
              darkTheme: AppTheme.dark(darkDynamic),
              themeMode: state.themeMode,
              home: VaneStateScope(notifier: state, child: const RootShell()),
            );
          },
        );
      },
    );
  }
}
