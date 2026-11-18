import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vane_client/main.dart';
import 'package:vane_client/services/settings_service.dart';
import 'package:vane_client/storage/history_store.dart';
import 'package:vane_client/state/app_state.dart';

void main() {
  testWidgets('app boots to the connect screen when no server is configured', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService();
    await settings.load();
    final history = HistoryStore();
    await history.init();
    final state = VaneAppState(settings: settings, historyStore: history);
    await state.bootstrap();

    await tester.pumpWidget(VaneApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('Connect to your Vane instance'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
