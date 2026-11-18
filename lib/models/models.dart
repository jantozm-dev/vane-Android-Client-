class ProviderModel {
  const ProviderModel({required this.name, required this.key});

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      name: (json['name'] ?? json['key'] ?? '').toString(),
      key: (json['key'] ?? '').toString(),
    );
  }

  final String name;
  final String key;

  @override
  bool operator ==(Object other) =>
      other is ProviderModel && other.name == name && other.key == key;

  @override
  int get hashCode => Object.hash(name, key);
}

class ProviderInfo {
  const ProviderInfo({
    required this.id,
    required this.name,
    required this.chatModels,
    required this.embeddingModels,
  });

  factory ProviderInfo.fromJson(Map<String, dynamic> json) {
    final chatModels = (json['chatModels'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ProviderModel.fromJson)
        .toList();
    final embeddingModels = (json['embeddingModels'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ProviderModel.fromJson)
        .toList();
    return ProviderInfo(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Provider').toString(),
      chatModels: chatModels,
      embeddingModels: embeddingModels,
    );
  }

  final String id;
  final String name;
  final List<ProviderModel> chatModels;
  final List<ProviderModel> embeddingModels;
}

class SourceRef {
  const SourceRef({required this.title, required this.url, this.content = ''});

  factory SourceRef.fromJson(dynamic raw) {
    if (raw is! Map) {
      return SourceRef(title: 'Source', url: '');
    }
    final metadata = raw['metadata'];
    final meta = metadata is Map ? metadata : const {};
    return SourceRef(
      title: (meta['title'] ?? meta['url'] ?? 'Source').toString(),
      url: (meta['url'] ?? '').toString(),
      content: (raw['content'] ?? '').toString(),
    );
  }

  final String title;
  final String url;
  final String content;

  String get host {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;
    return uri.host.replaceFirst(RegExp(r'^www\.'), '');
  }
}

class SearchRequest {
  const SearchRequest({
    required this.query,
    required this.chatProviderId,
    required this.chatModelKey,
    required this.embeddingProviderId,
    required this.embeddingModelKey,
    required this.sources,
    required this.optimizationMode,
    required this.systemInstructions,
    this.history = const [],
  });

  final String query;
  final String chatProviderId;
  final String chatModelKey;
  final String embeddingProviderId;
  final String embeddingModelKey;
  final List<String> sources;
  final String optimizationMode;
  final String systemInstructions;
  final List<List<String>> history;

  Map<String, dynamic> toJson() => {
    'query': query,
    'chatModel': {'providerId': chatProviderId, 'key': chatModelKey},
    'embeddingModel': {
      'providerId': embeddingProviderId,
      'key': embeddingModelKey,
    },
    'sources': sources,
    'optimizationMode': optimizationMode,
    'systemInstructions': systemInstructions,
    'history': history,
    'stream': true,
  };
}

sealed class SearchEvent {
  const SearchEvent();
}

class SearchStarted extends SearchEvent {
  const SearchStarted();
}

class SearchSourcesReceived extends SearchEvent {
  const SearchSourcesReceived(this.sources);

  final List<SourceRef> sources;
}

class SearchChunk extends SearchEvent {
  const SearchChunk(this.text);

  final String text;
}

class SearchCompleted extends SearchEvent {
  const SearchCompleted();
}

class SearchError extends SearchEvent {
  const SearchError(this.message);

  final String message;
}
