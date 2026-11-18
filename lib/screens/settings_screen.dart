import 'package:material_ui/material_ui.dart';

import '../models/models.dart';
import '../services/settings_service.dart';
import '../state/app_state.dart';
import '../widgets/sources.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = VaneStateScope.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _connectionCard(context, state),
              const SizedBox(height: 12),
              _modelsCard(context, state),
              const SizedBox(height: 12),
              _searchOptionsCard(context, state),
              const SizedBox(height: 12),
              _appearanceCard(context, state),
              const SizedBox(height: 12),
              _aboutCard(context),
            ],
          ),
        );
      },
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _connectionCard(BuildContext context, VaneAppState state) {
    final connected = state.connection == ConnectionPhase.ready;
    return _section(
      context,
      title: 'Connection',
      children: [
        Row(
          children: [
            Icon(
              connected ? Icons.check_circle_outline : Icons.link_off,
              size: 18,
              color: connected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                connected
                    ? '${state.settings.baseUrl} · ${state.providers.length} provider(s)'
                    : 'Not connected',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => _editServer(context, state),
              icon: const Icon(Icons.dns_outlined),
              label: const Text('Server address'),
            ),
            TextButton.icon(
              onPressed: state.connection == ConnectionPhase.connecting
                  ? null
                  : () => state.connect(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reconnect'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _editServer(BuildContext context, VaneAppState state) async {
    final controller = TextEditingController(text: state.settings.baseUrl);
    final url = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Server address'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'http://192.168.1.50:3000',
            prefixIcon: Icon(Icons.dns_outlined),
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (url == null || url.trim().isEmpty) return;
    await state.connect(serverUrl: url);
  }

  Widget _modelsCard(BuildContext context, VaneAppState state) {
    if (state.connection != ConnectionPhase.ready) {
      return _section(
        context,
        title: 'Models',
        children: [
          Text(
            'Connect to a Vane instance to pick chat and embedding models.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    final chatModels = <(ProviderInfo, ProviderModel)>[
      for (final provider in state.providers)
        for (final model in provider.chatModels) (provider, model),
    ];
    final embeddingModels = <(ProviderInfo, ProviderModel)>[
      for (final provider in state.providers)
        for (final model in provider.embeddingModels) (provider, model),
    ];

    final chatSelection =
        '${state.settings.chatProviderId}::${state.settings.chatModelKey}';
    final embeddingSelection =
        '${state.settings.embeddingProviderId}::${state.settings.embeddingModelKey}';

    return _section(
      context,
      title: 'Models',
      children: [
        Text('Chat model', style: Theme.of(context).textTheme.labelLarge),
        if (chatModels.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No chat models available. Configure a provider on the server.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          RadioGroup<String>(
            groupValue: chatSelection,
            onChanged: (selection) {
              final entry = _entryByComposite(chatModels, selection);
              if (entry != null) {
                state.selectChatModel(entry.$1.id, entry.$2.key);
              }
            },
            child: Column(
              children: [
                for (final entry in chatModels)
                  RadioListTile<String>(
                    value: '${entry.$1.id}::${entry.$2.key}',
                    title: Text(entry.$2.name),
                    subtitle: Text(entry.$1.name),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text('Embedding model', style: Theme.of(context).textTheme.labelLarge),
        if (embeddingModels.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No embedding models available. Configure one on the server.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          RadioGroup<String>(
            groupValue: embeddingSelection,
            onChanged: (selection) {
              final entry = _entryByComposite(embeddingModels, selection);
              if (entry != null) {
                state.selectEmbeddingModel(entry.$1.id, entry.$2.key);
              }
            },
            child: Column(
              children: [
                for (final entry in embeddingModels)
                  RadioListTile<String>(
                    value: '${entry.$1.id}::${entry.$2.key}',
                    title: Text(entry.$2.name),
                    subtitle: Text(entry.$1.name),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _searchOptionsCard(BuildContext context, VaneAppState state) {
    final settings = state.settings;
    return _section(
      context,
      title: 'Search options',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final source in AppSettings.allSources)
              FilterChip(
                label: Text(_sourceLabel(source)),
                selected: settings.sources.contains(source),
                onSelected: (value) => state.toggleSource(source, value),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Optimization mode',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'speed', label: Text('Speed')),
            ButtonSegment(value: 'balanced', label: Text('Balanced')),
            ButtonSegment(value: 'quality', label: Text('Quality')),
          ],
          selected: {settings.optimizationMode},
          onSelectionChanged: (selection) =>
              state.setOptimizationMode(selection.first),
        ),
        const SizedBox(height: 14),
        Text(
          'System instructions',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        SystemInstructionsField(
          key: ValueKey(settings.systemInstructions),
          initial: settings.systemInstructions,
          onSave: state.setSystemInstructions,
        ),
      ],
    );
  }

  (ProviderInfo, ProviderModel)? _entryByComposite(
    List<(ProviderInfo, ProviderModel)> entries,
    String? selection,
  ) {
    if (selection == null) return null;
    for (final entry in entries) {
      if ('${entry.$1.id}::${entry.$2.key}' == selection) return entry;
    }
    return null;
  }

  String _sourceLabel(String source) {
    switch (source) {
      case 'web':
        return 'Web';
      case 'academic':
        return 'Academic';
      case 'discussions':
        return 'Discussions';
      default:
        return source;
    }
  }

  Widget _appearanceCard(BuildContext context, VaneAppState state) {
    return _section(
      context,
      title: 'Appearance',
      children: [
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.system, label: Text('System')),
            ButtonSegment(value: ThemeMode.light, label: Text('Light')),
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
          ],
          selected: {state.themeMode},
          onSelectionChanged: (selection) =>
              state.setThemeMode(selection.first),
        ),
      ],
    );
  }

  Widget _aboutCard(BuildContext context) {
    return _section(
      context,
      title: 'About',
      children: [
        Text(
          'Vane for Android · 1.0.0',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'A Material You client for the open-source Vane (formerly '
          'Perplexica) answer engine. All data stays between this app and '
          'your own instance.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () =>
              launchExternal(context, 'https://github.com/ItzCrazyKns/Vane'),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Vane on GitHub'),
        ),
      ],
    );
  }
}

class SystemInstructionsField extends StatefulWidget {
  const SystemInstructionsField({
    super.key,
    required this.initial,
    required this.onSave,
  });

  final String initial;
  final ValueChanged<String> onSave;

  @override
  State<SystemInstructionsField> createState() =>
      _SystemInstructionsFieldState();
}

class _SystemInstructionsFieldState extends State<SystemInstructionsField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: _controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'e.g. Keep answers short and technical.',
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => widget.onSave(_controller.text),
          child: const Text('Save instructions'),
        ),
      ],
    );
  }
}
