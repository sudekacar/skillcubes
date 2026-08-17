/// Parsed visual payloads for specialized quiz renderers.
sealed class VisualQuestion {
  const VisualQuestion();
}

class ChartVisual extends VisualQuestion {
  const ChartVisual({
    required this.bars,
    this.questionLabel = 'En yüksek hangisi?',
  });

  final List<ChartBarData> bars;
  final String questionLabel;
}

class ChartBarData {
  const ChartBarData({required this.label, required this.value});

  final String label;
  final double value;
}

class RatioVisual extends VisualQuestion {
  const RatioVisual({
    required this.leftNum,
    required this.leftDen,
    required this.rightNum,
    required this.rightDen,
    this.prompt = 'Hangisi daha büyük?',
  });

  final int leftNum;
  final int leftDen;
  final int rightNum;
  final int rightDen;
  final String prompt;

  double get leftRatio => leftDen == 0 ? 0 : leftNum / leftDen;
  double get rightRatio => rightDen == 0 ? 0 : rightNum / rightDen;
}

class FunnelVisual extends VisualQuestion {
  const FunnelVisual({
    required this.inputs,
    required this.ruleOrder,
  });

  /// Input glyphs in original order (1-indexed rule refers to these).
  final List<String> inputs;

  /// Permutation of 1-based positions, e.g. [4, 3, 2, 1].
  final List<int> ruleOrder;
}

/// Fraction option for visual tiles.
class FractionParts {
  const FractionParts(this.num, this.den);
  final int num;
  final int den;
}
