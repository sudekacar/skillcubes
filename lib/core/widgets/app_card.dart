import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

/// Shared rounded surface used across SkillCubes screens.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.borderColor,
    /// When false, uses a plain [GestureDetector] (no ink splash — snappier).
    this.useInk = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final bool useInk;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(
          color: borderColor ??
              (isDark ? DarkPalette.border : LightPalette.border),
          width: borderColor != null ? 2 : 1,
        ),
      ),
      child: child,
    );

    if (onTap == null) return card;

    if (!useInk) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: card,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Theme.of(context)
            .colorScheme
            .primary
            .withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: card,
      ),
    );
  }
}
