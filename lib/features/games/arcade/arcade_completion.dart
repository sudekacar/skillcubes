import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/l10n_ext.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/category_provider.dart';
import '../../../core/services/game_stats_store.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/snappy_sheet.dart';
import '../../quiz/data/question_repository.dart';
import '../../quiz/widgets/ai_analysis_card.dart';
import 'arcade_metrics.dart';

/// Persists arcade metrics, runs AI coach, and shows the result sheet.
class ArcadeCompletion {
  ArcadeCompletion._();

  static Future<void> finish(
    BuildContext context, {
    required ArcadeMetrics metrics,
    required int categoryId,
    required String categorySlug,
    required String title,
    required LeaderboardCategory leaderboardCategory,
    required VoidCallback onRetry,
  }) async {
    final scorePct = metrics.scorePercent;

    await context.read<GameStatsStore>().recordQuizProgress(
          categoryId: '$categoryId',
          answeredCorrect: metrics.hits,
          total: metrics.analyzeTotal,
        );
    if (!context.mounted) return;

    try {
      await QuestionRepository(api: context.read<ApiService>()).syncProgress(
        categoryId: categoryId,
        completedQuestions: metrics.hits.clamp(0, 20),
        score: scorePct,
      );
      if (context.mounted) {
        context.read<CategoryProvider>().patchLocalProgress(
              categoryId: categoryId,
              completedQuestions: metrics.hits.clamp(0, 20),
              score: scorePct,
            );
      }
    } catch (_) {}

    if (!context.mounted) return;
    await context.read<GameStatsStore>().recordGameResult(
          category: leaderboardCategory,
          score: scorePct.toDouble(),
          subtitle:
              '$title · ${metrics.hits}/${metrics.analyzeTotal} · ${metrics.avgReactionMs.round()} ms',
          badge: metrics.accuracy >= 0.85 ? 'Arcade Ace' : null,
        );
    if (!context.mounted) return;

    AiAnalysisResult? analysis;
    final api = context.read<ApiService>();
    if (api.isAuthenticated && categorySlug.isNotEmpty) {
      try {
        analysis = await PremiumService(api).analyzePerformance(
          categorySlug: categorySlug,
          score: metrics.analyzeScore,
          totalQuestions: metrics.analyzeTotal,
          responseTimes: metrics.responseTimesSec,
        );
      } catch (_) {}
    }

    if (!context.mounted) return;

    final maxH =
        MediaQuery.sizeOf(context).height * (analysis == null ? 0.52 : 0.8);

    await showSnappyModalSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: ListView(
              shrinkWrap: true,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderOf(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.trRead('arcade_complete'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 14),
                _statRow(
                  context,
                  context.trRead('score'),
                  '$scorePct',
                ),
                _statRow(
                  context,
                  context.trRead('hits'),
                  '${metrics.hits}',
                ),
                _statRow(
                  context,
                  context.trRead('misses'),
                  '${metrics.misses}',
                ),
                _statRow(
                  context,
                  context.trRead('error_rate'),
                  '${(metrics.errorRate * 100).toStringAsFixed(0)}%',
                ),
                _statRow(
                  context,
                  context.trRead('avg_reaction'),
                  '${metrics.avgReactionMs.round()} ms',
                ),
                if (analysis != null) ...[
                  const SizedBox(height: 14),
                  AiAnalysisCard(
                    result: analysis,
                    onUnlocked: () async {
                      Navigator.pop(ctx);
                      if (!context.mounted) return;
                      await finish(
                        context,
                        metrics: metrics,
                        categoryId: categoryId,
                        categorySlug: categorySlug,
                        title: title,
                        leaderboardCategory: leaderboardCategory,
                        onRetry: onRetry,
                      );
                    },
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.pop();
                        },
                        child: Text(context.trRead('exit')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onRetry();
                        },
                        child: Text(context.trRead('retry')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _statRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: AppColors.muted(context))),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.scheme(context).primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
