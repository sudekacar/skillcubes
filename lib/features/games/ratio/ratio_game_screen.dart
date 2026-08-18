import 'dart:math';

import 'package:flutter/material.dart';
import '../../../core/widgets/snappy_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/feedback/answer_feedback.dart';
import '../../../core/localization/l10n_ext.dart';
import '../../../core/services/game_stats_store.dart';
import '../../../core/theme/app_colors.dart';
import '../presentation/game_widgets.dart';

class _RatioQ {
  _RatioQ(this.prompt, this.leftLabel, this.rightLabel, this.leftWins);

  final String prompt;
  final String leftLabel;
  final String rightLabel;
  final bool leftWins; // true => left bigger/heavier
}

class RatioGameScreen extends StatefulWidget {
  const RatioGameScreen({super.key});

  @override
  State<RatioGameScreen> createState() => _RatioGameScreenState();
}

class _RatioGameScreenState extends State<RatioGameScreen> {
  final _rng = Random();
  static const _total = 12;
  late List<_RatioQ> _questions;
  int _index = 0;
  int _correct = 0;

  @override
  void initState() {
    super.initState();
    _questions = List.generate(_total, (_) => _generate());
  }

  _RatioQ _generate() {
    if (_rng.nextBool()) {
      final a = _rng.nextInt(8) + 2;
      final b = _rng.nextInt(8) + 2;
      final c = _rng.nextInt(8) + 2;
      final d = _rng.nextInt(8) + 2;
      final left = a / b;
      final right = c / d;
      return _RatioQ(
        'Hangisi daha büyük?',
        '$a/$b',
        '$c/$d',
        left >= right,
      );
    }
    final leftWeight = _rng.nextInt(9) + 3;
    final rightWeight = _rng.nextInt(9) + 3;
    return _RatioQ(
      'Terazi: hangi taraf daha ağır?',
      '$leftWeight kg',
      '$rightWeight kg',
      leftWeight >= rightWeight,
    );
  }

  Future<void> _answer(bool choseLeft) async {
    final q = _questions[_index];
    final ok = choseLeft == q.leftWins;
    if (ok) _correct++;
    AnswerFeedback.show(context, isCorrect: ok);
    if (_index + 1 >= _total) {
      final score = (_correct / _total) * 100;
      await context.read<GameStatsStore>().recordGameResult(
            category: LeaderboardCategory.overall,
            score: score,
            subtitle: 'Oran $_correct/$_total',
          );
      if (!mounted) return;
      await showSnappyModalSheet<void>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => GameResultSheet(
          title: context.trRead('ratio_done'),
          stats: [
            (context.trRead('correct'), '$_correct / $_total'),
            (context.trRead('score'), score.toStringAsFixed(0)),
          ],
          onRetry: () {
            Navigator.pop(ctx);
            setState(() {
              _questions = List.generate(_total, (_) => _generate());
              _index = 0;
              _correct = 0;
            });
          },
          onExit: () {
            Navigator.pop(ctx);
            context.pop();
          },
        ),
      );
    } else {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_index];
    return GameScaffold(
      title: context.tr('module_ratio'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Soru ${_index + 1} / $_total',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const Spacer(),
            Text(
              q.prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(child: _side(q.leftLabel, true)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('vs', style: TextStyle(color: AppColors.textMuted)),
                ),
                Expanded(child: _side(q.rightLabel, false)),
              ],
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _side(String label, bool isLeft) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _answer(isLeft),
        child: Container(
          height: 140,
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
