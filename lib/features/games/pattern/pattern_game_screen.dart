import 'dart:math';

import 'package:flutter/material.dart';
import '../../../core/widgets/snappy_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/l10n_ext.dart';
import '../../../core/services/game_stats_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import '../presentation/game_widgets.dart';

enum _PatternKind { number, letter }

class PatternPuzzle {
  PatternPuzzle({
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
}

class PatternGameScreen extends StatefulWidget {
  const PatternGameScreen({super.key});

  @override
  State<PatternGameScreen> createState() => _PatternGameScreenState();
}

class _PatternGameScreenState extends State<PatternGameScreen> {
  final _rng = Random();
  late List<PatternPuzzle> _puzzles;
  int _index = 0;
  int _correct = 0;
  int? _selected;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _puzzles = List.generate(AppConstants.patternRounds, (_) => _generate());
  }

  PatternPuzzle _generate() {
    final kind = _rng.nextBool() ? _PatternKind.number : _PatternKind.letter;
    if (kind == _PatternKind.number) {
      final start = _rng.nextInt(12) + 1;
      final step = _rng.nextInt(5) + 2;
      final seq = List.generate(5, (i) => start + i * step);
      final answer = seq.removeAt(seq.length - 1);
      final options = <int>{answer};
      while (options.length < 4) {
        options.add(answer + _rng.nextInt(9) - 4);
      }
      final list = options.map((e) => e.toString()).toList()..shuffle(_rng);
      return PatternPuzzle(
        prompt: '${seq.join(', ')}, ?',
        options: list,
        correctIndex: list.indexOf(answer.toString()),
      );
    }

    final start = _rng.nextInt(20);
    final step = _rng.nextInt(3) + 1;
    final codes = List.generate(5, (i) => start + i * step);
    final letters = codes.map((c) => String.fromCharCode(65 + (c % 26))).toList();
    final answer = letters.removeLast();
    final options = <String>{answer};
    while (options.length < 4) {
      options.add(String.fromCharCode(65 + _rng.nextInt(26)));
    }
    final list = options.toList()..shuffle(_rng);
    return PatternPuzzle(
      prompt: '${letters.join(', ')}, ?',
      options: list,
      correctIndex: list.indexOf(answer),
    );
  }

  Future<void> _pick(int i) async {
    if (_revealed) return;
    setState(() {
      _selected = i;
      _revealed = true;
      if (i == _puzzles[_index].correctIndex) {
        _correct++;
        AppHaptics.success();
      } else {
        AppHaptics.error();
      }
    });
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    if (_index + 1 >= _puzzles.length) {
      final score = (_correct / _puzzles.length) * 100;
      await context.read<GameStatsStore>().recordGameResult(
            category: LeaderboardCategory.overall,
            score: score,
            subtitle: 'Örüntü $_correct/${_puzzles.length}',
          );
      if (!mounted) return;
      await showSnappyModalSheet<void>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => GameResultSheet(
          title: context.trRead('pattern_done'),
          stats: [
            (context.trRead('correct'), '$_correct / ${_puzzles.length}'),
            (context.trRead('score'), score.toStringAsFixed(0)),
          ],
          onRetry: () {
            Navigator.pop(ctx);
            setState(() {
              _puzzles =
                  List.generate(AppConstants.patternRounds, (_) => _generate());
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
    } else {
      setState(() {
        _index++;
        _selected = null;
        _revealed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = _puzzles[_index];
    return GameScaffold(
      title: context.tr('module_pattern'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              context.tr('question_of', {
                'current': '${_index + 1}',
                'total': '${_puzzles.length}',
              }),
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                puzzle.prompt,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('pick_missing'),
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const Spacer(),
            ...List.generate(puzzle.options.length, (i) {
              Color? border;
              if (_revealed) {
                if (i == puzzle.correctIndex) {
                  border = AppColors.mint;
                } else if (i == _selected) {
                  border = AppColors.accentRed;
                }
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _pick(i),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: border != null
                            ? Border.all(color: border, width: 2)
                            : null,
                      ),
                      child: Text(
                        puzzle.options[i],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
