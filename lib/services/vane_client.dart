import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

class VaneApiException implements Exception {
  const VaneApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class VaneClient {
  VaneClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String baseUrl, String path) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$base$path');
  }

  Future<List<ProviderInfo>> fetchProviders(String baseUrl) async {
    final http.Response response;
    try {
      response = await _client
          .get(_uri(baseUrl, '/api/providers'))
          .timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw const VaneApiException(
        'The server took too long to respond. Check that your Vane instance is reachable from this device.',
      );
    }
    if (response.statusCode != 200) {
      throw VaneApiException(
        'Server responded with HTTP ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }
    final dynamic body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      throw const VaneApiException(
        'The server returned an unexpected response.',
      );
    }
    final list = body is Map<String, dynamic>
        ? body['providers'] as List?
        : null;
    if (list == null) {
      throw const VaneApiException(
        'The server returned an unexpected response.',
      );
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(ProviderInfo.fromJson)
        .toList();
  }

  Stream<SearchEvent> search({
    required String baseUrl,
    required SearchRequest request,
  }) async* {
    final httpRequest = http.Request('POST', _uri(baseUrl, '/api/search'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(request.toJson());

    final http.StreamedResponse response;
    try {
      response = await _client
          .send(httpRequest)
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      yield const SearchError('Connecting to your Vane instance timed out.');
      return;
    } on http.ClientException {
      yield const SearchError(
        'Could not reach the Vane server. Check the address in Settings and your network connection.',
      );
      return;
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      String detail = '';
      try {
        final json = jsonDecode(body);
        if (json is Map<String, dynamic> && json['message'] != null) {
          detail = ' (${json['message']})';
        }
      } on FormatException {
        // keep detail empty
      }
      yield SearchError(
        'Search failed with HTTP ${response.statusCode}$detail.',
      );
      return;
    }

    var buffer = '';
    var completed = false;

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer += chunk;
      var index = buffer.indexOf('\n');
      while (index >= 0) {
        final line = buffer.substring(0, index).trim();
        buffer = buffer.substring(index + 1);
        index = buffer.indexOf('\n');
        final event = _parseLine(line);
        if (event is SearchCompleted) {
          completed = true;
        }
        if (event != null) yield event;
      }
    }
    if (!completed) {
      yield const SearchCompleted();
    }
  }

  SearchEvent? _parseLine(String line) {
    if (line.isEmpty) return null;
    dynamic json;
    try {
      json = jsonDecode(line);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, dynamic>) return null;
    switch (json['type']) {
      case 'init':
        return const SearchStarted();
      case 'sources':
        final list = json['data'] as List? ?? const [];
        return SearchSourcesReceived(list.map(SourceRef.fromJson).toList());
      case 'response':
        return SearchChunk((json['data'] ?? '').toString());
      case 'done':
        return const SearchCompleted();
      case 'error':
        final data = json['data'];
        return SearchError(
          data == null ? 'The server reported an error.' : data.toString(),
        );
      default:
        return null;
    }
  }
}
