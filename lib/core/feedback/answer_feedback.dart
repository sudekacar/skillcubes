import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../localization/l10n_ext.dart';
import '../theme/app_colors.dart';
import '../utils/haptics.dart';

/// Shared correct/wrong feedback for quizzes, games, and tests.
///
/// ```dart
/// AnswerFeedback.show(context, isCorrect: picked == correctIndex);
/// ```
class AnswerFeedback {
  AnswerFeedback._();

  static OverlayEntry? _entry;

  /// Shows confetti + praise, or shake + emoji + playful message.
  static void show(
    BuildContext context, {
    required bool isCorrect,
  }) {
    _dismiss();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _FeedbackLayer(
        isCorrect: isCorrect,
        onDismiss: () {
          entry.remove();
          if (_entry == entry) _entry = null;
        },
      ),
    );

    _entry = entry;
    overlay.insert(entry);

    if (isCorrect) {
      unawaited(AppHaptics.success());
    } else {
      unawaited(AppHaptics.error());
    }
  }

  static void _dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

class _FeedbackLayer extends StatefulWidget {
  const _FeedbackLayer({
    required this.isCorrect,
    required this.onDismiss,
  });

  final bool isCorrect;
  final VoidCallback onDismiss;

  @override
  State<_FeedbackLayer> createState() => _FeedbackLayerState();
}

class _FeedbackLayerState extends State<_FeedbackLayer>
    with SingleTickerProviderStateMixin {
  ConfettiController? _confetti;
  late AnimationController _shake;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    if (widget.isCorrect) {
      _confetti = ConfettiController(
        duration: const Duration(milliseconds: 1200),
      )..play();
    } else {
      _shake.forward();
    }

    _timer = Timer(
      Duration(milliseconds: widget.isCorrect ? 1700 : 1500),
      () {
        if (mounted) widget.onDismiss();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confetti?.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.isCorrect
        ? context.trRead('feedback_correct')
        : context.trRead('feedback_wrong');

    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.isCorrect && _confetti != null)
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confetti!,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  emissionFrequency: 0.08,
                  numberOfParticles: 22,
                  maxBlastForce: 28,
                  minBlastForce: 12,
                  gravity: 0.18,
                  colors: const [
                    AppColors.primary,
                    AppColors.mint,
                    AppColors.amber,
                    AppColors.accentRed,
                    Colors.white,
                  ],
                ),
              ),
            Center(
              child: widget.isCorrect
                  ? _PraiseBubble(message: message)
                  : _ShakeBubble(
                      controller: _shake,
                      message: message,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PraiseBubble extends StatelessWidget {
  const _PraiseBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.mint.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShakeBubble extends StatelessWidget {
  const _ShakeBubble({
    required this.controller,
    required this.message,
  });

  final AnimationController controller;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        final dx = math.sin(t * math.pi * 6) * 12 * (1 - t);
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.accentRed.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentRed.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😭', style: TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
