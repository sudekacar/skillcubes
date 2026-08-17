import 'api_service.dart';

/// Cognitive radar axis from `GET /user/radar-stats`.
class RadarAxisStat {
  const RadarAxisStat({
    required this.slug,
    required this.title,
    required this.percentage,
  });

  final String slug;
  final String title;
  final double percentage;

  factory RadarAxisStat.fromJson(Map<String, dynamic> json) => RadarAxisStat(
        slug: json['slug'] as String,
        title: json['title'] as String? ?? '',
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      );

  /// Short English radar label (Speed / Memory / Math / Logic / Focus / Pattern).
  String get radarLabel => switch (slug) {
        'hizli-matematik' || 'quick_math' => 'Math',
        'oruntu-yakalama' || 'pattern' => 'Pattern',
        'funnel' || 'logical' || 'logical_reasoning' => 'Logic',
        'ratio' => 'Speed',
        'charts' => 'Memory',
        'go-nogo' || 'go_nogo' => 'Focus',
        _ => title.isNotEmpty ? title : slug,
      };
}

class RadarStats {
  const RadarStats({required this.axes, required this.isPremium});

  final List<RadarAxisStat> axes;
  final bool isPremium;

  factory RadarStats.fromJson(Map<String, dynamic> json) {
    final raw = json['axes'] as List<dynamic>? ?? const [];
    return RadarStats(
      axes: raw
          .map((e) => RadarAxisStat.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      isPremium: json['is_premium'] as bool? ?? false,
    );
  }
}

/// Response from `POST /ai/analyze`.
class AiAnalysisResult {
  const AiAnalysisResult({
    required this.summary,
    required this.detailedReport,
    required this.recommendedCategory,
    required this.isPremiumLocked,
  });

  final String summary;
  final String detailedReport;
  final String recommendedCategory;
  final bool isPremiumLocked;

  factory AiAnalysisResult.fromJson(Map<String, dynamic> json) =>
      AiAnalysisResult(
        summary: json['summary'] as String? ?? '',
        detailedReport: json['detailed_report'] as String? ?? '',
        recommendedCategory: json['recommended_category'] as String? ?? '',
        isPremiumLocked: json['is_premium_locked'] as bool? ?? false,
      );
}

/// Thin API facade for premium / AI / radar endpoints.
class PremiumService {
  PremiumService(this._api);

  final ApiService _api;

  Future<RadarStats> fetchRadarStats() async {
    final data = await _api.getJson('/user/radar-stats');
    return RadarStats.fromJson(data);
  }

  Future<AiAnalysisResult> analyzePerformance({
    required String categorySlug,
    required int score,
    required int totalQuestions,
    List<double> responseTimes = const [],
  }) async {
    final data = await _api.postJson(
      '/ai/analyze',
      {
        'category_slug': categorySlug,
        'score': score,
        'total_questions': totalQuestions,
        'response_times': responseTimes,
      },
      auth: true,
    );
    return AiAnalysisResult.fromJson(data);
  }

  Future<String> chatWithEmma({
    required String message,
    List<Map<String, String>> history = const [],
  }) async {
    final data = await _api.postJson(
      '/ai/chat',
      {
        'message': message,
        'history': history,
      },
      auth: true,
    );
    return data['reply'] as String? ?? '';
  }

  Future<bool> togglePremium() async {
    final data = await _api.postJson('/user/toggle-premium', {}, auth: true);
    return data['is_premium'] as bool? ?? false;
  }
}
