import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../../core/widgets/snappy_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/feedback/answer_feedback.dart';
import '../../../core/localization/l10n_ext.dart';
import '../../../core/services/game_stats_store.dart';
import '../../../core/theme/app_colors.dart';
import '../presentation/game_widgets.dart';

class _MathQ {
  _MathQ(this.display, this.answer, this.options);

  final String display;
  final int answer;
  final List<int> options;
}

class QuickMathGameScreen extends StatefulWidget {
  const QuickMathGameScreen({super.key});

  @override
  State<QuickMathGameScreen> createState() => _QuickMathGameScreenState();
}

class _QuickMathGameScreenState extends State<QuickMathGameScreen>
    with SingleTickerProviderStateMixin {
  final _rng = Random();
  late _MathQ _question;
  int _score = 0;
  int _answered = 0;
  int _secondsLeft = AppConstants.quickMathSeconds;
  Timer? _timer;
  bool _finished = false;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _question = _generate();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        _end();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  _MathQ _generate() {
    final type = _rng.nextInt(3);
    late int answer;
    late String display;
    if (type == 0) {
      final a = _rng.nextInt(9) + 2;
      final b = _rng.nextInt(9) + 2;
      final c = _rng.nextInt(9) + 2;
      final product = a * b * c;
      final missing = _rng.nextInt(40) + 10;
      answer = missing;
      display = '($a × $b × $c) − ? = ${product - missing}';
    } else if (type == 1) {
      final a = _rng.nextInt(40) + 10;
      final b = _rng.nextInt(40) + 10;
      final c = _rng.nextInt(20) + 5;
      answer = a + b - c;
      display = '$a + $b − $c = ?';
    } else {
      final a = (_rng.nextInt(12) + 3) * 5;
      final b = _rng.nextInt(8) + 2;
      answer = a ~/ b;
      display = '$a ÷ $b = ?';
    }
    final options = <int>{answer};
    while (options.length < 4) {
      options.add(answer + _rng.nextInt(21) - 10);
    }
    return _MathQ(display, answer, options.toList()..shuffle(_rng));
  }

  Future<void> _pick(int value) async {
    if (_finished) return;
    final isCorrect = value == _question.answer;
    setState(() {
      _answered++;
      if (isCorrect) _score++;
      _question = _generate();
    });
    AnswerFeedback.show(context, isCorrect: isCorrect);
  }

  Future<void> _end() async {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    final composite = _score * 10.0 + _secondsLeft;
    await context.read<GameStatsStore>().recordGameResult(
          category: LeaderboardCategory.quickMath,
          score: composite,
          subtitle: '$_score doğru / $_answered',
          badge: _score >= 15 ? 'Math Wizard' : null,
        );
    if (!mounted) return;
    await showSnappyModalSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => GameResultSheet(
        title: context.trRead('quick_math_done'),
        stats: [
          (context.trRead('correct'), '$_score'),
          (context.trRead('attempts'), '$_answered'),
          (context.trRead('score'), composite.toStringAsFixed(0)),
        ],
        onRetry: () {
          Navigator.pop(ctx);
          setState(() {
            _score = 0;
            _answered = 0;
            _secondsLeft = AppConstants.quickMathSeconds;
            _finished = false;
            _question = _generate();
            _timer = Timer.periodic(const Duration(seconds: 1), (_) {
              if (_secondsLeft <= 1) {
                _end();
              } else {
                setState(() => _secondsLeft--);
              }
            });
          });
        },
        onExit: () {
          Navigator.pop(ctx);
          context.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urgent = _secondsLeft <= 10;
    return GameScaffold(
      title: context.tr('module_quick_math'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: urgent
                              ? AppColors.accentRed
                                  .withValues(alpha: 0.15 + 0.1 * _pulse.value)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: urgent
                              ? Border.all(color: AppColors.accentRed)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: urgent
                                  ? AppColors.accentRed
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_secondsLeft sn',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: urgent
                                    ? AppColors.accentRed
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Skor $_score',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.amber,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              _question.display,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const Spacer(),
            ..._question.options.map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _pick(o),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: Text(
                      '$o',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
