import 'package:flutter/material.dart';
import '../../../core/widgets/snappy_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/l10n_ext.dart';
import '../../../core/services/game_stats_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
import '../../games/presentation/game_widgets.dart';

class ProblemItem {
  const ProblemItem({
    required this.category,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.hint,
    required this.solution,
  });

  final String category;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String hint;
  final String solution;
}

const kProblems = [
  ProblemItem(
    category: 'Matematik',
    question: 'Bir ürün %20 indirimle 160 TL\'ye satılıyor. Orijinal fiyat nedir?',
    options: ['180 TL', '200 TL', '192 TL', '220 TL'],
    correctIndex: 1,
    hint: 'İndirim sonrası fiyat = orijinal × 0.80',
    solution: '160 = x × 0.8 ⇒ x = 160 / 0.8 = 200 TL',
  ),
  ProblemItem(
    category: 'Oran-Orantı',
    question: '3 işçi bir işi 12 günde bitiriyor. 6 işçi aynı işi kaç günde bitirir?',
    options: ['4', '6', '8', '9'],
    correctIndex: 1,
    hint: 'İşçi sayısı ile gün ters orantılıdır.',
    solution: '3 × 12 = 6 × g ⇒ g = 36 / 6 = 6 gün',
  ),
  ProblemItem(
    category: 'Sözel Mantık',
    question:
        'Tüm analistler hızlıdır. Bazı hızlılar dikkatlidir. Buna göre hangisi kesin doğrudur?',
    options: [
      'Tüm analistler dikkatlidir',
      'Bazı analistler dikkatli olabilir',
      'Hiçbir analist dikkatli değildir',
      'Tüm dikkatliler analisttir',
    ],
    correctIndex: 1,
    hint: 'Kesin sonuç ile olası sonucu ayır.',
    solution:
        'Analistler hızlıdır; hızlılar ile dikkatliler kısmen kesişebilir. Kesin olan: bazı analistlerin dikkatli olması mümkündür.',
  ),
  ProblemItem(
    category: 'Veri Yorumlama',
    question:
        'Bir ankette 200 kişinin %35\'i A seçeneğini işaretledi. A\'yı seçen kaç kişidir?',
    options: ['60', '65', '70', '75'],
    correctIndex: 2,
    hint: 'Yüzdeyi sayıya çevir: (yüzde/100) × toplam',
    solution: '200 × 0.35 = 70 kişi',
  ),
  ProblemItem(
    category: 'Matematik',
    question: '(15 × 8) − (36 ÷ 3) işleminin sonucu nedir?',
    options: ['108', '112', '96', '120'],
    correctIndex: 0,
    hint: 'Önce çarpma ve bölme, sonra çıkarma.',
    solution: '120 − 12 = 108',
  ),
];

class ProblemsScreen extends StatefulWidget {
  const ProblemsScreen({super.key});

  @override
  State<ProblemsScreen> createState() => _ProblemsScreenState();
}

class _ProblemsScreenState extends State<ProblemsScreen> {
  int _index = 0;
  int _correct = 0;
  int? _selected;
  bool _showHint = false;
  bool _showSolution = false;
  final _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
  }

  Future<void> _pick(int i) async {
    if (_selected != null) return;
    final p = kProblems[_index];
    setState(() {
      _selected = i;
      if (i == p.correctIndex) {
        _correct++;
        AppHaptics.success();
      } else {
        AppHaptics.error();
      }
    });
  }

  Future<void> _next() async {
    if (_index + 1 >= kProblems.length) {
      _stopwatch.stop();
      final seconds = _stopwatch.elapsed.inSeconds.clamp(1, 9999);
      final ratio = _correct / seconds;
      final score = ratio * 1000;
      await context.read<GameStatsStore>().recordGameResult(
            category: LeaderboardCategory.problems,
            score: score,
            subtitle: '$_correct/${kProblems.length} · ${seconds}s',
          );
      if (!mounted) return;
      await showSnappyModalSheet<void>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => GameResultSheet(
          title: context.trRead('problems_done'),
          stats: [
            (context.trRead('correct'), '$_correct / ${kProblems.length}'),
            (context.trRead('time_left'), '${seconds}s'),
            (context.trRead('score'), ratio.toStringAsFixed(3)),
          ],
          onRetry: () {
            Navigator.pop(ctx);
            setState(() {
              _index = 0;
              _correct = 0;
              _selected = null;
              _showHint = false;
              _showSolution = false;
              _stopwatch
                ..reset()
                ..start();
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
        _showHint = false;
        _showSolution = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = kProblems[_index];
    return GameScaffold(
      title: context.tr('module_problems'),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Chip(
                label: Text(p.category),
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                labelStyle: const TextStyle(color: AppColors.primary),
                side: BorderSide.none,
              ),
              const Spacer(),
              Text(
                '${_index + 1} / ${kProblems.length}',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Text(
              p.question,
              style: const TextStyle(fontSize: 17, height: 1.4, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(p.options.length, (i) {
            Color? border;
            if (_selected != null) {
              if (i == p.correctIndex) {
                border = AppColors.mint;
              } else if (i == _selected) {
                border = AppColors.accentRed;
              }
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                borderColor: border,
                onTap: () => _pick(i),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Text(p.options[i]),
              ),
            );
          }),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  AppHaptics.selection();
                  setState(() => _showHint = !_showHint);
                },
                icon: const Icon(Icons.lightbulb_outline, color: AppColors.amber),
                label: Text(context.tr('hint'), style: TextStyle(color: AppColors.amber)),
              ),
              TextButton.icon(
                onPressed: _selected == null
                    ? null
                    : () {
                        AppHaptics.selection();
                        setState(() => _showSolution = !_showSolution);
                      },
                icon: const Icon(Icons.menu_book_outlined, color: AppColors.primary),
                label: Text(context.tr('solution'), style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
          if (_showHint)
            AppCard(
              color: AppColors.amber.withValues(alpha: 0.1),
              child: Text(p.hint, style: const TextStyle(color: AppColors.amber)),
            ),
          if (_showSolution) ...[
            const SizedBox(height: 8),
            AppCard(
              color: AppColors.primary.withValues(alpha: 0.1),
              child: Text(p.solution, style: const TextStyle(color: AppColors.primary)),
            ),
          ],
          const SizedBox(height: 16),
          if (_selected != null)
            ElevatedButton(
              onPressed: _next,
              child: Text(
                _index + 1 >= kProblems.length
                    ? context.tr('finish')
                    : context.tr('next'),
              ),
            ),
        ],
      ),
    );
  }
}
