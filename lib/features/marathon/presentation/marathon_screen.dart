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
import '../../../core/utils/haptics.dart';
import '../../games/presentation/game_widgets.dart';
import '../../problems/presentation/problems_screen.dart';

class _MarathonItem {
  _MarathonItem(this.question, this.options, this.correctIndex, this.tag);

  final String question;
  final List<String> options;
  final int correctIndex;
  final String tag;
}

class MarathonScreen extends StatefulWidget {
  const MarathonScreen({super.key});

  @override
  State<MarathonScreen> createState() => _MarathonScreenState();
}

class _MarathonScreenState extends State<MarathonScreen> {
  final _rng = Random();
  late List<_MarathonItem> _items;
  int _index = 0;
  int _correct = 0;
  int _secondsLeft = AppConstants.marathonMinutes * 60;
  Timer? _timer;
  bool _started = false;
  bool _finished = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<_MarathonItem> _buildBank() {
    final bank = <_MarathonItem>[];
    for (final p in kProblems) {
      bank.add(_MarathonItem(p.question, p.options, p.correctIndex, p.category));
    }
    for (var i = 0; i < 12; i++) {
      final a = _rng.nextInt(20) + 5;
      final b = _rng.nextInt(20) + 5;
      final ans = a + b;
      final opts = <int>{ans};
      while (opts.length < 4) {
        opts.add(ans + _rng.nextInt(11) - 5);
      }
      final list = opts.map((e) => e.toString()).toList()..shuffle(_rng);
      bank.add(
        _MarathonItem(
          '$a + $b = ?',
          list,
          list.indexOf(ans.toString()),
          'Hızlı Matematik',
        ),
      );
    }
    for (var i = 0; i < 8; i++) {
      final start = _rng.nextInt(10) + 1;
      final step = _rng.nextInt(4) + 2;
      final seq = List.generate(4, (j) => start + j * step);
      final ans = start + 4 * step;
      final opts = <int>{ans};
      while (opts.length < 4) {
        opts.add(ans + _rng.nextInt(9) - 4);
      }
      final list = opts.map((e) => '$e').toList()..shuffle(_rng);
      bank.add(
        _MarathonItem(
          '${seq.join(', ')}, ?',
          list,
          list.indexOf('$ans'),
          'Örüntü',
        ),
      );
    }
    bank.shuffle(_rng);
    return bank.take(AppConstants.marathonQuestionCount).toList();
  }

  void _start() {
    _items = _buildBank();
    setState(() {
      _started = true;
      _index = 0;
      _correct = 0;
      _secondsLeft = AppConstants.marathonMinutes * 60;
      _finished = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        _end();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _pick(int i) async {
    if (_finished) return;
    final item = _items[_index];
    final isCorrect = i == item.correctIndex;
    if (isCorrect) {
      _correct++;
    }
    AnswerFeedback.show(context, isCorrect: isCorrect);
    if (_index + 1 >= _items.length) {
      await _end();
    } else {
      setState(() => _index++);
    }
  }

  Future<void> _end() async {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    final score = _correct * 50.0 + _secondsLeft;
    await context.read<GameStatsStore>().recordGameResult(
          category: LeaderboardCategory.overall,
          score: score,
          subtitle: 'Maraton $_correct/${_items.length}',
          badge: _correct >= 15 ? 'Maraton Şampiyonu' : null,
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
        title: context.trRead('marathon_done'),
        stats: [
          (context.trRead('correct'), '$_correct / ${_items.length}'),
          (context.trRead('time_left'), _format(_secondsLeft)),
          (context.trRead('score'), score.toStringAsFixed(0)),
        ],
        onRetry: () {
          Navigator.pop(ctx);
          _start();
        },
        onExit: () {
          Navigator.pop(ctx);
          context.pop();
        },
      ),
    );
  }

  String _format(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return GameScaffold(
        title: context.tr('module_marathon'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.timer, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                context.tr('marathon_meta', {
                  'minutes': '${AppConstants.marathonMinutes}',
                  'count': '${AppConstants.marathonQuestionCount}',
                }),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('marathon_intro'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    AppHaptics.medium();
                    _start();
                  },
                  child: Text(context.tr('start_simulation')),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    }

    final item = _items[_index];
    return GameScaffold(
      title: context.tr('module_marathon'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_index + 1) / _items.length,
                    backgroundColor: AppColors.surface,
                    color: AppColors.primary,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _format(_secondsLeft),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _secondsLeft < 60
                        ? AppColors.accentRed
                        : AppColors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.tag,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.35),
            ),
            const SizedBox(height: 24),
            ...List.generate(item.options.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _pick(i),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(item.options[i]),
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
