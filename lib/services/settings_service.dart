import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  AppSettings({
    required this.baseUrl,
    required this.chatProviderId,
    required this.chatModelKey,
    required this.embeddingProviderId,
    required this.embeddingModelKey,
    required this.sources,
    required this.optimizationMode,
    required this.systemInstructions,
    required this.themeMode,
    required this.onboarded,
  });

  factory AppSettings.defaults() => AppSettings(
    baseUrl: '',
    chatProviderId: null,
    chatModelKey: null,
    embeddingProviderId: null,
    embeddingModelKey: null,
    sources: ['web'],
    optimizationMode: 'balanced',
    systemInstructions: '',
    themeMode: ThemeMode.system,
    onboarded: false,
  );

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    baseUrl: (json['baseUrl'] ?? '').toString(),
    chatProviderId: json['chatProviderId']?.toString(),
    chatModelKey: json['chatModelKey']?.toString(),
    embeddingProviderId: json['embeddingProviderId']?.toString(),
    embeddingModelKey: json['embeddingModelKey']?.toString(),
    sources: (json['sources'] as List? ?? const ['web'])
        .map((e) => e.toString())
        .toList(),
    optimizationMode: (json['optimizationMode'] ?? 'balanced').toString(),
    systemInstructions: (json['systemInstructions'] ?? '').toString(),
    themeMode: ThemeMode.values.firstWhere(
      (m) => m.name == json['themeMode'],
      orElse: () => ThemeMode.system,
    ),
    onboarded: json['onboarded'] == true,
  );

  static const allSources = ['web', 'academic', 'discussions'];

  String baseUrl;
  String? chatProviderId;
  String? chatModelKey;
  String? embeddingProviderId;
  String? embeddingModelKey;
  List<String> sources;
  String optimizationMode;
  String systemInstructions;
  ThemeMode themeMode;
  bool onboarded;

  Map<String, dynamic> toJson() => {
    'baseUrl': baseUrl,
    'chatProviderId': chatProviderId,
    'chatModelKey': chatModelKey,
    'embeddingProviderId': embeddingProviderId,
    'embeddingModelKey': embeddingModelKey,
    'sources': sources,
    'optimizationMode': optimizationMode,
    'systemInstructions': systemInstructions,
    'themeMode': themeMode.name,
    'onboarded': onboarded,
  };
}

class SettingsService {
  static const _storageKey = 'vane.settings.v1';

  AppSettings get current => _current;

  late SharedPreferences _prefs;
  AppSettings _current = AppSettings.defaults();

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        _current = AppSettings.fromJson(json);
      }
    } on FormatException {
      _current = AppSettings.defaults();
    }
  }

  Future<void> save(AppSettings settings) async {
    _current = settings;
    await _prefs.setString(_storageKey, jsonEncode(settings.toJson()));
  }
}
