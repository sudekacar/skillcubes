import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/l10n_ext.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/services/category_provider.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/widgets/app_card.dart';

/// Indigo fill used for the radar polygon (explicit brand accent).
const Color kRadarIndigo = Color(0xFF6366F1);

/// 6-axis spider/radar chart fed by `GET /user/radar-stats`.
class CognitiveRadarChart extends StatefulWidget {
  const CognitiveRadarChart({super.key});

  @override
  State<CognitiveRadarChart> createState() => _CognitiveRadarChartState();
}

class _CognitiveRadarChartState extends State<CognitiveRadarChart>
    with SingleTickerProviderStateMixin {
  RadarStats? _stats;
  bool _loading = true;
  String? _error;
  int _seenEpoch = -1;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final epoch = context.watch<CategoryProvider>().statsEpoch;
    if (_seenEpoch >= 0 && epoch != _seenEpoch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
    _seenEpoch = epoch;
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = context.read<ApiService>();
    if (!api.isAuthenticated) {
      setState(() {
        _loading = false;
        _error = null;
        _stats = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stats = await PremiumService(api).fetchRadarStats();
      if (!mounted) return;
      context.read<AuthProvider>().applyPremiumFlag(stats.isPremium);
      setState(() {
        _stats = stats;
        _loading = false;
      });
      _pulse.forward(from: 0);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onSurface = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;
    final outline = scheme.outline.withValues(
      alpha: theme.brightness == Brightness.light ? 0.55 : 0.45,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.radar, color: kRadarIndigo, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('radar_title'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
              ),
              IconButton(
                tooltip: context.tr('retry'),
                onPressed: _loading ? null : _load,
                icon: Icon(Icons.refresh, size: 20, color: muted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('radar_subtitle'),
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              ),
            )
          else if (_stats == null || _stats!.axes.isEmpty)
            SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  context.tr('radar_empty'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              ),
            )
          else
            SizedBox(
              height: 260,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  return RepaintBoundary(
                    child: CustomPaint(
                      isComplex: true,
                      willChange: false,
                      painter: _RadarPainter(
                        axes: _stats!.axes,
                        fillColor: kRadarIndigo,
                        gridColor: outline,
                        labelColor: muted,
                        valueColor: onSurface,
                        spokeColor: outline,
                        grow: Curves.easeOut.transform(_pulse.value),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.axes,
    required this.fillColor,
    required this.gridColor,
    required this.labelColor,
    required this.valueColor,
    required this.spokeColor,
    this.grow = 1,
  });

  final List<RadarAxisStat> axes;
  final Color fillColor;
  final Color gridColor;
  final Color labelColor;
  final Color valueColor;
  final Color spokeColor;
  final double grow;

  @override
  void paint(Canvas canvas, Size size) {
    final n = axes.length;
    if (n == 0) return;

    final center = Offset(size.width / 2, size.height / 2 + 8);
    final radius = math.min(size.width, size.height) * 0.32;

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final spokePaint = Paint()
      ..color = spokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var ring = 1; ring <= 5; ring++) {
      final r = radius * (ring / 5);
      final path = Path();
      for (var i = 0; i < n; i++) {
        final p = _point(center, r, i, n);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    final labelStyle = TextStyle(
      color: labelColor,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    for (var i = 0; i < n; i++) {
      final tip = _point(center, radius, i, n);
      canvas.drawLine(center, tip, spokePaint);

      final tp = TextPainter(
        text: TextSpan(text: axes[i].radarLabel, style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      final labelPos = _point(center, radius + 22, i, n);
      tp.paint(
        canvas,
        Offset(labelPos.dx - tp.width / 2, labelPos.dy - tp.height / 2),
      );
    }

    final dataPath = Path();
    for (var i = 0; i < n; i++) {
      final pct = axes[i].percentage.clamp(0, 100) / 100 * grow;
      final p = _point(center, radius * pct, i, n);
      if (i == 0) {
        dataPath.moveTo(p.dx, p.dy);
      } else {
        dataPath.lineTo(p.dx, p.dy);
      }
    }
    dataPath.close();

    final bounds = dataPath.getBounds();
    final gradient = ui.Gradient.radial(
      center,
      radius,
      [
        fillColor.withValues(alpha: 0.45),
        fillColor.withValues(alpha: 0.12),
      ],
      const [0.15, 1.0],
    );

    canvas.drawPath(
      dataPath,
      Paint()
        ..shader = gradient
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Silence unused warning if bounds unused in some engines.
    assert(bounds.width >= 0);

    for (var i = 0; i < n; i++) {
      final pct = axes[i].percentage.clamp(0, 100) / 100 * grow;
      final p = _point(center, radius * pct, i, n);
      canvas.drawCircle(p, 4, Paint()..color = fillColor);
      canvas.drawCircle(
        p,
        4,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  Offset _point(Offset center, double r, int i, int n) {
    final angle = -math.pi / 2 + (2 * math.pi * i / n);
    return Offset(
      center.dx + r * math.cos(angle),
      center.dy + r * math.sin(angle),
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.axes != axes ||
        oldDelegate.grow != grow ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.gridColor != gridColor;
  }
}
