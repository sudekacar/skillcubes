import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/l10n_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/snappy_sheet.dart';
import 'premium_plan.dart';

/// Premium upsell bottom sheet — navigates to checkout on CTA.
class PaywallSheet extends StatefulWidget {
  const PaywallSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showSnappyModalSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => const PaywallSheet(),
    );
  }

  @override
  State<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<PaywallSheet> {
  bool _annualSelected = true;

  void _goCheckout() {
    AppHaptics.medium();
    final plan =
        _annualSelected ? PremiumPlan.annual : PremiumPlan.monthly;
    final router = GoRouter.of(context);
    Navigator.of(context).pop(false);
    router.push('/checkout?plan=${plan.queryValue}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onSurface = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;
    final outline = scheme.outline.withValues(
      alpha: theme.brightness == Brightness.light ? 0.45 : 0.5,
    );

    final perks = <(IconData, String, String)>[
      (
        Icons.all_inclusive,
        context.tr('perk_unlimited_title'),
        context.tr('perk_unlimited_body'),
      ),
      (
        Icons.psychology_alt_outlined,
        context.tr('perk_ai_title'),
        context.tr('perk_ai_body'),
      ),
      (
        Icons.radar,
        context.tr('perk_radar_title'),
        context.tr('perk_radar_body'),
      ),
      (
        Icons.ac_unit,
        context.tr('perk_freeze_title'),
        context.tr('perk_freeze_body'),
      ),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.45),
                ),
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: AppColors.amber,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('paywall_title'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('paywall_subtitle'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: muted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _PlanCard(
                      title: context.tr('plan_monthly'),
                      price: context.tr('plan_monthly_price'),
                      selected: !_annualSelected,
                      onTap: () {
                        AppHaptics.selection();
                        setState(() => _annualSelected = false);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PlanCard(
                      title: context.tr('plan_annual'),
                      price: context.tr('plan_annual_price'),
                      selected: _annualSelected,
                      bestValue: true,
                      onTap: () {
                        AppHaptics.selection();
                        setState(() => _annualSelected = true);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...perks.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  useInk: false,
                  borderColor: outline,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(p.$1, color: scheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.$2,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: onSurface,
                              ),
                            ),
                            Text(
                              p.$3,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _goCheckout,
                child: Text(context.tr('try_free_7_days')),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _goCheckout,
                child: Text(context.tr('upgrade_premium')),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: muted),
              child: Text(context.tr('maybe_later')),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.selected,
    required this.onTap,
    this.bestValue = false,
  });

  final String title;
  final String price;
  final bool selected;
  final bool bestValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glow = AppColors.amber;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
        decoration: BoxDecoration(
          color: selected ? glow.withValues(alpha: 0.12) : scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected || bestValue
                ? glow
                : scheme.outline.withValues(alpha: 0.4),
            width: selected || bestValue ? 2 : 1,
          ),
          boxShadow: (selected || bestValue)
              ? [
                  BoxShadow(
                    color: glow.withValues(alpha: 0.35),
                    blurRadius: 14,
                    spreadRadius: 0.5,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (bestValue)
              Positioned(
                top: -26,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: glow,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: glow.withValues(alpha: 0.45),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      context.tr('best_value'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0A192F),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
            Column(
              children: [
                const SizedBox(height: 4),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  price,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(height: 8),
                  Icon(Icons.check_circle, color: glow, size: 20),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
