import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../games/arcade/arcade_catalog.dart';

/// SkillCubes training categories shown on the dashboard.
enum QuizCategoryId {
  funnel,
  pattern,
  quickMath,
  ratio,
  charts,
  goNoGo,
  logicalReasoning,
  english,
}

/// UI metadata for a dashboard / quiz category.
class QuizCategory {
  const QuizCategory({
    required this.id,
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
    required this.color,
  });

  final QuizCategoryId id;
  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final Color color;

  String get routePath {
    final arcade = switch (id) {
      QuizCategoryId.quickMath => ArcadeKind.speedTap,
      QuizCategoryId.pattern => ArcadeKind.spatialGrid,
      QuizCategoryId.goNoGo => ArcadeKind.swipeFocus,
      _ => null,
    };
    if (arcade != null) {
      return ArcadeKind.routeFor(
        kind: arcade,
        categoryId: id.index + 1,
        slug: id.name,
        title: '',
      );
    }
    return '/dashboard/quiz/local/${id.name}';
  }

  static QuizCategoryId? tryParse(String? raw) {
    if (raw == null) return null;
    for (final id in QuizCategoryId.values) {
      if (id.name == raw) return id;
    }
    return null;
  }
}

/// Canonical list of interactive category cards (2-column dashboard grid).
const kQuizCategories = <QuizCategory>[
  QuizCategory(
    id: QuizCategoryId.funnel,
    titleKey: 'module_funnel',
    subtitleKey: 'module_funnel_sub',
    icon: Icons.filter_alt_outlined,
    color: AppColors.primary,
  ),
  QuizCategory(
    id: QuizCategoryId.pattern,
    titleKey: 'module_pattern',
    subtitleKey: 'module_pattern_sub',
    icon: Icons.grid_view_rounded,
    color: AppColors.mint,
  ),
  QuizCategory(
    id: QuizCategoryId.quickMath,
    titleKey: 'module_quick_math',
    subtitleKey: 'module_quick_math_sub',
    icon: Icons.calculate_outlined,
    color: AppColors.amber,
  ),
  QuizCategory(
    id: QuizCategoryId.ratio,
    titleKey: 'module_ratio',
    subtitleKey: 'module_ratio_sub',
    icon: Icons.balance_outlined,
    color: AppColors.primary,
  ),
  QuizCategory(
    id: QuizCategoryId.charts,
    titleKey: 'module_charts',
    subtitleKey: 'module_charts_sub',
    icon: Icons.bar_chart_rounded,
    color: AppColors.mint,
  ),
  QuizCategory(
    id: QuizCategoryId.goNoGo,
    titleKey: 'module_gonogo',
    subtitleKey: 'module_gonogo_sub',
    icon: Icons.touch_app_outlined,
    color: AppColors.accentRed,
  ),
  QuizCategory(
    id: QuizCategoryId.logicalReasoning,
    titleKey: 'module_logical',
    subtitleKey: 'module_logical_sub',
    icon: Icons.psychology_outlined,
    color: AppColors.amber,
  ),
  QuizCategory(
    id: QuizCategoryId.english,
    titleKey: 'module_english',
    subtitleKey: 'module_english_sub',
    icon: Icons.translate_outlined,
    color: AppColors.primary,
  ),
];

QuizCategory categoryById(QuizCategoryId id) =>
    kQuizCategories.firstWhere((c) => c.id == id);

/// Shared quiz size used across dashboard badges and quiz sessions.
const int kQuestionsPerCategory = AppConstants.questionsPerCategory;
