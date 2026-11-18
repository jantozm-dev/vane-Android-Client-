import 'models.dart';

class StoredChat {
  StoredChat({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.turns,
  });

  factory StoredChat.fromJson(Map<String, dynamic> json) => StoredChat(
    id: (json['id'] ?? '').toString(),
    title: (json['title'] ?? 'Search').toString(),
    createdAt:
        DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
        DateTime.now(),
    updatedAt:
        DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
        DateTime.now(),
    turns: (json['turns'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((t) => StoredTurn.fromJson(t))
        .toList(),
  );

  final String id;
  final String title;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<StoredTurn> turns;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'turns': [for (final t in turns) t.toJson()],
  };
}

class StoredTurn {
  StoredTurn({
    required this.question,
    required this.answer,
    required this.sources,
  });

  factory StoredTurn.fromJson(Map<String, dynamic> json) => StoredTurn(
    question: (json['question'] ?? '').toString(),
    answer: (json['answer'] ?? '').toString(),
    sources: (json['sources'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SourceRef.fromJson)
        .toList(),
  );

  final String question;
  String answer;
  List<SourceRef> sources;

  Map<String, dynamic> toJson() => {
    'question': question,
    'answer': answer,
    'sources': [
      for (final s in sources)
        {'title': s.title, 'url': s.url, 'content': s.content},
    ],
  };
}

class MessageRole {
  static const human = 'human';
  static const assistant = 'assistant';
}
