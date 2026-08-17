import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// Authenticated user profile from `GET /auth/me`.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.isPremium = false,
    this.streakCount = 0,
    this.streakFreezeCount = 1,
  });

  final int id;
  final String email;
  final String fullName;
  final bool isPremium;
  final int streakCount;
  final int streakFreezeCount;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        email: json['email'] as String,
        fullName: (json['full_name'] as String?) ?? '',
        isPremium: json['is_premium'] as bool? ?? false,
        streakCount: json['streak_count'] as int? ?? 0,
        streakFreezeCount: json['streak_freeze_count'] as int? ?? 1,
      );

  AuthUser copyWith({
    bool? isPremium,
    int? streakCount,
    int? streakFreezeCount,
  }) {
    return AuthUser(
      id: id,
      email: email,
      fullName: fullName,
      isPremium: isPremium ?? this.isPremium,
      streakCount: streakCount ?? this.streakCount,
      streakFreezeCount: streakFreezeCount ?? this.streakFreezeCount,
    );
  }
}

/// Handles register / login / me and persists the JWT via [ApiService].
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api);

  final ApiService _api;

  AuthUser? _user;
  bool _loading = false;
  String? _error;

  AuthUser? get user => _user;
  bool get isAuthenticated => _api.isAuthenticated;
  bool get isPremium => _user?.isPremium ?? false;
  bool get loading => _loading;
  String? get error => _error;

  /// Restore session if a token already exists.
  Future<void> tryRestoreSession() async {
    if (!_api.isAuthenticated) return;
    try {
      await fetchMe();
    } catch (_) {
      await _api.clearToken();
      _user = null;
      notifyListeners();
    }
  }

  /// Creates an account via `POST /auth/register` without starting a session.
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    await _runAuth(() async {
      await _api.postJson('/auth/register', {
        'email': email.trim(),
        'password': password,
        'full_name': fullName.trim(),
      });
      // Backend may return a JWT — discard it so the user must log in explicitly.
      await _api.clearToken();
      _user = null;
    });
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _runAuth(() async {
      final data = await _api.postJson('/auth/login', {
        'email': email.trim(),
        'password': password,
      });
      await _api.setAccessToken(data['access_token'] as String);
      await fetchMe();
    });
  }

  Future<void> fetchMe() async {
    final data = await _api.getJson('/auth/me');
    _user = AuthUser.fromJson(data);
    notifyListeners();
  }

  void applyPremiumFlag(bool isPremium) {
    final u = _user;
    if (u == null || u.isPremium == isPremium) return;
    _user = u.copyWith(isPremium: isPremium);
    notifyListeners();
  }

  /// Dev helper — flips premium via `POST /user/toggle-premium`.
  Future<bool> togglePremium() async {
    final data = await _api.postJson('/user/toggle-premium', {}, auth: true);
    final premium = data['is_premium'] as bool? ?? false;
    final u = _user;
    if (u != null) {
      _user = u.copyWith(isPremium: premium);
    } else {
      await fetchMe();
    }
    notifyListeners();
    return premium;
  }

  Future<void> logout() async {
    await _api.clearToken();
    _user = null;
    _error = null;
    notifyListeners();
  }

  Future<void> _runAuth(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
