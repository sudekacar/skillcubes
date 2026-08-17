import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/visual_question.dart';
import 'shape_glyphs.dart';

/// Side-by-side proportion comparison for "Oran & Karşılaştırma".
class RatioQuestionView extends StatelessWidget {
  const RatioQuestionView({super.key, required this.data});

  final RatioVisual data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          data.prompt,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _RatioCard(
                num: data.leftNum,
                den: data.leftDen,
                ratio: data.leftRatio,
                color: ShapeGlyphs.indigo,
                label: 'A',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'VS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: _RatioCard(
                num: data.rightNum,
                den: data.rightDen,
                ratio: data.rightRatio,
                color: ShapeGlyphs.emerald,
                label: 'B',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RatioCard extends StatelessWidget {
  const _RatioCard({
    required this.num,
    required this.den,
    required this.ratio,
    required this.color,
    required this.label,
  });

  final int num;
  final int den;
  final double ratio;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = (ratio.clamp(0.0, 1.0) * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.16),
            scheme.surface,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 88,
            height: 88,
            child: CustomPaint(
              painter: _PiePainter(
                progress: ratio.clamp(0.0, 1.0),
                color: color,
                track: scheme.outline.withValues(alpha: 0.2),
              ),
              child: Center(
                child: Text(
                  '$num/$den',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: scheme.outline.withValues(alpha: 0.15),
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '%$pct',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Compact fraction chip for option tiles.
class RatioOptionChip extends StatelessWidget {
  const RatioOptionChip({
    super.key,
    required this.num,
    required this.den,
    this.accent,
  });

  final int num;
  final int den;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? ShapeGlyphs.indigo;
    final ratio = den == 0 ? 0.0 : (num / den).clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$num / $den',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 7,
                  backgroundColor: color.withValues(alpha: 0.15),
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
