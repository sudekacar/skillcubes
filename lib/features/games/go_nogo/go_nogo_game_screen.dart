import 'dart:async';
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

class GoNoGoGameScreen extends StatefulWidget {
  const GoNoGoGameScreen({super.key});

  @override
  State<GoNoGoGameScreen> createState() => _GoNoGoGameScreenState();
}

class _GoNoGoGameScreenState extends State<GoNoGoGameScreen> {
  final _rng = Random();
  static const _goColors = {
    'Yeşil': AppColors.mint,
    'Mavi': AppColors.primary,
    'Sarı': AppColors.amber,
  };
  static const _noGo = MapEntry('Kırmızı', AppColors.accentRed);

  int _round = 0;
  int _hits = 0;
  int _falseAlarms = 0;
  int _misses = 0;
  final List<int> _reactionTimes = [];
  String? _label;
  Color? _color;
  bool _stroop = false;
  bool _waitingTap = false;
  bool _isNoGo = false;
  DateTime? _shownAt;
  Timer? _roundTimer;
  bool _finished = false;
  bool _started = false;

  @override
  void dispose() {
    _roundTimer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _started = true;
      _round = 0;
      _hits = 0;
      _falseAlarms = 0;
      _misses = 0;
      _reactionTimes.clear();
      _finished = false;
    });
    _nextStimulus();
  }

  void _nextStimulus() {
    _roundTimer?.cancel();
    if (_round >= AppConstants.goNoGoRounds) {
      _finish();
      return;
    }
    setState(() {
      _round++;
      _stroop = _rng.nextBool();
      _isNoGo = _rng.nextDouble() < 0.28;
      if (_isNoGo) {
        _label = _noGo.key;
        _color = _noGo.value;
      } else {
        final keys = _goColors.keys.toList();
        final name = keys[_rng.nextInt(keys.length)];
        _label = name;
        if (_stroop) {
          // mismatch word vs color
          final other = keys.where((k) => k != name).toList();
          _color = _goColors[other[_rng.nextInt(other.length)]];
        } else {
          _color = _goColors[name];
        }
      }
      _waitingTap = true;
      _shownAt = DateTime.now();
    });

    _roundTimer = Timer(Duration(milliseconds: 900 + _rng.nextInt(500)), () {
      if (!_waitingTap || _finished) return;
      // missed a Go
      if (!_isNoGo) {
        setState(() {
          _misses++;
          _waitingTap = false;
          _label = null;
        });
        AppHaptics.error();
      } else {
        setState(() {
          _waitingTap = false;
          _label = null;
        });
      }
      Future.delayed(const Duration(milliseconds: 350), _nextStimulus);
    });
  }

  void _onTap() {
    if (!_waitingTap || _finished) return;
    final ms = DateTime.now().difference(_shownAt!).inMilliseconds;
    setState(() => _waitingTap = false);
    _roundTimer?.cancel();

    if (_isNoGo) {
      _falseAlarms++;
      AppHaptics.error();
    } else {
      _hits++;
      _reactionTimes.add(ms);
      AppHaptics.success();
    }
    setState(() => _label = null);
    Future.delayed(const Duration(milliseconds: 280), _nextStimulus);
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    _roundTimer?.cancel();
    final totalRelevant = _hits + _misses + _falseAlarms;
    final errorRate =
        totalRelevant == 0 ? 0.0 : (_falseAlarms + _misses) / totalRelevant;
    final avgMs = _reactionTimes.isEmpty
        ? 999
        : (_reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length)
            .round();
    // Higher is better: accuracy emphasis + fast reactions
    final score = ((1 - errorRate) * 1000) - avgMs;

    await context.read<GameStatsStore>().recordGameResult(
          category: LeaderboardCategory.goNoGo,
          score: score,
          subtitle:
              'Hata ${(errorRate * 100).toStringAsFixed(0)}% · $avgMs ms',
          badge: errorRate < 0.15 ? 'Reflex King' : null,
        );
    if (!mounted) return;
    await showSnappyModalSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => GameResultSheet(
        title: context.trRead('gonogo_done'),
        stats: [
          (context.trRead('hits'), '$_hits'),
          (context.trRead('false_alarms'), '$_falseAlarms'),
          (context.trRead('misses'), '$_misses'),
          (context.trRead('avg_reaction'), '$avgMs ms'),
          (context.trRead('error_rate'), '${(errorRate * 100).toStringAsFixed(0)}%'),
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

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: context.tr('module_gonogo'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: !_started
            ? Column(
                children: [
                  const Spacer(),
                  const Icon(Icons.touch_app, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('gonogo_rules'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('gonogo_stroop'),
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
                      child: Text(context.tr('start')),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              )
            : Column(
                children: [
                  Text(
                    'Tur $_round / ${AppConstants.goNoGoRounds}',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _onTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 220,
                      height: 220,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _color ?? AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: _color != null
                            ? [
                                BoxShadow(
                                  color: (_color ?? AppColors.primary)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        _label ?? '',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _stat('İsabet', '$_hits', AppColors.mint),
                      _stat('Hata+', '$_falseAlarms', AppColors.accentRed),
                      _stat('Kaçırma', '$_misses', AppColors.amber),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            )),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }
}
