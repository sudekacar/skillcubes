import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Exception thrown for non-2xx API responses.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// HTTP client for SkillCubes FastAPI (`/api/v1`).
///
/// Injects `Authorization: Bearer <token>` when a JWT is stored.
class ApiService {
  ApiService(this._prefs, {http.Client? client})
      : _client = client ?? http.Client();

  /// FastAPI origin (no `/api/v1` suffix).
  ///
  /// Android emulator reaches the host via `10.0.2.2`.
  /// iOS simulator / desktop / web use loopback.
  static String get hostOrigin {
    const port = 8000;
    if (kIsWeb) return 'http://127.0.0.1:$port';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:$port';
      default:
        return 'http://127.0.0.1:$port';
    }
  }

  static String get baseUrl => '$hostOrigin/api/v1';

  static const _tokenKey = 'access_token';

  final SharedPreferences _prefs;
  final http.Client _client;

  String? get accessToken => _prefs.getString(_tokenKey);

  bool get isAuthenticated =>
      accessToken != null && accessToken!.trim().isNotEmpty;

  Future<void> setAccessToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _prefs.remove(_tokenKey);
    } else {
      await _prefs.setString(_tokenKey, token);
    }
  }

  Future<void> clearToken() => setAccessToken(null);

  Map<String, String> _headers({bool auth = true, bool jsonBody = true}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
    };
    if (auth && isAuthenticated) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final response = await _client.get(
      _uri(path, query),
      headers: _headers(auth: auth),
    );
    return _decodeMap(response);
  }

  Future<List<dynamic>> getJsonList(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final response = await _client.get(
      _uri(path, query),
      headers: _headers(auth: auth),
    );
    return _decodeList(response);
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    final raw = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(raw);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        _errorMessage(decoded, response.statusCode),
      );
    }
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw ApiException(response.statusCode, 'Unexpected response shape');
  }

  List<dynamic> _decodeList(http.Response response) {
    final raw = response.body.isEmpty ? '[]' : response.body;
    final decoded = jsonDecode(raw);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        _errorMessage(decoded, response.statusCode),
      );
    }
    if (decoded is List) return decoded;
    throw ApiException(response.statusCode, 'Expected a JSON array');
  }

  String _errorMessage(Object? decoded, int status) {
    if (decoded is Map) {
      final detail = decoded['detail'];
      if (detail is String) return detail;
      if (detail != null) return detail.toString();
    }
    return 'Request failed ($status)';
  }

  void dispose() => _client.close();
}
