import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Maps unicode puzzle glyphs → styled geometric painters.
abstract final class ShapeGlyphs {
  static const indigo = Color(0xFF6366F1);
  static const emerald = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const rose = Color(0xFFF43F5E);
  static const sky = Color(0xFF0EA5E9);
  static const violet = Color(0xFF8B5CF6);

  static Color colorFor(String glyph) {
    return switch (glyph) {
      '▲' || '△' => amber,
      '■' || '∎' || '█' || '▢' => sky,
      '●' || '○' => emerald,
      '◆' || '◇' || '♦' => indigo,
      '★' || '☆' => rose,
      '✚' || '+' || '┼' => violet,
      _ => indigo,
    };
  }

  static Widget build(
    String glyph, {
    double size = 28,
    Color? color,
  }) {
    final c = color ?? colorFor(glyph);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GlyphPainter(glyph: glyph, color: c),
      ),
    );
  }

  static Widget sequence(
    List<String> glyphs, {
    double size = 26,
    double gap = 6,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < glyphs.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          build(glyphs[i], size: size),
        ],
      ],
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({required this.glyph, required this.color});

  final String glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final glow = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    Path path;
    switch (glyph) {
      case '▲':
      case '△':
        path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r * 0.95, cy + r * 0.85)
          ..lineTo(cx - r * 0.95, cy + r * 0.85)
          ..close();
      case '■':
      case '∎':
      case '█':
      case '▢':
        final s = r * 1.5;
        path = Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, cy), width: s, height: s),
              const Radius.circular(3),
            ),
          );
      case '●':
      case '○':
        path = Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      case '◆':
      case '◇':
      case '♦':
        path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r, cy)
          ..close();
      case '★':
      case '☆':
        path = _star(Offset(cx, cy), r, r * 0.45, 5);
      case '✚':
      case '+':
      case '┼':
        final t = r * 0.35;
        path = Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, cy), width: t, height: r * 2),
              const Radius.circular(2),
            ),
          )
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: t),
              const Radius.circular(2),
            ),
          );
      default:
        path = Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    }

    canvas.drawPath(path, glow);
    canvas.drawPath(path, fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  Path _star(Offset c, double outer, double inner, int points) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + (i * math.pi / points);
      final p = Offset(
        c.dx + radius * math.cos(angle),
        c.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color;
}
