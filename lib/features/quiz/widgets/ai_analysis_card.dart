import 'package:flutter/material.dart';

import '../../../core/localization/l10n_ext.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
import '../../premium/paywall_sheet.dart';

/// Shows Emma's cognitive coaching after a quiz or arcade session.
class AiAnalysisCard extends StatelessWidget {
  const AiAnalysisCard({
    super.key,
    required this.result,
    this.onUnlocked,
  });

  final AiAnalysisResult result;
  final VoidCallback? onUnlocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onSurface = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;
    final outline = scheme.outline.withValues(
      alpha: theme.brightness == Brightness.light ? 0.35 : 0.5,
    );

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderColor: outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: scheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('emma_coach_badge'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (result.isPremiumLocked)
                const Icon(Icons.lock_outline, size: 18, color: AppColors.amber),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.summary,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          if (result.recommendedCategory.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.recommend_outlined,
                  size: 18,
                  color: AppColors.mint,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('ai_recommended', {
                      'category': result.recommendedCategory,
                    }),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: muted,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Text(
            context.tr('emma_advice_title'),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 8),
          if (result.isPremiumLocked)
            _LockedReport(
              onUnlock: () async {
                await AppHaptics.medium();
                if (!context.mounted) return;
                final upgraded = await PaywallSheet.show(context);
                if (upgraded == true) onUnlocked?.call();
              },
            )
          else
            Text(
              result.detailedReport,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}

/// Static locked overlay — no blur / opacity animations (GPU-friendly).
class _LockedReport extends StatelessWidget {
  const _LockedReport({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final outline = scheme.outline.withValues(
      alpha: theme.brightness == Brightness.light ? 0.4 : 0.5,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: muted.withValues(
          alpha: theme.brightness == Brightness.light ? 0.12 : 0.18,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        child: Column(
          children: [
            // Lightweight placeholder bars instead of blurred text.
            _PlaceholderBar(color: muted.withValues(alpha: 0.25), widthFactor: 1),
            const SizedBox(height: 8),
            _PlaceholderBar(color: muted.withValues(alpha: 0.2), widthFactor: 0.92),
            const SizedBox(height: 8),
            _PlaceholderBar(color: muted.withValues(alpha: 0.18), widthFactor: 0.78),
            const SizedBox(height: 14),
            const Icon(Icons.lock, color: AppColors.amber, size: 28),
            const SizedBox(height: 8),
            Text(
              context.tr('ai_unlock_hint'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: onUnlock,
              icon: const Icon(Icons.workspace_premium, size: 18),
              label: Text(context.tr('unlock_premium')),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderBar extends StatelessWidget {
  const _PlaceholderBar({
    required this.color,
    required this.widthFactor,
  });

  final Color color;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
