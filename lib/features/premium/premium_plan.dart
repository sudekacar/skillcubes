/// Selected SkillCubes Premium billing plan.
enum PremiumPlanKind { monthly, annual }

class PremiumPlan {
  const PremiumPlan({
    required this.kind,
    required this.titleKey,
    required this.priceLabel,
    required this.periodLabel,
    required this.trialLabel,
  });

  final PremiumPlanKind kind;
  final String titleKey;
  final String priceLabel;
  final String periodLabel;
  final String trialLabel;

  bool get isAnnual => kind == PremiumPlanKind.annual;

  static const annual = PremiumPlan(
    kind: PremiumPlanKind.annual,
    titleKey: 'plan_annual',
    priceLabel: '₺599.99',
    periodLabel: '/yr',
    trialLabel: '7-Day Free Trial',
  );

  static const monthly = PremiumPlan(
    kind: PremiumPlanKind.monthly,
    titleKey: 'plan_monthly',
    priceLabel: '₺99.99',
    periodLabel: '/mo',
    trialLabel: '7-Day Free Trial',
  );

  static PremiumPlan fromQuery(String? raw) {
    if (raw == 'monthly') return monthly;
    return annual;
  }

  String get queryValue => isAnnual ? 'annual' : 'monthly';
}
