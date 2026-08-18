import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/feedback/answer_feedback.dart';
import '../../../core/theme/app_colors.dart';
import 'arcade_metrics.dart';

/// Glowing targets appear one-by-one on a grid; tap before they expire.
class SpeedTapGame extends StatefulWidget {
  const SpeedTapGame({
    super.key,
    required this.onFinished,
  });

  final ValueChanged<ArcadeMetrics> onFinished;

  @override
  State<SpeedTapGame> createState() => _SpeedTapGameState();
}

class _SpeedTapGameState extends State<SpeedTapGame>
    with SingleTickerProviderStateMixin {
  static const _grid = 4;
  static const _rounds = 16;
  static const _windowMs = 900;

  final _rng = Random();
  late final Ticker _ticker;

  int _round = 0;
  int _hits = 0;
  int _misses = 0;
  int _errors = 0;
  final List<int> _rts = [];

  int? _activeIndex;
  DateTime? _shownAt;
  double _pulse = 0;
  bool _finished = false;
  Timer? _expireTimer;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (_activeIndex == null) return;
      setState(() => _pulse = (elapsed.inMilliseconds % 600) / 600);
    })
      ..start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _spawn());
  }

  @override
  void dispose() {
    _expireTimer?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  void _spawn() {
    if (_finished) return;
    if (_round >= _rounds) {
      _end();
      return;
    }
    _expireTimer?.cancel();
    setState(() {
      _round++;
      _activeIndex = _rng.nextInt(_grid * _grid);
      _shownAt = DateTime.now();
    });
    _expireTimer = Timer(const Duration(milliseconds: _windowMs), () {
      if (_finished || _activeIndex == null || !mounted) return;
      setState(() {
        _misses++;
        _activeIndex = null;
      });
      AnswerFeedback.show(context, isCorrect: false);
      Future.delayed(const Duration(milliseconds: 220), _spawn);
    });
  }

  void _onTapCell(int index) {
    if (_finished || _activeIndex == null) return;
    if (index != _activeIndex) {
      setState(() => _errors++);
      AnswerFeedback.show(context, isCorrect: false);
      return;
    }
    final ms = DateTime.now().difference(_shownAt!).inMilliseconds;
    _expireTimer?.cancel();
    setState(() {
      _hits++;
      _rts.add(ms);
      _activeIndex = null;
    });
    AnswerFeedback.show(context, isCorrect: true);
    Future.delayed(const Duration(milliseconds: 180), _spawn);
  }

  void _end() {
    if (_finished) return;
    _finished = true;
    _expireTimer?.cancel();
    widget.onFinished(
      ArcadeMetrics(
        hits: _hits,
        misses: _misses,
        errors: _errors,
        responseTimesMs: List.unmodifiable(_rts),
        totalRounds: _rounds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        _Hud(
          round: _round,
          total: _rounds,
          hits: _hits,
          label: 'Speed Tap',
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = min(constraints.maxWidth, constraints.maxHeight);
              return Center(
                child: SizedBox(
                  width: size,
                  height: size,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) {
                      final cell = size / _grid;
                      final col = (d.localPosition.dx / cell)
                          .floor()
                          .clamp(0, _grid - 1);
                      final row = (d.localPosition.dy / cell)
                          .floor()
                          .clamp(0, _grid - 1);
                      _onTapCell(row * _grid + col);
                    },
                    child: CustomPaint(
                      painter: _SpeedTapPainter(
                        grid: _grid,
                        activeIndex: _activeIndex,
                        pulse: _pulse,
                        accent: scheme.primary,
                        cellColor: scheme.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        lineColor: scheme.outline.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SpeedTapPainter extends CustomPainter {
  _SpeedTapPainter({
    required this.grid,
    required this.activeIndex,
    required this.pulse,
    required this.accent,
    required this.cellColor,
    required this.lineColor,
  });

  final int grid;
  final int? activeIndex;
  final double pulse;
  final Color accent;
  final Color cellColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / grid;
    final bg = Paint()..color = cellColor;
    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (var r = 0; r < grid; r++) {
      for (var c = 0; c < grid; c++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(c * cell + 4, r * cell + 4, cell - 8, cell - 8),
          const Radius.circular(14),
        );
        canvas.drawRRect(rect, bg);
        canvas.drawRRect(rect, line);
      }
    }

    if (activeIndex != null) {
      final r = activeIndex! ~/ grid;
      final c = activeIndex! % grid;
      final glow = 0.45 + 0.55 * (0.5 + 0.5 * sin(pulse * pi * 2));
      final center = Offset(c * cell + cell / 2, r * cell + cell / 2);
      final radius = cell * 0.28 * (0.92 + 0.08 * glow);

      final glowPaint = Paint()
        ..color = accent.withValues(alpha: 0.35 * glow)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 18);
      canvas.drawCircle(center, radius * 1.55, glowPaint);

      final core = Paint()..color = accent.withValues(alpha: 0.95);
      canvas.drawCircle(center, radius, core);

      final ring = Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(center, radius * 0.72, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedTapPainter old) =>
      old.activeIndex != activeIndex ||
      old.pulse != pulse ||
      old.accent != accent;
}

class _Hud extends StatelessWidget {
  const _Hud({
    required this.round,
    required this.total,
    required this.hits,
    required this.label,
  });

  final int round;
  final int total;
  final int hits;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label  $round/$total',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        Icon(Icons.bolt, size: 16, color: AppColors.scheme(context).primary),
        const SizedBox(width: 4),
        Text('$hits', style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}
