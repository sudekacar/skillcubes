import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/l10n_ext.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/services/category_provider.dart';
import '../../../core/services/game_stats_store.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../quiz/domain/quiz_category.dart';
import '../../ai_coach/emma_coach_banner.dart';
import '../arcade/arcade_catalog.dart';

/// Main training dashboard — interactive 2-column category cards (20 questions).
class GamesHubScreen extends StatefulWidget {
  const GamesHubScreen({super.key});

  @override
  State<GamesHubScreen> createState() => _GamesHubScreenState();
}

class _GamesHubScreenState extends State<GamesHubScreen> {
  static const _dailyGoal = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().refresh();
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        NotificationService.instance.ensureDailyReminderScheduled();
      }
    });
  }

  int _todayProgress(GameStatsStore store) {
    return store.sessionsToday().clamp(0, _dailyGoal);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GameStatsStore>();
    final profile = store.profile;
    final auth = context.watch<AuthProvider>();
    final cats = context.watch<CategoryProvider>();
    final displayName = auth.user?.fullName.isNotEmpty == true
        ? auth.user!.fullName
        : profile.displayName;
    final streak = auth.user?.streakCount ?? profile.streak;
    final todayDone = _todayProgress(store);
    final goalRatio = (todayDone / _dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppHeader(title: context.tr('nav_train')),
      body: RefreshIndicator(
        onRefresh: () => context.read<CategoryProvider>().refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              context.tr('hello', {'name': displayName}),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('dashboard_prompt'),
              style: TextStyle(color: AppColors.muted(context)),
            ),
            const SizedBox(height: 16),
            _StreakHeroBanner(
              streak: streak,
              todayDone: todayDone,
              dailyGoal: _dailyGoal,
              goalRatio: goalRatio,
            ),
            const SizedBox(height: 14),
            const EmmaCoachBanner(),
            const SizedBox(height: 20),
            Text(
              context.tr('categories_title'),
              style: TextStyle(
                color: AppColors.muted(context),
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            if (cats.loading && cats.categories.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (cats.error != null && cats.categories.isEmpty)
              AppCard(
                child: Column(
                  children: [
                    Text(
                      cats.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted(context)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () =>
                          context.read<CategoryProvider>().refresh(),
                      child: Text(context.tr('retry')),
                    ),
                  ],
                ),
              )
            else
              _CategoryGrid(
                remote: cats.categories,
                store: store,
              ),
          ],
        ),
      ),
    );
  }
}

class _StreakHeroBanner extends StatelessWidget {
  const _StreakHeroBanner({
    required this.streak,
    required this.todayDone,
    required this.dailyGoal,
    required this.goalRatio,
  });

  final int streak;
  final int todayDone;
  final int dailyGoal;
  final double goalRatio;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A3358),
                  scheme.primary.withValues(alpha: 0.35),
                ]
              : [
                  scheme.primary.withValues(alpha: 0.12),
                  AppColors.amber.withValues(alpha: 0.18),
                ],
        ),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: isDark ? 0.18 : 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('🔥', style: TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('streak_hero_title', {'count': '$streak'}),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('streak_hero_sub'),
                      style: TextStyle(
                        color: AppColors.muted(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                context.tr('daily_goal'),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.muted(context),
                ),
              ),
              const Spacer(),
              Text(
                '$todayDone / $dailyGoal',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: goalRatio,
              minHeight: 8,
              backgroundColor: AppColors.borderOf(context),
              color: AppColors.amber,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.remote,
    required this.store,
  });

  final List<RemoteCategory> remote;
  final GameStatsStore store;

  @override
  Widget build(BuildContext context) {
    final useRemote = remote.isNotEmpty;
    final count = useRemote ? remote.length : kQuizCategories.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        if (useRemote) {
          final category = remote[index];
          return RepaintBoundary(
            key: ValueKey<String>('cat_${category.id}'),
            child: _CategoryCard(
              title: category.title,
              subtitle: category.description,
              icon: category.icon,
              color: category.color,
              done: category.completedQuestions,
              total: category.totalQuestions,
              isLocked: category.isLocked,
              questionLimit: category.questionLimit,
              onTap: () {
                AppHaptics.light();
                context.push(category.routePath);
              },
            ),
          );
        }

        final category = kQuizCategories[index];
        return RepaintBoundary(
          key: ValueKey<String>('local_${category.id.name}'),
          child: _CategoryCard(
            title: context.tr(category.titleKey),
            subtitle: context.tr(category.subtitleKey),
            icon: category.icon,
            color: category.color,
            done: store.progressFor(category.id.name),
            total: AppConstants.questionsPerCategory,
            onTap: () {
              AppHaptics.light();
              final arcade = switch (category.id) {
                QuizCategoryId.quickMath => ArcadeKind.speedTap,
                QuizCategoryId.pattern => ArcadeKind.spatialGrid,
                QuizCategoryId.goNoGo => ArcadeKind.swipeFocus,
                _ => null,
              };
              if (arcade != null) {
                context.push(
                  ArcadeKind.routeFor(
                    kind: arcade,
                    categoryId: category.id.index + 1,
                    slug: category.id.name,
                    title: context.tr(category.titleKey),
                  ),
                );
              } else {
                context.push('/dashboard/quiz/local/${category.id.name}');
              }
            },
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.done,
    required this.total,
    required this.onTap,
    this.isLocked = false,
    this.questionLimit = 20,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int done;
  final int total;
  final VoidCallback onTap;
  final bool isLocked;
  final int questionLimit;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashFactory: NoSplash.splashFactory,
        highlightColor: color.withValues(alpha: 0.08),
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: isDark ? 0.16 : 0.08),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.35),
                            color.withValues(alpha: 0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const Spacer(),
                    if (isLocked)
                      const Icon(Icons.lock, size: 15, color: AppColors.amber),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Flexible(
                        flex: 3,
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        flex: 2,
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            color: AppColors.muted(context),
                            fontSize: 11,
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 5,
                    backgroundColor: AppColors.borderOf(context),
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isLocked
                      ? context.tr('teaser_badge', {'count': '$questionLimit'})
                      : context.tr('completed_of', {
                          'done': '$done',
                          'total': '$total',
                        }),
                  style: TextStyle(
                    color: AppColors.muted(context),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
