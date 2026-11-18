import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../models/history.dart';
import '../state/app_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.onOpenSearch});

  final VoidCallback onOpenSearch;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late VaneAppState _state;
  late Future<List<StoredChat>> _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _state = VaneStateScope.of(context);
      _future = _state.loadHistory();
      _initialized = true;
    }
  }

  void _refresh() {
    setState(() {
      _future = _state.loadHistory();
    });
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
          'All locally saved searches will be removed from this device. '
          'Chats remain on your Vane server until deleted there.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _state.clearHistory();
    _refresh();
  }

  Future<void> _deleteChat(StoredChat chat) async {
    final removed = await _state.deleteChatAndReturn(chat.id);
    _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Deleted “${chat.title}”'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              if (removed != null) await _state.restoreChat(removed);
              _refresh();
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Clear all',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _confirmDeleteAll,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<List<StoredChat>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data ?? const <StoredChat>[];
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 56,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  const Text('Nothing here yet'),
                  const SizedBox(height: 4),
                  const Text('Your searches will be saved on this device.'),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: chats.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final chat = chats[index];
              return Card(
                child: ListTile(
                  title: Text(
                    chat.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${chat.turns.length} question${chat.turns.length == 1 ? '' : 's'}'
                    ' · ${DateFormat.yMMMd().add_jm().format(chat.updatedAt)}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteChat(chat),
                  ),
                  onTap: () {
                    _state.openChat(chat);
                    widget.onOpenSearch();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
