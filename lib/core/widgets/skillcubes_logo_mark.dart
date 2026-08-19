import 'package:flutter/material.dart';

/// Crisp vector SkillCubes mark (book + cubes) — no raster assets.
class SkillCubesLogoMark extends StatelessWidget {
  const SkillCubesLogoMark({
    super.key,
    this.size = 88,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SkillCubesLogoPainter(
          primary: scheme.primary,
          accent: scheme.tertiary,
          highlight: scheme.secondary,
        ),
      ),
    );
  }
}

class _SkillCubesLogoPainter extends CustomPainter {
  _SkillCubesLogoPainter({
    required this.primary,
    required this.accent,
    required this.highlight,
  });

  final Color primary;
  final Color accent;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bookRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.12, w * 0.72, h * 0.76),
      Radius.circular(w * 0.1),
    );

    final bookPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, Color.lerp(primary, accent, 0.45)!],
      ).createShader(bookRect.outerRect);

    canvas.drawRRect(bookRect, bookPaint);

    final spine = Paint()..color = primary.withValues(alpha: 0.35);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.14, h * 0.12, w * 0.1, h * 0.76),
        Radius.circular(w * 0.06),
      ),
      spine,
    );

    void cube(double cx, double cy, double side, Color color) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: side, height: side),
        Radius.circular(side * 0.22),
      );
      canvas.drawRRect(rect, Paint()..color = color);
      canvas.drawRRect(
        rect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = side * 0.08,
      );
    }

    final cubeSize = w * 0.16;
    cube(w * 0.52, h * 0.38, cubeSize, highlight);
    cube(w * 0.68, h * 0.52, cubeSize * 0.92, Colors.white.withValues(alpha: 0.95));
    cube(w * 0.48, h * 0.58, cubeSize * 0.88, accent);

    final page = Paint()..color = Colors.white.withValues(alpha: 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.28, h * 0.22, w * 0.48, h * 0.08),
        Radius.circular(w * 0.04),
      ),
      page,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.28, h * 0.34, w * 0.38, h * 0.06),
        Radius.circular(w * 0.03),
      ),
      page,
    );
  }

  @override
  bool shouldRepaint(covariant _SkillCubesLogoPainter old) =>
      old.primary != primary || old.accent != accent || old.highlight != highlight;
}
