import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/feedback/answer_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import 'arcade_metrics.dart';

/// 4×4 spatial memory: flash a pattern, then recall by tapping cells.
class SpatialGridGame extends StatefulWidget {
  const SpatialGridGame({
    super.key,
    required this.onFinished,
  });

  final ValueChanged<ArcadeMetrics> onFinished;

  @override
  State<SpatialGridGame> createState() => _SpatialGridGameState();
}

enum _Phase { show, hide, input, feedback }

class _SpatialGridGameState extends State<SpatialGridGame> {
  static const _grid = 4;
  static const _rounds = 8;
  static const _showMs = 2000;

  final _rng = Random();

  int _round = 0;
  int _hits = 0;
  int _misses = 0;
  int _errors = 0;
  final List<int> _rts = [];

  Set<int> _pattern = {};
  Set<int> _picked = {};
  _Phase _phase = _Phase.show;
  DateTime? _inputStarted;
  bool _finished = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _nextRound());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _patternSize => (3 + (_round ~/ 2)).clamp(3, 6);

  void _nextRound() {
    if (_finished) return;
    if (_round >= _rounds) {
      _end();
      return;
    }
    _timer?.cancel();
    final cells = List.generate(_grid * _grid, (i) => i)..shuffle(_rng);
    setState(() {
      _round++;
      _pattern = cells.take(_patternSize).toSet();
      _picked = {};
      _phase = _Phase.show;
      _inputStarted = null;
    });
    _timer = Timer(const Duration(milliseconds: _showMs), () {
      if (!mounted || _finished) return;
      setState(() => _phase = _Phase.hide);
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted || _finished) return;
        setState(() {
          _phase = _Phase.input;
          _inputStarted = DateTime.now();
        });
      });
    });
  }

  void _onTap(int index) {
    if (_phase != _Phase.input || _finished) return;
    if (_picked.contains(index)) return;

    setState(() => _picked.add(index));

    if (!_pattern.contains(index)) {
      _errors++;
      AnswerFeedback.show(context, isCorrect: false);
      _resolveRound(success: false);
      return;
    }

    AppHaptics.light();
    if (_picked.length >= _pattern.length) {
      final allGood = _picked.difference(_pattern).isEmpty &&
          _pattern.difference(_picked).isEmpty;
      if (allGood) {
        final ms = DateTime.now().difference(_inputStarted!).inMilliseconds;
        _hits++;
        _rts.add(ms);
        AnswerFeedback.show(context, isCorrect: true);
        _resolveRound(success: true);
      }
    }
  }

  void _resolveRound({required bool success}) {
    if (_phase == _Phase.feedback) return;
    if (!success) _misses++;
    setState(() => _phase = _Phase.feedback);
    Future.delayed(const Duration(milliseconds: 650), _nextRound);
  }

  void _end() {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
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
    final hint = switch (_phase) {
      _Phase.show => 'Ezberle…',
      _Phase.hide => '…',
      _Phase.input => 'Deseni dokun',
      _Phase.feedback => _picked.containsAll(_pattern) &&
              _pattern.containsAll(_picked)
          ? 'Doğru!'
          : 'Tekrar dene',
    };

    return Column(
      children: [
        Row(
          children: [
            Text(
              'Mekânsal  $_round/$_rounds',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              hint,
              style: TextStyle(
                color: AppColors.muted(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
                      _onTap(row * _grid + col);
                    },
                    child: CustomPaint(
                      painter: _SpatialPainter(
                        grid: _grid,
                        pattern: _pattern,
                        picked: _picked,
                        phase: _phase,
                        accent: scheme.primary,
                        mint: AppColors.mint,
                        err: AppColors.accentRed,
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

class _SpatialPainter extends CustomPainter {
  _SpatialPainter({
    required this.grid,
    required this.pattern,
    required this.picked,
    required this.phase,
    required this.accent,
    required this.mint,
    required this.err,
    required this.cellColor,
    required this.lineColor,
  });

  final int grid;
  final Set<int> pattern;
  final Set<int> picked;
  final _Phase phase;
  final Color accent;
  final Color mint;
  final Color err;
  final Color cellColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / grid;
    final line = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var i = 0; i < grid * grid; i++) {
      final r = i ~/ grid;
      final c = i % grid;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(c * cell + 5, r * cell + 5, cell - 10, cell - 10),
        const Radius.circular(12),
      );

      Color fill = cellColor;
      if (phase == _Phase.show && pattern.contains(i)) {
        fill = accent.withValues(alpha: 0.9);
      } else if (phase == _Phase.input || phase == _Phase.feedback) {
        if (picked.contains(i)) {
          if (pattern.contains(i)) {
            fill = mint.withValues(alpha: 0.85);
          } else {
            fill = err.withValues(alpha: 0.85);
          }
        } else if (phase == _Phase.feedback && pattern.contains(i)) {
          fill = accent.withValues(alpha: 0.35);
        }
      }

      canvas.drawRRect(rect, Paint()..color = fill);
      canvas.drawRRect(rect, line);
    }
  }

  @override
  bool shouldRepaint(covariant _SpatialPainter old) =>
      old.phase != phase ||
      old.pattern != pattern ||
      old.picked != picked;
}
