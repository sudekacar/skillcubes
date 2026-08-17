import '../domain/visual_question.dart';

/// Extracts structured visual data from plain-text quiz prompts / options.
abstract final class QuestionVisualParser {
  static final _barPair = RegExp(r'([A-Za-z])\s*=\s*(\d+(?:\.\d+)?)');
  static final _ratioPair = RegExp(
    r'(\d+)\s*/\s*(\d+)\s+vs\s+(\d+)\s*/\s*(\d+)',
    caseSensitive: false,
  );
  static final _funnelInput = RegExp(r'Girdi\s*:\s*(.+)', caseSensitive: false);
  static final _funnelRule = RegExp(r'Kural\s*:\s*([\d\-–—]+)', caseSensitive: false);
  static final _fractionOnly = RegExp(r'^(\d+)\s*/\s*(\d+)$');

  static VisualQuestion? parse({
    required String prompt,
    required String categorySlug,
  }) {
    final slug = categorySlug.toLowerCase();

    if (slug.contains('chart') ||
        slug == 'charts' ||
        prompt.contains('Çubuk') ||
        prompt.contains('cubuk')) {
      return _parseChart(prompt);
    }

    if (slug.contains('ratio') ||
        slug.contains('oran') ||
        prompt.toLowerCase().contains(' vs ')) {
      return _parseRatio(prompt);
    }

    if (slug.contains('funnel') ||
        prompt.contains('Girdi:') ||
        prompt.contains('Kural:')) {
      return _parseFunnel(prompt);
    }

    // Heuristic fallbacks regardless of slug.
    return _parseChart(prompt) ?? _parseRatio(prompt) ?? _parseFunnel(prompt);
  }

  static ChartVisual? _parseChart(String prompt) {
    final matches = _barPair.allMatches(prompt).toList();
    if (matches.length < 2) return null;
    final bars = matches
        .map(
          (m) => ChartBarData(
            label: m.group(1)!.toUpperCase(),
            value: double.parse(m.group(2)!),
          ),
        )
        .toList();
    return ChartVisual(bars: bars);
  }

  static RatioVisual? _parseRatio(String prompt) {
    final m = _ratioPair.firstMatch(prompt);
    if (m == null) return null;
    return RatioVisual(
      leftNum: int.parse(m.group(1)!),
      leftDen: int.parse(m.group(2)!),
      rightNum: int.parse(m.group(3)!),
      rightDen: int.parse(m.group(4)!),
    );
  }

  static FunnelVisual? _parseFunnel(String prompt) {
    final inputMatch = _funnelInput.firstMatch(prompt);
    final ruleMatch = _funnelRule.firstMatch(prompt);
    if (inputMatch == null || ruleMatch == null) return null;

    final raw = inputMatch.group(1)!.trim();
    // Prefer space-separated glyphs; else split into code units / runes.
    var inputs = raw
        .split(RegExp(r'\s+'))
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (inputs.length < 2) {
      inputs = raw.runes.map((r) => String.fromCharCode(r)).toList();
    }

    final order = ruleMatch
        .group(1)!
        .split(RegExp(r'[-–—]'))
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toList();
    if (inputs.isEmpty || order.isEmpty) return null;

    return FunnelVisual(inputs: inputs, ruleOrder: order);
  }

  /// Parses funnel option strings that are concatenations of glyphs.
  static List<String> parseShapeSequence(String option) {
    final trimmed = option.trim();
    if (trimmed.contains(' ')) {
      return trimmed.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    }
    // Known shape characters may be multi-code-unit; use runes.
    return trimmed.runes.map((r) => String.fromCharCode(r)).toList();
  }

  static FractionParts? parseFraction(String option) {
    final m = _fractionOnly.firstMatch(option.trim());
    if (m == null) return null;
    return FractionParts(int.parse(m.group(1)!), int.parse(m.group(2)!));
  }
}
