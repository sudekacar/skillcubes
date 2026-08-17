import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/l10n_ext.dart';
import '../../../core/services/game_stats_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';

/// Category & period filtered local leaderboard.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  LeaderboardCategory _category = LeaderboardCategory.overall;
  LeaderboardPeriod _period = LeaderboardPeriod.weekly;

  String _categoryLabel(BuildContext context, LeaderboardCategory c) =>
      switch (c) {
        LeaderboardCategory.quickMath => context.tr('cat_quick_math'),
        LeaderboardCategory.goNoGo => context.tr('cat_gonogo'),
        LeaderboardCategory.problems => context.tr('cat_problems'),
        LeaderboardCategory.overall => context.tr('cat_overall'),
      };

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GameStatsStore>();
    final entries = store.filtered(category: _category, period: _period);

    return Scaffold(
      appBar: AppHeader(title: context.tr('leaderboard')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: LeaderboardCategory.values.map((c) {
                final selected = c == _category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_categoryLabel(context, c)),
                    selected: selected,
                    onSelected: (_) {
                      AppHaptics.selection();
                      setState(() => _category = c);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: LeaderboardPeriod.values.map((p) {
                final label = switch (p) {
                  LeaderboardPeriod.daily => context.tr('period_daily'),
                  LeaderboardPeriod.weekly => context.tr('period_weekly'),
                  LeaderboardPeriod.allTime => context.tr('period_all'),
                };
                final selected = p == _period;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextButton(
                      onPressed: () {
                        AppHaptics.selection();
                        setState(() => _period = p);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: selected
                            ? AppColors.scheme(context)
                                .primary
                                .withValues(alpha: 0.12)
                            : Colors.transparent,
                        foregroundColor: selected
                            ? AppColors.scheme(context).primary
                            : AppColors.muted(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(label, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      context.tr('leaderboard_empty'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted(context)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: entries.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      final medal = switch (i) {
                        0 => AppColors.amber,
                        1 => AppColors.textMuted,
                        2 => const Color(0xFFCD7F32),
                        _ => AppColors.scheme(context).primary,
                      };
                      return AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: medal.withValues(alpha: 0.2),
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: medal,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (e.subtitle != null)
                                    Text(
                                      e.subtitle!,
                                      style: TextStyle(
                                        color: AppColors.muted(context),
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              e.score.toStringAsFixed(0),
                              style: TextStyle(
                                color: AppColors.scheme(context).primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
