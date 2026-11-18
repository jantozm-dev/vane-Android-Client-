import 'package:material_ui/material_ui.dart';

import '../../state/app_state.dart';

import '../connect_screen.dart';
import 'thread_view.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = VaneStateScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Vane')),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          if (state.connection == ConnectionPhase.ready) {
            return ThreadScreen(state: state, input: _input);
          }
          return ConnectScreen(state: state);
        },
      ),
    );
  }
}
