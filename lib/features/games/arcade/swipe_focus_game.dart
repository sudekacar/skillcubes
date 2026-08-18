import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/feedback/answer_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import 'arcade_metrics.dart';

enum _SwipeDir { left, right, up, down }

class _Entity {
  _Entity({
    required this.id,
    required this.pos,
    required this.vel,
    required this.isTarget,
    required this.requiredDir,
    required this.hue,
    required this.radius,
    required this.spawnedAt,
  });

  final int id;
  Offset pos;
  Offset vel;
  final bool isTarget;
  final _SwipeDir requiredDir;
  final Color hue;
  final double radius;
  final DateTime spawnedAt;
  bool resolved = false;
}

/// Filter moving targets with directional swipes; ignore distractors.
class SwipeFocusGame extends StatefulWidget {
  const SwipeFocusGame({
    super.key,
    required this.onFinished,
  });

  final ValueChanged<ArcadeMetrics> onFinished;

  @override
  State<SwipeFocusGame> createState() => _SwipeFocusGameState();
}

class _SwipeFocusGameState extends State<SwipeFocusGame>
    with SingleTickerProviderStateMixin {
  static const _durationSec = 28.0;
  static const _targetGoal = 14;

  final _rng = Random();
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  final List<_Entity> _entities = [];
  int _nextId = 0;
  double _elapsed = 0;
  double _spawnAcc = 0;
  Size _field = Size.zero;

  int _hits = 0;
  int _misses = 0;
  int _errors = 0;
  final List<int> _rts = [];
  bool _finished = false;

  Offset? _dragStart;
  Offset? _dragCurrent;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_finished) return;
    final dtMs = _lastTick == Duration.zero
        ? 16
        : (elapsed - _lastTick).inMilliseconds.clamp(1, 40);
    _lastTick = elapsed;
    final dt = dtMs / 1000.0;
    _elapsed += dt;
    _spawnAcc += dt;

    if (_elapsed >= _durationSec || _hits + _misses >= _targetGoal + 4) {
      _end();
      return;
    }

    if (_field.isEmpty) {
      setState(() {});
      return;
    }

    if (_spawnAcc > 0.85) {
      _spawnAcc = 0;
      _spawn(_field);
    }

    for (final e in _entities) {
      if (e.resolved) continue;
      e.pos += e.vel * (dt * 60);
      if (_outOfBounds(e, _field)) {
        if (e.isTarget) {
          _misses++;
          AppHaptics.error();
        }
        e.resolved = true;
      }
    }
    _entities.removeWhere((e) => e.resolved);

    setState(() {});
  }

  bool _outOfBounds(_Entity e, Size size) {
    return e.pos.dx < -40 ||
        e.pos.dx > size.width + 40 ||
        e.pos.dy < -40 ||
        e.pos.dy > size.height + 40;
  }

  void _spawn(Size size) {
    final isTarget = _rng.nextDouble() < 0.55;
    final fromLeft = _rng.nextBool();
    final y = 60.0 + _rng.nextDouble() * (size.height - 120);
    final speed = 2.2 + _rng.nextDouble() * 2.4;
    final dir = isTarget
        ? (_rng.nextBool() ? _SwipeDir.right : _SwipeDir.left)
        : _SwipeDir.up;
    _entities.add(
      _Entity(
        id: _nextId++,
        pos: Offset(fromLeft ? -24 : size.width + 24, y),
        vel: Offset(fromLeft ? speed : -speed, (_rng.nextDouble() - 0.5) * 0.6),
        isTarget: isTarget,
        requiredDir: dir,
        hue: isTarget
            ? (dir == _SwipeDir.right ? AppColors.mint : AppColors.primary)
            : AppColors.accentRed.withValues(alpha: 0.85),
        radius: isTarget ? 22 : 18,
        spawnedAt: DateTime.now(),
      ),
    );
  }

  _SwipeDir? _dirFromDelta(Offset d) {
    if (d.distance < 28) return null;
    if (d.dx.abs() > d.dy.abs()) {
      return d.dx > 0 ? _SwipeDir.right : _SwipeDir.left;
    }
    return d.dy > 0 ? _SwipeDir.down : _SwipeDir.up;
  }

  void _onSwipe(_SwipeDir dir, Offset at) {
    _Entity? best;
    var bestDist = 72.0;
    for (final e in _entities) {
      if (e.resolved) continue;
      final d = (e.pos - at).distance;
      if (d < bestDist) {
        bestDist = d;
        best = e;
      }
    }
    if (best == null) return;

    if (!best.isTarget) {
      best.resolved = true;
      _errors++;
      AnswerFeedback.show(context, isCorrect: false);
      return;
    }

    if (best.requiredDir != dir) {
      best.resolved = true;
      _errors++;
      AnswerFeedback.show(context, isCorrect: false);
      return;
    }

    best.resolved = true;
    _hits++;
    _rts.add(DateTime.now().difference(best.spawnedAt).inMilliseconds);
    AnswerFeedback.show(context, isCorrect: true);
  }

  void _end() {
    if (_finished) return;
    _finished = true;
    _ticker.stop();
    widget.onFinished(
      ArcadeMetrics(
        hits: _hits,
        misses: _misses,
        errors: _errors,
        responseTimesMs: List.unmodifiable(_rts),
        totalRounds: max(_targetGoal, _hits + _misses),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_elapsed / _durationSec).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Selektif Odak',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              '$_hits hit',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.scheme(context).primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.borderOf(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Yeşil → sağa · Mavi → sola · Kırmızıyı yok say',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.muted(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _field = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) {
                  _dragStart = d.localPosition;
                  _dragCurrent = d.localPosition;
                },
                onPanUpdate: (d) => _dragCurrent = d.localPosition,
                onPanEnd: (_) {
                  final s = _dragStart;
                  final c = _dragCurrent;
                  _dragStart = null;
                  _dragCurrent = null;
                  if (s == null || c == null) return;
                  final dir = _dirFromDelta(c - s);
                  if (dir == null) return;
                  _onSwipe(dir, s);
                  setState(() {});
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _SwipePainter(
                    entities: List.unmodifiable(_entities),
                    dragStart: _dragStart,
                    dragCurrent: _dragCurrent,
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

class _SwipePainter extends CustomPainter {
  _SwipePainter({
    required this.entities,
    required this.dragStart,
    required this.dragCurrent,
  });

  final List<_Entity> entities;
  final Offset? dragStart;
  final Offset? dragCurrent;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x148892B0)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    for (final e in entities) {
      if (e.resolved) continue;
      final glow = Paint()
        ..color = e.hue.withValues(alpha: 0.35)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 12);
      canvas.drawCircle(e.pos, e.radius * 1.35, glow);

      final fill = Paint()..color = e.hue;
      if (e.isTarget) {
        canvas.drawCircle(e.pos, e.radius, fill);
        final arrow = Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        final tip = switch (e.requiredDir) {
          _SwipeDir.right => e.pos + const Offset(10, 0),
          _SwipeDir.left => e.pos + const Offset(-10, 0),
          _SwipeDir.up => e.pos + const Offset(0, -10),
          _SwipeDir.down => e.pos + const Offset(0, 10),
        };
        canvas.drawLine(e.pos, tip, arrow);
      } else {
        final rect = Rect.fromCenter(
          center: e.pos,
          width: e.radius * 1.7,
          height: e.radius * 1.7,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          fill,
        );
      }
    }

    if (dragStart != null && dragCurrent != null) {
      final p = Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(dragStart!, dragCurrent!, p);
    }
  }

  @override
  bool shouldRepaint(covariant _SwipePainter old) => true;
}
