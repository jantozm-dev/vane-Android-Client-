import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../models/history.dart';
import '../models/models.dart';
import '../services/settings_service.dart';
import '../services/vane_client.dart';
import '../storage/history_store.dart';

enum ConnectionPhase { loading, setup, connecting, ready, error }

class VaneAppState extends ChangeNotifier {
  VaneAppState({
    required SettingsService settings,
    required HistoryStore historyStore,
    VaneClient? client,
  }) : _settingsService = settings,
       _history = historyStore,
       _client = client ?? VaneClient(),
       _settings = settings.current;

  final SettingsService _settingsService;
  final HistoryStore _history;
  final VaneClient _client;
  StreamSubscription<SearchEvent>? _subscription;
  final Random _random = Random.secure();
  int _activeTurnIndex = -1;

  AppSettings _settings;

  AppSettings get settings => _settings;
  ThemeMode get themeMode => _settings.themeMode;

  ConnectionPhase connection = ConnectionPhase.loading;
  String? connectionError;
  List<ProviderInfo> providers = [];

  StoredChat? currentChat;

  bool get isStreaming => _subscription != null;
  bool get hasAnswerText => streamedAnswer.isNotEmpty;
  String streamedAnswer = '';
  List<SourceRef> streamedSources = const [];
  String? streamError;
  String? pendingQuestion;

  bool get needsModelSelection =>
      _settings.chatProviderId == null ||
      _settings.chatModelKey == null ||
      _settings.embeddingProviderId == null ||
      _settings.embeddingModelKey == null;

  bool get hasServer => _settings.baseUrl.trim().isNotEmpty;

  Future<void> bootstrap() async {
    if (!hasServer) {
      connection = ConnectionPhase.setup;
      notifyListeners();
      return;
    }
    await connect();
  }

  Future<void> connect({String? serverUrl}) async {
    final url = serverUrl?.trim() ?? _settings.baseUrl.trim();
    if (url.isEmpty) {
      connection = ConnectionPhase.setup;
      notifyListeners();
      return;
    }
    connection = ConnectionPhase.connecting;
    connectionError = null;
    notifyListeners();
    try {
      providers = await _client.fetchProviders(normalizeBaseUrl(url));
      _ensureDefaultModels();
      connection = ConnectionPhase.ready;
      if (serverUrl != null) {
        await updateSettings(_settings..baseUrl = normalizeBaseUrl(url));
      }
    } on Exception catch (error) {
      connection = ConnectionPhase.error;
      connectionError = describeError(error);
    }
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await updateSettings(_settings..onboarded = true);
  }

  Future<void> updateSettings(AppSettings next) async {
    _settings = next;
    await _settingsService.save(next);
    notifyListeners();
  }

  void selectChatModel(String providerId, String key) {
    updateSettings(
      _settings
        ..chatProviderId = providerId
        ..chatModelKey = key,
    );
  }

  void selectEmbeddingModel(String providerId, String key) {
    updateSettings(
      _settings
        ..embeddingProviderId = providerId
        ..embeddingModelKey = key,
    );
  }

  void toggleSource(String source, bool enabled) {
    final next = [..._settings.sources];
    if (enabled) {
      if (!next.contains(source)) next.add(source);
    } else {
      next.remove(source);
    }
    if (next.isEmpty) return;
    updateSettings(_settings..sources = next);
  }

  void setOptimizationMode(String mode) {
    updateSettings(_settings..optimizationMode = mode);
  }

  void setSystemInstructions(String value) {
    updateSettings(_settings..systemInstructions = value.trim());
  }

  void setThemeMode(ThemeMode mode) {
    updateSettings(_settings..themeMode = mode);
  }

  void _ensureDefaultModels() {
    if (providers.isEmpty) return;
    if (_settings.chatProviderId == null ||
        !_providersContain(
          _settings.chatProviderId!,
          _settings.chatModelKey,
          (p) => p.chatModels,
        )) {
      for (final provider in providers) {
        if (provider.chatModels.isNotEmpty) {
          _settings
            ..chatProviderId = provider.id
            ..chatModelKey = provider.chatModels.first.key;
          break;
        }
      }
    }
    if (_settings.embeddingProviderId == null ||
        !_providersContain(
          _settings.embeddingProviderId!,
          _settings.embeddingModelKey,
          (p) => p.embeddingModels,
        )) {
      for (final provider in providers) {
        if (provider.embeddingModels.isNotEmpty) {
          _settings
            ..embeddingProviderId = provider.id
            ..embeddingModelKey = provider.embeddingModels.first.key;
          break;
        }
      }
    }
    _settingsService.save(_settings);
  }

  bool _providersContain(
    String providerId,
    String? modelKey,
    List<ProviderModel> Function(ProviderInfo) selector,
  ) {
    for (final provider in providers) {
      if (provider.id != providerId) continue;
      return selector(provider).any((m) => m.key == modelKey);
    }
    return false;
  }

  Future<void> send(String query) async {
    final text = query.trim();
    if (text.isEmpty || isStreaming || connection != ConnectionPhase.ready) {
      return;
    }
    if (needsModelSelection) {
      streamError =
          'No chat or embedding model is available from this Vane instance. '
          'Configure a provider in the server dashboard.';
      notifyListeners();
      return;
    }

    final chat =
        currentChat ??
        StoredChat(
          id: generateId(_random),
          title: titleFor(text),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          turns: [],
        );
    final turn = StoredTurn(question: text, answer: '', sources: const []);
    chat.turns.add(turn);
    _activeTurnIndex = chat.turns.length - 1;
    currentChat = chat;
    streamedAnswer = '';
    streamedSources = const [];
    streamError = null;
    pendingQuestion = text;
    notifyListeners();

    final history = <List<String>>[
      for (var i = 0; i < chat.turns.length - 1; i++) ...[
        [MessageRole.human, chat.turns[i].question],
        if (chat.turns[i].answer.isNotEmpty)
          [MessageRole.assistant, chat.turns[i].answer],
      ],
    ];

    final request = SearchRequest(
      query: text,
      chatProviderId: _settings.chatProviderId!,
      chatModelKey: _settings.chatModelKey!,
      embeddingProviderId: _settings.embeddingProviderId!,
      embeddingModelKey: _settings.embeddingModelKey!,
      sources: _settings.sources,
      optimizationMode: _settings.optimizationMode,
      systemInstructions: _settings.systemInstructions,
      history: history,
    );

    _subscription = _client
        .search(baseUrl: _settings.baseUrl.trim(), request: request)
        .listen(
          (event) {
            switch (event) {
              case SearchStarted():
                break;
              case SearchSourcesReceived():
                streamedSources = event.sources;
                turn.sources = event.sources;
              case SearchChunk():
                streamedAnswer += event.text;
                turn.answer = streamedAnswer;
              case SearchCompleted():
              case SearchError():
                if (event is SearchError) {
                  streamError = describeError(event);
                }
                streamedAnswer = turn.answer;
                _finishTurn(chat);
            }
            notifyListeners();
          },
          onError: (Object error) {
            streamError = describeError(error);
            streamedAnswer = turn.answer;
            _finishTurn(chat);
            notifyListeners();
          },
        );
  }

  void _finishTurn(StoredChat chat) {
    _subscription?.cancel();
    _subscription = null;
    final index = _activeTurnIndex;
    _activeTurnIndex = -1;
    streamedAnswer = '';
    streamedSources = const [];
    pendingQuestion = null;
    if (index >= 0 && index < chat.turns.length) {
      final turn = chat.turns[index];
      if (turn.answer.isEmpty && turn.sources.isEmpty) {
        chat.turns.removeAt(index);
      }
    }
    chat.updatedAt = DateTime.now();
    if (chat.turns.isEmpty) {
      currentChat = null;
    } else {
      _history.upsert(chat);
    }
  }

  void cancel() {
    if (!isStreaming) return;
    _subscription?.cancel();
    _subscription = null;
    final chat = currentChat;
    if (chat != null && _activeTurnIndex >= 0) {
      final turn = chat.turns[_activeTurnIndex];
      if (turn.answer.isEmpty) {
        chat.turns.remove(turn);
      } else {
        turn.answer += ' …';
      }
      chat.updatedAt = DateTime.now();
      if (chat.turns.isEmpty) {
        currentChat = null;
      } else {
        _history.upsert(chat);
      }
    }
    _activeTurnIndex = -1;
    streamedAnswer = '';
    streamedSources = const [];
    pendingQuestion = null;
    notifyListeners();
  }

  void openChat(StoredChat chat) {
    if (isStreaming) cancel();
    currentChat = chat;
    streamedAnswer = '';
    streamedSources = const [];
    streamError = null;
    pendingQuestion = null;
    notifyListeners();
  }

  void newSearch() {
    if (isStreaming) cancel();
    currentChat = null;
    streamedAnswer = '';
    streamedSources = const [];
    streamError = null;
    pendingQuestion = null;
    notifyListeners();
  }

  Future<void> deleteChat(String id) async {
    await deleteChatAndReturn(id);
  }

  Future<StoredChat?> deleteChatAndReturn(String id) async {
    final removed = await _history.delete(id);
    if (currentChat?.id == id) {
      newSearch();
    } else {
      notifyListeners();
    }
    return removed;
  }

  Future<void> clearHistory() async {
    await _history.clear();
    newSearch();
  }

  Future<List<StoredChat>> loadHistory() => _history.load();

  Future<void> restoreChat(StoredChat chat) async {
    await _history.upsert(chat);
    notifyListeners();
  }

  static String normalizeBaseUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return url;
    if (!url.startsWith(RegExp(r'^https?://', caseSensitive: false))) {
      url = 'http://$url';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static String titleFor(String query) {
    final clean = query.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= 48) return clean;
    return '${clean.substring(0, 45)}…';
  }

  static String describeError(Object error) {
    if (error is VaneApiException) return error.message;
    if (error is SearchError) return error.message;
    if (error is SocketException) {
      return 'Could not reach the Vane server. Check the address in Settings, '
          'that both devices are on the same network, and that this app is '
          'allowed to use unencrypted HTTP for a local instance.';
    }
    if (error is TimeoutException) {
      return 'The connection timed out. Your Vane instance may be busy or unreachable.';
    }
    return 'Something went wrong: $error';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

String generateId(Random random) {
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class VaneStateScope extends InheritedNotifier<VaneAppState> {
  const VaneStateScope({
    super.key,
    required VaneAppState super.notifier,
    required super.child,
  });

  static VaneAppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<VaneStateScope>()!.notifier!;
}
