import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  const UserProfile({
    required this.displayName,
    this.streak = 0,
    this.totalGames = 0,
    this.badges = const [],
    this.lastPlayedDate,
  });

  final String displayName;
  final int streak;
  final int totalGames;
  final List<String> badges;
  final String? lastPlayedDate;

  UserProfile copyWith({
    String? displayName,
    int? streak,
    int? totalGames,
    List<String>? badges,
    String? lastPlayedDate,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      streak: streak ?? this.streak,
      totalGames: totalGames ?? this.totalGames,
      badges: badges ?? this.badges,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'streak': streak,
        'totalGames': totalGames,
        'badges': badges,
        'lastPlayedDate': lastPlayedDate,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        displayName: json['displayName'] as String? ?? 'Player',
        streak: json['streak'] as int? ?? 0,
        totalGames: json['totalGames'] as int? ?? 0,
        badges: (json['badges'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        lastPlayedDate: json['lastPlayedDate'] as String?,
      );
}

enum LeaderboardCategory {
  quickMath,
  goNoGo,
  problems,
  overall,
}

enum LeaderboardPeriod { daily, weekly, allTime }

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.name,
    required this.score,
    required this.category,
    required this.timestamp,
    this.subtitle,
  });

  final String name;
  final double score;
  final LeaderboardCategory category;
  final DateTime timestamp;
  final String? subtitle;

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'category': category.name,
        'timestamp': timestamp.toIso8601String(),
        'subtitle': subtitle,
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        name: json['name'] as String,
        score: (json['score'] as num).toDouble(),
        category: LeaderboardCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => LeaderboardCategory.overall,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
        subtitle: json['subtitle'] as String?,
      );
}

class GameStatsStore extends ChangeNotifier {
  GameStatsStore(this._prefs);

  final SharedPreferences _prefs;

  static const _profileKey = 'user_profile';
  static const _scoresKey = 'leaderboard_scores';
  static const _quizProgressKey = 'quiz_category_progress';
  static const _guestModeKey = 'guest_mode';

  UserProfile _profile = const UserProfile(displayName: 'Player');
  List<LeaderboardEntry> _entries = [];
  /// Best correct answers recorded per category (0–20).
  Map<String, int> _quizProgress = {};

  UserProfile get profile => _profile;
  List<LeaderboardEntry> get entries => List.unmodifiable(_entries);
  Map<String, int> get quizProgress => Map.unmodifiable(_quizProgress);

  /// True when the user chose “continue as guest” on a prior launch.
  bool get isGuestMode => _prefs.getBool(_guestModeKey) ?? false;

  /// How many sessions were logged today (overall category preferred).
  int sessionsToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return _entries.where((e) {
      return !e.timestamp.isBefore(start) &&
          e.category == LeaderboardCategory.overall;
    }).length;
  }

  /// Completed-correct count for a category card (capped at 20).
  int progressFor(String categoryId) => _quizProgress[categoryId] ?? 0;

  Future<void> load() async {
    final profileRaw = _prefs.getString(_profileKey);
    if (profileRaw != null) {
      _profile = UserProfile.fromJson(
        jsonDecode(profileRaw) as Map<String, dynamic>,
      );
    }

    final scoresRaw = _prefs.getString(_scoresKey);
    if (scoresRaw != null) {
      final list = jsonDecode(scoresRaw) as List<dynamic>;
      _entries = list
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final progressRaw = _prefs.getString(_quizProgressKey);
    if (progressRaw != null) {
      final map = jsonDecode(progressRaw) as Map<String, dynamic>;
      _quizProgress = map.map(
        (k, v) => MapEntry(k, (v as num).toInt()),
      );
    }
    notifyListeners();
  }

  Future<void> setDisplayName(String name) async {
    _profile = _profile.copyWith(
      displayName: name.trim().isEmpty ? 'Player' : name.trim(),
    );
    await _persistProfile();
  }

  Future<void> enableGuestMode() async {
    await _prefs.setBool(_guestModeKey, true);
    notifyListeners();
  }

  Future<void> clearGuestMode() async {
    await _prefs.setBool(_guestModeKey, false);
    notifyListeners();
  }

  /// Persists best correct count for a category (keeps the higher score).
  Future<void> recordQuizProgress({
    required String categoryId,
    required int answeredCorrect,
    required int total,
  }) async {
    final previous = _quizProgress[categoryId] ?? 0;
    final next = answeredCorrect.clamp(0, total);
    if (next > previous) {
      _quizProgress[categoryId] = next;
      await _prefs.setString(_quizProgressKey, jsonEncode(_quizProgress));
      notifyListeners();
    }
  }

  Future<void> recordGameResult({
    required LeaderboardCategory category,
    required double score,
    String? subtitle,
    String? badge,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).toIso8601String();
    var streak = _profile.streak;
    if (_profile.lastPlayedDate != today) {
      final yesterday = DateTime(now.year, now.month, now.day - 1)
          .toIso8601String();
      streak = _profile.lastPlayedDate == yesterday ? streak + 1 : 1;
    }

    final badges = [..._profile.badges];
    if (badge != null && !badges.contains(badge)) {
      badges.add(badge);
    }

    _profile = _profile.copyWith(
      streak: streak,
      totalGames: _profile.totalGames + 1,
      badges: badges,
      lastPlayedDate: today,
    );

    _entries.add(
      LeaderboardEntry(
        name: _profile.displayName,
        score: score,
        category: category,
        timestamp: now,
        subtitle: subtitle,
      ),
    );

    // Also bump overall with same score contribution
    if (category != LeaderboardCategory.overall) {
      _entries.add(
        LeaderboardEntry(
          name: _profile.displayName,
          score: score,
          category: LeaderboardCategory.overall,
          timestamp: now,
          subtitle: category.name,
        ),
      );
    }

    await _persistProfile();
    await _persistScores();
    notifyListeners();
  }

  List<LeaderboardEntry> filtered({
    required LeaderboardCategory category,
    required LeaderboardPeriod period,
  }) {
    final now = DateTime.now();
    final filtered = _entries.where((e) {
      if (e.category != category) return false;
      switch (period) {
        case LeaderboardPeriod.daily:
          return e.timestamp.year == now.year &&
              e.timestamp.month == now.month &&
              e.timestamp.day == now.day;
        case LeaderboardPeriod.weekly:
          return now.difference(e.timestamp).inDays < 7;
        case LeaderboardPeriod.allTime:
          return true;
      }
    }).toList();

    // For go/no-go lower is better when subtitle indicates error rate;
    // we store composite where higher is better (score = accuracy * 1000 - avgMs)
    filtered.sort((a, b) => b.score.compareTo(a.score));
    return filtered.take(50).toList();
  }

  Future<void> _persistProfile() async {
    await _prefs.setString(_profileKey, jsonEncode(_profile.toJson()));
  }

  Future<void> _persistScores() async {
    await _prefs.setString(
      _scoresKey,
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
  }
}
