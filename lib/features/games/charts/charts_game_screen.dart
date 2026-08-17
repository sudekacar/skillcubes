import 'dart:math';

import 'package:flutter/material.dart';
import '../../../core/widgets/snappy_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/l10n_ext.dart';
import '../../../core/services/game_stats_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import '../presentation/game_widgets.dart';

class _ChartQ {
  _ChartQ({
    required this.values,
    required this.labels,
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  final List<double> values;
  final List<String> labels;
  final String question;
  final List<String> options;
  final int correctIndex;
}

class ChartsGameScreen extends StatefulWidget {
  const ChartsGameScreen({super.key});

  @override
  State<ChartsGameScreen> createState() => _ChartsGameScreenState();
}

class _ChartsGameScreenState extends State<ChartsGameScreen> {
  final _rng = Random();
  static const _total = 8;
  late List<_ChartQ> _questions;
  int _index = 0;
  int _correct = 0;
  int? _selected;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _questions = List.generate(_total, (_) => _generate());
  }

  _ChartQ _generate() {
    final labels = ['A', 'B', 'C', 'D'];
    final values = List.generate(4, (_) => (_rng.nextInt(8) + 2).toDouble());
    final maxIdx = values.indexOf(values.reduce(max));
    final sum = values.reduce((a, b) => a + b);
    final askMax = _rng.nextBool();
    if (askMax) {
      final options = List.of(labels)..shuffle(_rng);
      return _ChartQ(
        values: values,
        labels: labels,
        question: 'En yüksek çubuk hangisi?',
        options: options,
        correctIndex: options.indexOf(labels[maxIdx]),
      );
    }
    final target = labels[_rng.nextInt(4)];
    final idx = labels.indexOf(target);
    final pct = ((values[idx] / sum) * 100).round();
    final options = <String>{'$pct%'};
    while (options.length < 4) {
      options.add('${(pct + _rng.nextInt(21) - 10).clamp(5, 95)}%');
    }
    final list = options.toList()..shuffle(_rng);
    return _ChartQ(
      values: values,
      labels: labels,
      question: '$target yaklaşık yüzde kaç?',
      options: list,
      correctIndex: list.indexOf('$pct%'),
    );
  }

  Future<void> _pick(int i) async {
    if (_revealed) return;
    setState(() {
      _selected = i;
      _revealed = true;
      if (i == _questions[_index].correctIndex) {
        _correct++;
        AppHaptics.success();
      } else {
        AppHaptics.error();
      }
    });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    if (_index + 1 >= _total) {
      final score = (_correct / _total) * 100;
      await context.read<GameStatsStore>().recordGameResult(
            category: LeaderboardCategory.overall,
            score: score,
            subtitle: 'Grafik $_correct/$_total',
          );
      if (!mounted) return;
      await showSnappyModalSheet<void>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => GameResultSheet(
          title: context.trRead('charts_done'),
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
    final q = _questions[_index];
    final maxV = q.values.reduce(max);
    return GameScaffold(
      title: context.tr('module_charts'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Soru ${_index + 1} / $_total',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(q.values.length, (i) {
                    final h = (q.values[i] / maxV) * 160;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              q.values[i].toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                              height: h,
                              decoration: BoxDecoration(
                                color: [
                                  AppColors.primary,
                                  AppColors.amber,
                                  AppColors.mint,
                                  AppColors.accentRed,
                                ][i],
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              q.labels[i],
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              q.question,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...List.generate(q.options.length, (i) {
              Color? border;
              if (_revealed) {
                if (i == q.correctIndex) {
                  border = AppColors.mint;
                } else if (i == _selected) {
                  border = AppColors.accentRed;
                }
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _pick(i),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: border != null
                            ? Border.all(color: border, width: 2)
                            : null,
                      ),
                      child: Text(
                        q.options[i],
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
