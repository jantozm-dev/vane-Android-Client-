import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/history.dart';

class HistoryStore {
  HistoryStore({SharedPreferences? prefs}) : _prefsOverride = prefs;

  static const _storageKey = 'vane.history.v1';

  final SharedPreferences? _prefsOverride;
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = _prefsOverride ?? await SharedPreferences.getInstance();
  }

  Future<List<StoredChat>> load() async {
    final prefs = _requirePrefs();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return [];
    try {
      final json = jsonDecode(raw);
      if (json is! List) return [];
      final chats = json
          .whereType<Map<String, dynamic>>()
          .map(StoredChat.fromJson)
          .toList();
      chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return chats;
    } on FormatException {
      return [];
    }
  }

  Future<void> upsert(StoredChat chat) async {
    final prefs = _requirePrefs();
    final chats = await load();
    chats.removeWhere((c) => c.id == chat.id);
    chats.add(chat);
    chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _write(prefs, chats);
  }

  Future<StoredChat?> delete(String id) async {
    final prefs = _requirePrefs();
    final chats = await load();
    StoredChat? removed;
    for (final chat in chats) {
      if (chat.id == id) removed = chat;
    }
    chats.removeWhere((c) => c.id == id);
    await _write(prefs, chats);
    return removed;
  }

  Future<void> clear() async {
    final prefs = _requirePrefs();
    await prefs.remove(_storageKey);
  }

  SharedPreferences _requirePrefs() {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('HistoryStore.init() must be called before use.');
    }
    return prefs;
  }

  Future<void> _write(SharedPreferences prefs, List<StoredChat> chats) {
    return prefs.setString(
      _storageKey,
      jsonEncode([for (final c in chats) c.toJson()]),
    );
  }
}
