import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/l10n_ext.dart';
import '../../../core/services/category_provider.dart';
import '../../../core/services/game_stats_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import '../presentation/game_widgets.dart';
import 'arcade_catalog.dart';
import 'arcade_completion.dart';
import 'arcade_metrics.dart';
import 'spatial_grid_game.dart';
import 'speed_tap_game.dart';
import 'swipe_focus_game.dart';

/// Host screen for Touch Arcade mini-games (intro → play → AI result).
class ArcadeGameScreen extends StatefulWidget {
  const ArcadeGameScreen({
    super.key,
    required this.kind,
    required this.categoryId,
    required this.categorySlug,
    required this.title,
  });

  final ArcadeKind kind;
  final int categoryId;
  final String categorySlug;
  final String title;

  @override
  State<ArcadeGameScreen> createState() => _ArcadeGameScreenState();
}

class _ArcadeGameScreenState extends State<ArcadeGameScreen> {
  bool _started = false;
  int _session = 0;
  bool _finishing = false;

  LeaderboardCategory get _lbCategory => switch (widget.kind) {
        ArcadeKind.speedTap => LeaderboardCategory.quickMath,
        ArcadeKind.spatialGrid => LeaderboardCategory.overall,
        ArcadeKind.swipeFocus => LeaderboardCategory.goNoGo,
      };

  String get _displayTitle {
    final remote = context.read<CategoryProvider>().byId(widget.categoryId);
    if (widget.title.isNotEmpty) return widget.title;
    if (remote != null) return remote.title;
    return context.tr(widget.kind.titleKey);
  }

  Future<void> _onFinished(ArcadeMetrics metrics) async {
    if (_finishing) return;
    _finishing = true;
    await ArcadeCompletion.finish(
      context,
      metrics: metrics,
      categoryId: widget.categoryId,
      categorySlug: widget.categorySlug,
      title: _displayTitle,
      leaderboardCategory: _lbCategory,
      onRetry: () {
        setState(() {
          _started = true;
          _session++;
          _finishing = false;
        });
      },
    );
    if (mounted) _finishing = false;
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: _displayTitle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: !_started
            ? _Intro(
                kind: widget.kind,
                onStart: () async {
                  await AppHaptics.medium();
                  setState(() => _started = true);
                },
              )
            : KeyedSubtree(
                key: ValueKey(_session),
                child: switch (widget.kind) {
                  ArcadeKind.speedTap => SpeedTapGame(onFinished: _onFinished),
                  ArcadeKind.spatialGrid =>
                    SpatialGridGame(onFinished: _onFinished),
                  ArcadeKind.swipeFocus =>
                    SwipeFocusGame(onFinished: _onFinished),
                },
              ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.kind, required this.onStart});

  final ArcadeKind kind;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final icon = switch (kind) {
      ArcadeKind.speedTap => Icons.flash_on_rounded,
      ArcadeKind.spatialGrid => Icons.grid_on_rounded,
      ArcadeKind.swipeFocus => Icons.swipe_rounded,
    };
    final color = switch (kind) {
      ArcadeKind.speedTap => AppColors.amber,
      ArcadeKind.spatialGrid => AppColors.mint,
      ArcadeKind.swipeFocus => AppColors.primary,
    };

    return Column(
      children: [
        const Spacer(),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 44, color: color),
        ),
        const SizedBox(height: 20),
        Text(
          context.tr(kind.titleKey),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr(kind.rulesKey),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.45,
            color: AppColors.muted(context),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onStart,
            child: Text(context.tr('start_training')),
          ),
        ),
      ],
    );
  }
}
