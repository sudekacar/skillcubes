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

class FunnelPuzzle {
  FunnelPuzzle({
    required this.inputs,
    required this.rule,
    required this.options,
    required this.correctIndex,
  });

  final List<String> inputs;
  final String rule;
  final List<String> options;
  final int correctIndex;
}

class FunnelGameScreen extends StatefulWidget {
  const FunnelGameScreen({super.key});

  @override
  State<FunnelGameScreen> createState() => _FunnelGameScreenState();
}

class _FunnelGameScreenState extends State<FunnelGameScreen> {
  final _rng = Random();
  late List<FunnelPuzzle> _puzzles;
  int _index = 0;
  int _correct = 0;
  int? _selected;
  bool _revealed = false;

  static const _shapes = ['▲', '■', '●', '◆', '★', '✚'];

  @override
  void initState() {
    super.initState();
    _puzzles = List.generate(AppConstants.funnelRounds, (_) => _generate());
  }

  FunnelPuzzle _generate() {
    final n = 4;
    final inputs = List.generate(n, (_) => _shapes[_rng.nextInt(_shapes.length)]);
    // Rule like "1-3-2-4" means permute positions
    final order = List.generate(n, (i) => i)..shuffle(_rng);
    final rule = order.map((i) => i + 1).join('-');
    final output = order.map((i) => inputs[i]).join();
    final options = <String>{output};
    while (options.length < 4) {
      final decoy = List.of(inputs)..shuffle(_rng);
      options.add(decoy.join());
    }
    final optionList = options.toList()..shuffle(_rng);
    return FunnelPuzzle(
      inputs: inputs,
      rule: rule,
      options: optionList,
      correctIndex: optionList.indexOf(output),
    );
  }

  Future<void> _pick(int i) async {
    if (_revealed) return;
    final isCorrect = i == _puzzles[_index].correctIndex;
    setState(() {
      _selected = i;
      _revealed = true;
      if (isCorrect) _correct++;
    });
    AnswerFeedback.show(context, isCorrect: isCorrect);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    if (_index + 1 >= _puzzles.length) {
      await _finish();
    } else {
      setState(() {
        _index++;
        _selected = null;
        _revealed = false;
      });
    }
  }

  Future<void> _finish() async {
    final score = (_correct / _puzzles.length) * 100;
    await context.read<GameStatsStore>().recordGameResult(
          category: LeaderboardCategory.overall,
          score: score,
          subtitle: 'Funnel $_correct/${_puzzles.length}',
          badge: score >= 80 ? 'Mantık Ustası' : null,
        );
    if (!mounted) return;
    await showSnappyModalSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => GameResultSheet(
        title: context.trRead('funnel_done'),
        stats: [
          (context.trRead('correct'), '$_correct / ${_puzzles.length}'),
          (context.trRead('score'), score.toStringAsFixed(0)),
        ],
        onRetry: () {
          Navigator.pop(ctx);
          setState(() {
            _puzzles = List.generate(AppConstants.funnelRounds, (_) => _generate());
            _index = 0;
            _correct = 0;
            _selected = null;
            _revealed = false;
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
    final puzzle = _puzzles[_index];
    return GameScaffold(
      title: context.tr('module_funnel'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_index + 1) / _puzzles.length,
              backgroundColor: AppColors.surface,
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('question_of', {
                'current': '${_index + 1}',
                'total': '${_puzzles.length}',
              }),
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 28),
            Text(
              context.tr('input_symbols'),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: puzzle.inputs
                  .map(
                    (s) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(s, style: const TextStyle(fontSize: 26)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Text(context.tr('transform_rule'), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    puzzle.rule,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              context.tr('output_options'),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: puzzle.options.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemBuilder: (context, i) {
                  Color? border;
                  if (_revealed) {
                    if (i == puzzle.correctIndex) {
                      border = AppColors.mint;
                    } else if (i == _selected) {
                      border = AppColors.accentRed;
                    }
                  }
                  return Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _pick(i),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: border != null
                              ? Border.all(color: border, width: 2)
                              : null,
                        ),
                        child: Text(
                          puzzle.options[i],
                          style: const TextStyle(fontSize: 22, letterSpacing: 4),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
