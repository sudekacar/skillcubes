import 'package:flutter/material.dart';

import '../../../core/localization/l10n_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/snappy_sheet.dart';

/// Shared result bottom sheet for all SkillCubes games.
class GameResultSheet extends StatelessWidget {
  const GameResultSheet({
    super.key,
    required this.title,
    required this.stats,
    required this.onRetry,
    required this.onExit,
  });

  final String title;
  final List<(String, String)> stats;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  /// Opens the result UI with a ≤150ms slide (no heavy fade).
  static Future<void> show(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isDismissible = false,
  }) {
    return showSnappyModalSheet<void>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderOf(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          ...stats.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.$1,
                      style: TextStyle(color: AppColors.muted(context)),
                    ),
                    Text(
                      s.$2,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.scheme(context).primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onExit,
                  child: Text(context.tr('exit')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onRetry,
                  child: Text(context.tr('retry')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

PreferredSizeWidget gameAppBar(String title) => AppHeader(title: title);

class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.title,
    required this.child,
    this.bottomBar,
  });

  final String title;
  final Widget child;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gameAppBar(title),
      body: child,
      bottomNavigationBar: bottomBar,
    );
  }
}
