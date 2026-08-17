import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/l10n_ext.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/services/category_provider.dart';
import '../../../core/services/game_stats_store.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/snappy_sheet.dart';
import '../../premium/paywall_sheet.dart';
import '../data/question_repository.dart';
import '../domain/quiz_category.dart';
import '../widgets/ai_analysis_card.dart';
import '../widgets/quiz_option_tile.dart';
import '../widgets/visual_question_panel.dart';
import 'quiz_controller.dart';

/// Category quiz — always starts at Question 1.
class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.remoteCategoryId,
    this.localFallback,
    this.title,
  });

  final int remoteCategoryId;
  final QuizCategoryId? localFallback;
  final String? title;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  QuizController? _controller;
  bool _resultShown = false;
  bool _paywallShowing = false;
  Timer? _tickTimer;
  int _elapsedSec = 0;

  void _startTicker() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final quiz = _controller;
      if (!mounted || quiz == null || quiz.answered || quiz.finished) return;
      setState(() {
        _elapsedSec = quiz.currentQuestionElapsedSec.round();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;

    final api = context.read<ApiService>();
    final remote =
        context.read<CategoryProvider>().byId(widget.remoteCategoryId);
    final controller = QuizController(
      remoteCategoryId: widget.remoteCategoryId,
      localFallback: widget.localFallback ?? _slugToLocal(remote?.slug),
      title: widget.title ?? remote?.title ?? '',
      categorySlug: remote?.slug ?? '',
      isLocked: remote?.isLocked ?? false,
      repository: QuestionRepository(api: api),
    );
    _controller = controller;
    controller.addListener(_onQuizChanged);
    controller.start().then((_) {
      if (mounted) {
        setState(() => _elapsedSec = 0);
        _startTicker();
      }
    });
  }

  QuizCategoryId? _slugToLocal(String? slug) {
    return switch (slug) {
      'funnel' => QuizCategoryId.funnel,
      'pattern' || 'oruntu-yakalama' => QuizCategoryId.pattern,
      'quick_math' || 'hizli-matematik' => QuizCategoryId.quickMath,
      'ratio' => QuizCategoryId.ratio,
      'charts' => QuizCategoryId.charts,
      'go_nogo' || 'go-nogo' => QuizCategoryId.goNoGo,
      'logical' || 'logical_reasoning' => QuizCategoryId.logicalReasoning,
      'english' => QuizCategoryId.english,
      _ => null,
    };
  }

  void _onQuizChanged() {
    final quiz = _controller;
    if (quiz == null) return;

    if (quiz.paywallRequested && !_paywallShowing) {
      _paywallShowing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final upgraded = await PaywallSheet.show(context);
        quiz.clearPaywallRequest();
        _paywallShowing = false;

        if (upgraded == true && mounted) {
          final remote =
              context.read<CategoryProvider>().byId(widget.remoteCategoryId);
          quiz.isLocked = remote?.isLocked ?? false;
          setState(() => _resultShown = false);
          await quiz.start();
          return;
        }

        if (quiz.finished && !_resultShown && mounted) {
          _resultShown = true;
          await _showResult();
        }
      });
      return;
    }

    if (quiz.finished && !_resultShown && !quiz.paywallRequested) {
      _resultShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showResult();
      });
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _controller?.removeListener(_onQuizChanged);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _showResult() async {
    final quiz = _controller!;
    final scorePct = quiz.total == 0
        ? 0
        : ((quiz.correctCount / quiz.total) * 100).round();

    await context.read<GameStatsStore>().recordQuizProgress(
          categoryId: '${widget.remoteCategoryId}',
          answeredCorrect: quiz.correctCount,
          total: quiz.total,
        );
    if (!mounted) return;

    try {
      await quiz.syncProgressToBackend(score: scorePct);
      if (mounted) {
        context.read<CategoryProvider>().patchLocalProgress(
              categoryId: widget.remoteCategoryId,
              completedQuestions: quiz.correctCount,
              score: scorePct,
            );
      }
    } catch (_) {}

    if (!mounted) return;
    await context.read<GameStatsStore>().recordGameResult(
          category: LeaderboardCategory.overall,
          score: scorePct.toDouble(),
          subtitle: '${quiz.title} ${quiz.correctCount}/${quiz.total}',
          badge: scorePct >= 80 ? 'Quiz Ace' : null,
        );
    if (!mounted) return;

    AiAnalysisResult? analysis;
    final api = context.read<ApiService>();
    final slug = quiz.categorySlug.isNotEmpty
        ? quiz.categorySlug
        : context
                .read<CategoryProvider>()
                .byId(widget.remoteCategoryId)
                ?.slug ??
            '';
    if (api.isAuthenticated && slug.isNotEmpty) {
      try {
        analysis = await PremiumService(api).analyzePerformance(
          categorySlug: slug,
          score: quiz.correctCount,
          totalQuestions: quiz.total.clamp(1, 20),
          responseTimes: quiz.responseTimes,
        );
      } catch (_) {}
    }

    if (!mounted) return;

    final maxH = MediaQuery.sizeOf(context).height * (analysis == null ? 0.5 : 0.78);

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
                  context.trRead('quiz_complete'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.trRead('correct'),
                        style: TextStyle(color: AppColors.muted(context)),
                      ),
                      Text(
                        '${quiz.correctCount} / ${quiz.total}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.scheme(context).primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.trRead('score'),
                        style: TextStyle(color: AppColors.muted(context)),
                      ),
                      Text(
                        '$scorePct',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.scheme(context).primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (analysis != null) ...[
                  const SizedBox(height: 14),
                  AiAnalysisCard(
                    result: analysis,
                    onUnlocked: () async {
                      Navigator.pop(ctx);
                      final remote = context
                          .read<CategoryProvider>()
                          .byId(widget.remoteCategoryId);
                      quiz.isLocked = remote?.isLocked ?? false;
                      setState(() => _resultShown = false);
                      _resultShown = true;
                      await _showResult();
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
                          setState(() => _resultShown = false);
                          quiz.start();
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

  @override
  Widget build(BuildContext context) {
    final quiz = _controller;
    if (quiz == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final remote =
        context.watch<CategoryProvider>().byId(widget.remoteCategoryId);
    final title = widget.title ?? remote?.title ?? context.tr('nav_train');
    final accent = remote?.color ?? AppColors.primary;
    if (remote != null) {
      quiz.isLocked =
          remote.isLocked && !context.watch<AuthProvider>().isPremium;
    }

    return ChangeNotifierProvider.value(
      value: quiz,
      child: Consumer<QuizController>(
        builder: (context, quiz, _) {
          final total = quiz.progressTotal;
          final progress =
              total == 0 ? 0.0 : (quiz.displayNumber / total).clamp(0.0, 1.0);

          return Scaffold(
            appBar: AppHeader(title: title),
            body: quiz.loading
                ? const Center(child: CircularProgressIndicator())
                : quiz.error != null || quiz.total == 0
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            quiz.error ?? context.tr('leaderboard_empty'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _QuizTopBar(
                              current: quiz.displayNumber,
                              total: total,
                              isPreview: quiz.isLocked,
                              correct: quiz.correctCount,
                              elapsedSec: quiz.answered
                                  ? (quiz.responseTimes.isEmpty
                                      ? _elapsedSec
                                      : quiz.responseTimes.last.round())
                                  : _elapsedSec,
                              progress: progress,
                              accent: accent,
                            ),
                            const SizedBox(height: 16),
                            AppCard(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                              child: VisualQuestionPanel(
                                key: ValueKey(
                                  '${quiz.index}_${quiz.current.id}',
                                ),
                                prompt: quiz.current.prompt,
                                categorySlug: quiz.categorySlug,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView.separated(
                                itemCount: quiz.current.options.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final q = quiz.current;
                                  final showCorrect =
                                      quiz.answered && i == q.correctIndex;
                                  final showIncorrect = quiz.answered &&
                                      i == quiz.selectedIndex &&
                                      i != q.correctIndex;
                                  return QuizOptionTile(
                                    index: i,
                                    label: q.options[i],
                                    categorySlug: quiz.categorySlug,
                                    selected: quiz.selectedIndex == i,
                                    showCorrect: showCorrect,
                                    showIncorrect: showIncorrect,
                                    enabled: !quiz.answered && !quiz.finished,
                                    onTap: () {
                                      AppHaptics.selection();
                                      quiz.selectOption(i);
                                      if (i == q.correctIndex) {
                                        AppHaptics.success();
                                      } else {
                                        AppHaptics.error();
                                      }
                                      setState(() {});
                                    },
                                  );
                                },
                              ),
                            ),
                            if (quiz.answered && quiz.current.hint != null) ...[
                              AppCard(
                                color: AppColors.amber.withValues(alpha: 0.1),
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  quiz.current.hint!,
                                  style: const TextStyle(
                                    color: AppColors.amber,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (quiz.answered && !quiz.finished)
                              ElevatedButton(
                                onPressed: () {
                                  AppHaptics.medium();
                                  quiz.next();
                                  setState(() => _elapsedSec = 0);
                                  _startTicker();
                                },
                                child: Text(
                                  quiz.displayNumber >= quiz.total
                                      ? context.tr('finish')
                                      : context.tr('next'),
                                ),
                              ),
                          ],
                        ),
                      ),
          );
        },
      ),
    );
  }
}

class _QuizTopBar extends StatelessWidget {
  const _QuizTopBar({
    required this.current,
    required this.total,
    required this.isPreview,
    required this.correct,
    required this.elapsedSec,
    required this.progress,
    required this.accent,
  });

  final int current;
  final int total;
  final bool isPreview;
  final int correct;
  final int elapsedSec;
  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.muted(context);
    final mm = (elapsedSec ~/ 60).toString().padLeft(2, '0');
    final ss = (elapsedSec % 60).toString().padLeft(2, '0');

    final label = isPreview
        ? context.tr('question_preview', {
            'current': '$current',
            'total': '$total',
          })
        : context.tr('question_of', {
            'current': '$current',
            'total': '$total',
          });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            if (isPreview) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  context.tr('preview_chip'),
                  style: const TextStyle(
                    color: AppColors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.timer_outlined, size: 16, color: muted),
            const SizedBox(width: 4),
            Text(
              '$mm:$ss',
              style: TextStyle(
                color: muted,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$correct ✓',
              style: const TextStyle(
                color: AppColors.mint,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: AppColors.borderOf(context),
            color: accent,
          ),
        ),
      ],
    );
  }
}
