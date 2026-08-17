import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/l10n_ext.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/services/category_provider.dart';
import '../../../core/services/game_stats_store.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../premium/paywall_sheet.dart';
import '../widgets/radar_chart.dart';

/// Profile, badges, streak, and theme/language settings.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  bool _remindersEnabled = true;
  bool _remindersLoaded = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: context.read<GameStatsStore>().profile.displayName,
    );
    _loadReminderPref();
  }

  Future<void> _loadReminderPref() async {
    final enabled = await NotificationService.instance.remindersEnabled;
    if (!mounted) return;
    setState(() {
      _remindersEnabled = enabled;
      _remindersLoaded = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GameStatsStore>();
    final profile = store.profile;
    final theme = context.watch<ThemeProvider>();
    final locale = context.watch<LocaleProvider>();
    final auth = context.watch<AuthProvider>();
    final isPremium = auth.isPremium;

    return Scaffold(
      appBar: AppHeader(title: context.tr('nav_profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.scheme(context).primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    profile.displayName.isNotEmpty
                        ? profile.displayName[0].toUpperCase()
                        : (auth.user?.fullName.isNotEmpty == true
                            ? auth.user!.fullName[0].toUpperCase()
                            : '?'),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.scheme(context).primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.user?.fullName.isNotEmpty == true
                            ? auth.user!.fullName
                            : profile.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('trainings_done', {
                          'count': '${profile.totalGames}',
                        }),
                        style: TextStyle(color: AppColors.muted(context)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (isPremium ? AppColors.amber : AppColors.mint)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isPremium
                              ? context.tr('plan_premium')
                              : context.tr('plan_free'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isPremium ? AppColors.amber : AppColors.mint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (auth.isAuthenticated) ...[
            const SizedBox(height: 16),
            _CognitiveStatsBadges(store: store),
            const SizedBox(height: 12),
            const CognitiveRadarChart(),
            if (!isPremium) ...[
              const SizedBox(height: 12),
              AppCard(
                useInk: false,
                onTap: () async {
                  await AppHaptics.medium();
                  if (!context.mounted) return;
                  await PaywallSheet.show(context);
                },
                color: AppColors.amber.withValues(alpha: 0.08),
                borderColor: AppColors.amber.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium, color: AppColors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr('upgrade_premium'),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppColors.muted(context)),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: context.tr('streak'),
                  value: '${auth.user?.streakCount ?? profile.streak}',
                  icon: Icons.local_fire_department,
                  color: AppColors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  label: context.tr('badges'),
                  value: '${profile.badges.length}',
                  icon: Icons.military_tech_outlined,
                  color: AppColors.mint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('badges'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 10),
          if (profile.badges.isEmpty)
            AppCard(
              child: Text(
                context.tr('badge_empty'),
                style: TextStyle(color: AppColors.muted(context)),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.badges
                  .map(
                    (b) => Chip(
                      avatar: const Icon(
                        Icons.star,
                        size: 16,
                        color: AppColors.amber,
                      ),
                      label: Text(b),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 28),
          Text(
            context.tr('settings'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 10),
          // Theme toggle
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('theme')),
              subtitle: Text(
                theme.isDark
                    ? context.tr('theme_dark')
                    : context.tr('theme_light'),
                style: TextStyle(color: AppColors.muted(context)),
              ),
              secondary: Icon(
                theme.isDark ? Icons.dark_mode : Icons.light_mode,
                color: AppColors.scheme(context).primary,
              ),
              value: theme.isDark,
              activeThumbColor: AppColors.scheme(context).primary,
              onChanged: (_) async {
                await AppHaptics.selection();
                await theme.toggleDarkLight();
              },
            ),
          ),
          const SizedBox(height: 12),
          // Daily streak reminder
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('streak_reminders')),
              subtitle: Text(
                context.tr('streak_reminders_sub'),
                style: TextStyle(color: AppColors.muted(context)),
              ),
              secondary: Icon(
                Icons.notifications_active_outlined,
                color: AppColors.scheme(context).primary,
              ),
              value: _remindersEnabled,
              activeThumbColor: AppColors.scheme(context).primary,
              onChanged: !_remindersLoaded
                  ? null
                  : (value) async {
                      await AppHaptics.selection();
                      setState(() => _remindersEnabled = value);
                      await NotificationService.instance
                          .setRemindersEnabled(value);
                    },
            ),
          ),
          const SizedBox(height: 12),
          // Language selector
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('language'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _LangChip(
                        label: context.tr('lang_tr'),
                        selected: locale.language == AppLanguage.tr,
                        onTap: () async {
                          await AppHaptics.selection();
                          await locale.setLanguage(AppLanguage.tr);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LangChip(
                        label: context.tr('lang_en'),
                        selected: locale.language == AppLanguage.en,
                        onTap: () async {
                          await AppHaptics.selection();
                          await locale.setLanguage(AppLanguage.en);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('update_name'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(hintText: context.tr('display_name_hint')),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await AppHaptics.medium();
              await store.setDisplayName(_nameController.text);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.trRead('profile_saved'))),
              );
            },
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
  }
}
class _CognitiveStatsBadges extends StatelessWidget {
  const _CognitiveStatsBadges({required this.store});

  final GameStatsStore store;

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<CategoryProvider>();
    final tests = store.profile.totalGames;
    final overall = store.entries
        .where((e) => e.category == LeaderboardCategory.overall)
        .toList();
    final avg = overall.isEmpty
        ? 0
        : (overall.map((e) => e.score).reduce((a, b) => a + b) / overall.length)
            .round();

    String topArea = '—';
    if (cats.categories.isNotEmpty) {
      final best = [...cats.categories]
        ..sort((a, b) => b.score.compareTo(a.score));
      if (best.first.score > 0) {
        topArea = best.first.title;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _AnimatedStatBadge(
            icon: Icons.fitness_center,
            color: AppColors.primary,
            value: '$tests',
            label: context.tr('stat_tests'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _AnimatedStatBadge(
            icon: Icons.my_location,
            color: AppColors.mint,
            value: '%$avg',
            label: context.tr('stat_accuracy'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _AnimatedStatBadge(
            icon: Icons.emoji_events_outlined,
            color: AppColors.amber,
            value: topArea,
            label: context.tr('stat_top_area'),
            compact: true,
          ),
        ),
      ],
    );
  }
}

class _AnimatedStatBadge extends StatefulWidget {
  const _AnimatedStatBadge({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.compact = false,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final bool compact;

  @override
  State<_AnimatedStatBadge> createState() => _AnimatedStatBadgeState();
}

class _AnimatedStatBadgeState extends State<_AnimatedStatBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.86, end: 1).animate(_scale),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          children: [
            Icon(widget.icon, color: widget.color, size: 20),
            const SizedBox(height: 6),
            Text(
              widget.value,
              maxLines: widget.compact ? 1 : 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: widget.compact ? 12 : 16,
                color: widget.color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.muted(context),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.scheme(context).primary.withValues(alpha: 0.15)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.scheme(context).primary
                  : AppColors.borderOf(context),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected
                  ? AppColors.scheme(context).primary
                  : AppColors.muted(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(color: AppColors.muted(context))),
        ],
      ),
    );
  }
}
