import 'package:material_ui/material_ui.dart';

import '../../models/history.dart';
import '../../state/app_state.dart';
import '../../widgets/answer_markdown.dart';
import '../../widgets/composer.dart';
import '../../widgets/sources.dart';

class ThreadScreen extends StatefulWidget {
  const ThreadScreen({super.key, required this.state, required this.input});

  final VaneAppState state;
  final TextEditingController input;

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _submit() {
    final state = widget.state;
    final text = widget.input.text.trim();
    if (text.isEmpty || state.isStreaming) return;
    widget.input.clear();
    state.send(text);
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final chat = state.currentChat;
    return Column(
      children: [
        Expanded(
          child: chat == null
              ? _Welcome(
                  onSuggestion: (value) {
                    widget.input.text = value;
                    _submit();
                  },
                )
              : _ThreadList(
                  state: state,
                  chat: chat,
                  scrollController: _scroll,
                ),
        ),
        if (chat != null) const SizedBox(height: 4),
        Composer(state: state, controller: widget.input, onSubmit: _submit),
      ],
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onSuggestion});

  final ValueChanged<String> onSuggestion;

  static const _suggestions = [
    'Explain how a four-stroke engine works',
    'Compare SwiftUI and Flutter for a new app',
    'Best free self-hosted apps in 2026',
    'Summarize the plot of Dune in three sentences',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wind_power,
                size: 40,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ask anything, privately',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Answers come from your own self-hosted Vane instance, '
              'backed by real sources.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final suggestion in _suggestions)
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: () => onSuggestion(suggestion),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadList extends StatelessWidget {
  const _ThreadList({
    required this.state,
    required this.chat,
    required this.scrollController,
  });

  final VaneAppState state;
  final StoredChat chat;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final activeIndex = state.isStreaming ? chat.turns.length - 1 : -1;
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: chat.turns.length,
      itemBuilder: (context, index) {
        return _TurnView(
          turn: chat.turns[index],
          isActive: index == activeIndex,
          state: state,
        );
      },
    );
  }
}

class _TurnView extends StatelessWidget {
  const _TurnView({
    required this.turn,
    required this.isActive,
    required this.state,
  });

  final StoredTurn turn;
  final bool isActive;
  final VaneAppState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final liveAnswer = isActive ? state.streamedAnswer : turn.answer;
    final sources = isActive ? state.streamedSources : turn.sources;
    final waiting = isActive && liveAnswer.isEmpty && sources.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.82,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Text(
                turn.question,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: scheme.onPrimary),
              ),
            ),
          ),
          if (sources.isNotEmpty) ...[
            const SizedBox(height: 14),
            SourceChips(sources: sources),
          ],
          if (liveAnswer.isNotEmpty) ...[
            const SizedBox(height: 14),
            AnswerMarkdown(data: liveAnswer),
          ],
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            child: isActive
                ? _LiveStatus(
                    waiting: waiting,
                    error: state.streamError,
                    onRetry: () => state.send(turn.question),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _LiveStatus extends StatelessWidget {
  const _LiveStatus({
    required this.waiting,
    required this.error,
    required this.onRetry,
  });

  final bool waiting;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (waiting) {
      return const Padding(
        padding: EdgeInsets.only(top: 14),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            SizedBox(width: 12),
            Text('Searching the web…'),
          ],
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.only(top: 14),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          SizedBox(width: 12),
          Text('Writing…'),
        ],
      ),
    );
  }
}
