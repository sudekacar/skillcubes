import 'package:flutter/material.dart';

import '../../features/games/arcade/arcade_catalog.dart';
import '../theme/app_colors.dart';
import 'api_service.dart';

/// Category DTO from `GET /categories`.
class RemoteCategory {
  const RemoteCategory({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.totalQuestions,
    required this.iconName,
    required this.completedQuestions,
    required this.score,
    this.isFree = false,
    this.isLocked = false,
    this.questionLimit = 20,
  });

  final int id;
  final String slug;
  final String title;
  final String description;
  final int totalQuestions;
  final String iconName;
  final int completedQuestions;
  final int score;
  final bool isFree;
  final bool isLocked;
  final int questionLimit;

  String get routePath {
    final arcade = ArcadeKind.forSlug(slug);
    if (arcade != null) {
      return ArcadeKind.routeFor(
        kind: arcade,
        categoryId: id,
        slug: slug,
        title: title,
      );
    }
    return '/dashboard/quiz/$id';
  }

  Color get color => switch (slug) {
        'funnel' ||
        'ratio' ||
        'english' ||
        'hizli-matematik' =>
          AppColors.primary,
        'pattern' ||
        'oruntu-yakalama' ||
        'charts' =>
          AppColors.mint,
        'quick_math' ||
        'logical' ||
        'logical_reasoning' =>
          AppColors.amber,
        'go_nogo' || 'go-nogo' => AppColors.accentRed,
        _ => AppColors.primary,
      };

  IconData get icon => switch (slug) {
        'funnel' => Icons.filter_alt_outlined,
        'pattern' || 'oruntu-yakalama' => Icons.grid_view_rounded,
        'quick_math' || 'hizli-matematik' => Icons.calculate_outlined,
        'ratio' => Icons.balance_outlined,
        'charts' => Icons.bar_chart_rounded,
        'go_nogo' || 'go-nogo' => Icons.touch_app_outlined,
        'logical' || 'logical_reasoning' => Icons.psychology_outlined,
        'english' => Icons.translate_outlined,
        _ => Icons.quiz_outlined,
      };

  factory RemoteCategory.fromJson(Map<String, dynamic> json) => RemoteCategory(
        id: json['id'] as int,
        slug: json['slug'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        totalQuestions: json['total_questions'] as int? ?? 20,
        iconName: json['icon_name'] as String? ?? 'quiz',
        completedQuestions: json['completed_questions'] as int? ?? 0,
        score: json['score'] as int? ?? 0,
        isFree: json['is_free'] as bool? ?? false,
        isLocked: json['is_locked'] as bool? ?? false,
        questionLimit: json['question_limit'] as int? ?? 20,
      );

  RemoteCategory copyWith({
    int? completedQuestions,
    int? score,
    bool? isFree,
    bool? isLocked,
    int? questionLimit,
  }) {
    return RemoteCategory(
      id: id,
      slug: slug,
      title: title,
      description: description,
      totalQuestions: totalQuestions,
      iconName: iconName,
      completedQuestions: completedQuestions ?? this.completedQuestions,
      score: score ?? this.score,
      isFree: isFree ?? this.isFree,
      isLocked: isLocked ?? this.isLocked,
      questionLimit: questionLimit ?? this.questionLimit,
    );
  }
}

/// Loads and caches categories for the dashboard.
class CategoryProvider extends ChangeNotifier {
  CategoryProvider(this._api);

  final ApiService _api;

  List<RemoteCategory> _categories = [];
  bool _loading = false;
  String? _error;
  int _statsEpoch = 0;

  List<RemoteCategory> get categories => List.unmodifiable(_categories);
  bool get loading => _loading;
  String? get error => _error;

  /// Bumps when progress changes so profile radar can refetch.
  int get statsEpoch => _statsEpoch;

  RemoteCategory? byId(int id) {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> refresh() async {
    if (!_api.isAuthenticated) {
      _categories = [];
      _error = null;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _api.getJsonList('/categories');
      _categories = list
          .map((e) => RemoteCategory.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void patchLocalProgress({
    required int categoryId,
    required int completedQuestions,
    required int score,
  }) {
    _categories = [
      for (final c in _categories)
        if (c.id == categoryId)
          c.copyWith(
            completedQuestions: completedQuestions > c.completedQuestions
                ? completedQuestions
                : c.completedQuestions,
            score: score > c.score ? score : c.score,
          )
        else
          c,
    ];
    _statsEpoch++;
    notifyListeners();
  }
}
