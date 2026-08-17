/// Raw performance metrics from a Touch Arcade session.
class ArcadeMetrics {
  const ArcadeMetrics({
    required this.hits,
    required this.misses,
    required this.errors,
    required this.responseTimesMs,
    this.totalRounds = 0,
  });

  final int hits;
  final int misses;
  final int errors;
  final List<int> responseTimesMs;
  final int totalRounds;

  int get attempts => hits + misses + errors;

  double get accuracy {
    final n = attempts;
    if (n == 0) return 0;
    return hits / n;
  }

  double get errorRate => 1 - accuracy;

  double get avgReactionMs {
    if (responseTimesMs.isEmpty) return 0;
    return responseTimesMs.reduce((a, b) => a + b) / responseTimesMs.length;
  }

  /// 0–100 score for progress / radar.
  int get scorePercent {
    final acc = accuracy;
    final speedBonus = responseTimesMs.isEmpty
        ? 0.0
        : (1.0 - (avgReactionMs.clamp(200, 1200) - 200) / 1000).clamp(0.0, 1.0);
    return ((acc * 0.75 + speedBonus * 0.25) * 100).round().clamp(0, 100);
  }

  /// Correct-count style score for `POST /ai/analyze`.
  int get analyzeScore => hits;

  int get analyzeTotal {
    final t = totalRounds > 0 ? totalRounds : attempts;
    return t.clamp(1, 40);
  }

  /// Seconds (matches quiz controller convention).
  List<double> get responseTimesSec => responseTimesMs
      .map((ms) => double.parse((ms / 1000).toStringAsFixed(2)))
      .toList(growable: false);
}
