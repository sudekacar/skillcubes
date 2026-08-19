import 'dart:math';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../domain/quiz_category.dart';
import '../domain/quiz_question.dart';

/// Supplies exactly [AppConstants.questionsPerCategory] questions per category.
///
/// Prefers FastAPI `GET /questions?category_id=` when authenticated;
/// falls back to a local generated pool when offline / guest.
class QuestionRepository {
  QuestionRepository({ApiService? this._api, Random? random})
      : _rng = random ?? Random();

  final ApiService? _api;
  final Random _rng;

  static const _shapes = ['▲', '■', '●', '◆', '★', '✚'];

  /// Load questions from the backend for [remoteCategoryId].
  ///
  /// Does **not** pad short (freemium teaser) packs up to 20 — that would
  /// bypass the premium gate. Full packs are still capped at 20.
  Future<List<QuizQuestion>> questionsForRemote(int remoteCategoryId) async {
    final api = _api;
    if (api == null || !api.isAuthenticated) {
      throw ApiException(401, 'Not authenticated');
    }

    final list = await api.getJsonList(
      '/questions',
      query: {'category_id': '$remoteCategoryId'},
    );

    final questions = list.map((e) {
      final json = Map<String, dynamic>.from(e as Map);
      final options = (json['options'] as List<dynamic>? ?? const [])
          .map((o) {
            if (o == null) return '';
            if (o is String) return o.trim();
            if (o is num) return o.toString();
            return o.toString().trim();
          })
          .where((s) => s.isNotEmpty)
          .toList();
      return QuizQuestion(
        id: '${json['id']}',
        categoryId: '$remoteCategoryId',
        prompt: json['question_text'] as String,
        options: options,
        correctIndex: json['correct_option_index'] as int,
        hint: json['explanation'] as String?,
      );
    }).toList();

    final full = AppConstants.questionsPerCategory;
    if (questions.length >= full) {
      questions.shuffle(_rng);
      return questions.take(full).toList(growable: false);
    }

    // Teaser / partial pack — keep API order, no stub padding.
    return List<QuizQuestion>.unmodifiable(questions);
  }

  /// Persist quiz progress to `POST /user/progress`.
  Future<void> syncProgress({
    required int categoryId,
    required int completedQuestions,
    required int score,
  }) async {
    final api = _api;
    if (api == null || !api.isAuthenticated) return;
    await api.postJson(
      '/user/progress',
      {
        'category_id': categoryId,
        'completed_questions': completedQuestions,
        'score': score,
      },
      auth: true,
    );
  }

  /// Returns a shuffled set of exactly 20 questions for [categoryId] (local).
  List<QuizQuestion> questionsFor(QuizCategoryId categoryId) {
    final pool = _poolFor(categoryId);
    final needed = AppConstants.questionsPerCategory;

    final items = <QuizQuestion>[...pool];
    var stubIndex = 0;
    while (items.length < needed) {
      items.add(_stub(categoryId, stubIndex++));
    }

    items.shuffle(_rng);
    return items.take(needed).toList(growable: false);
  }

  List<QuizQuestion> _poolFor(QuizCategoryId id) {
    switch (id) {
      case QuizCategoryId.funnel:
        return List.generate(12, _funnel);
      case QuizCategoryId.pattern:
        return List.generate(14, _pattern);
      case QuizCategoryId.quickMath:
        return List.generate(16, _quickMath);
      case QuizCategoryId.ratio:
        return List.generate(12, _ratio);
      case QuizCategoryId.charts:
        return List.generate(10, _charts);
      case QuizCategoryId.goNoGo:
        return List.generate(12, _goNoGo);
      case QuizCategoryId.logicalReasoning:
        return _logicalPool();
      case QuizCategoryId.english:
        return _englishPool();
    }
  }

  QuizQuestion _funnel(int i) {
    final inputs = List.generate(4, (_) => _shapes[_rng.nextInt(_shapes.length)]);
    final order = List.generate(4, (j) => j)..shuffle(_rng);
    final rule = order.map((e) => e + 1).join('-');
    final correct = order.map((e) => inputs[e]).join();
    final options = <String>{correct};
    while (options.length < 4) {
      final decoy = List.of(inputs)..shuffle(_rng);
      options.add(decoy.join());
    }
    final list = options.toList()..shuffle(_rng);
    return QuizQuestion(
      id: 'funnel_$i',
      categoryId: QuizCategoryId.funnel.name,
      prompt: 'Girdi: ${inputs.join(' ')}\nKural: $rule\nDoğru çıktı hangisi?',
      options: list,
      correctIndex: list.indexOf(correct),
      hint: 'Kural pozisyon sırasını gösterir (1-3-2-4 gibi).',
    );
  }

  QuizQuestion _pattern(int i) {
    final start = _rng.nextInt(12) + 1;
    final step = _rng.nextInt(5) + 2;
    final seq = List.generate(4, (j) => start + j * step);
    final answer = start + 4 * step;
    final options = <int>{answer};
    while (options.length < 4) {
      options.add(answer + _rng.nextInt(11) - 5);
    }
    final list = options.map((e) => '$e').toList()..shuffle(_rng);
    return QuizQuestion(
      id: 'pattern_$i',
      categoryId: QuizCategoryId.pattern.name,
      prompt: '${seq.join(', ')}, ?',
      options: list,
      correctIndex: list.indexOf('$answer'),
      hint: 'Ortak farkı (aritmetik dizi) bul.',
    );
  }

  QuizQuestion _quickMath(int i) {
    final a = _rng.nextInt(20) + 5;
    final b = _rng.nextInt(20) + 5;
    final c = _rng.nextInt(12) + 2;
    late final int answer;
    late final String prompt;
    switch (i % 3) {
      case 0:
        answer = a + b - c;
        prompt = '$a + $b − $c = ?';
      case 1:
        answer = a * b;
        prompt = '$a × $b = ?';
      default:
        final product = a * b * c;
        final missing = _rng.nextInt(30) + 10;
        answer = missing;
        prompt = '($a × $b × $c) − ? = ${product - missing}';
    }
    final options = <int>{answer};
    while (options.length < 4) {
      options.add(answer + _rng.nextInt(17) - 8);
    }
    final list = options.map((e) => '$e').toList()..shuffle(_rng);
    return QuizQuestion(
      id: 'math_$i',
      categoryId: QuizCategoryId.quickMath.name,
      prompt: prompt,
      options: list,
      correctIndex: list.indexOf('$answer'),
    );
  }

  QuizQuestion _ratio(int i) {
    final a = _rng.nextInt(8) + 2;
    final b = _rng.nextInt(8) + 2;
    final c = _rng.nextInt(8) + 2;
    final d = _rng.nextInt(8) + 2;
    final left = a / b;
    final right = c / d;
    final leftWins = left >= right;
    final correct = leftWins ? '$a/$b' : '$c/$d';
    final options = ['$a/$b', '$c/$d', '${a + 1}/$b', '$a/${b + 1}']
      ..shuffle(_rng);
    // Ensure correct is present
    if (!options.contains(correct)) {
      options[0] = correct;
    }
    return QuizQuestion(
      id: 'ratio_$i',
      categoryId: QuizCategoryId.ratio.name,
      prompt: 'Hangisi daha büyük?\n$a/$b  vs  $c/$d',
      options: options,
      correctIndex: options.indexOf(correct),
      hint: 'Kesirleri ondalığa çevir veya çapraz çarp.',
    );
  }

  QuizQuestion _charts(int i) {
    final values = List.generate(4, (_) => _rng.nextInt(8) + 2);
    final labels = ['A', 'B', 'C', 'D'];
    final maxIdx = values.indexOf(values.reduce(max));
    final correct = labels[maxIdx];
    final options = List.of(labels)..shuffle(_rng);
    return QuizQuestion(
      id: 'charts_$i',
      categoryId: QuizCategoryId.charts.name,
      prompt:
          'Çubuk değerleri: ${List.generate(4, (j) => '${labels[j]}=${values[j]}').join(', ')}\nEn yüksek hangisi?',
      options: options,
      correctIndex: options.indexOf(correct),
    );
  }

  QuizQuestion _goNoGo(int i) {
    const prompts = [
      (
        'Kural: Yeşil/Mavi/Sarıya dokun, Kırmızıya dokunma. Kırmızı yanınca ne yapmalısın?',
        ['Dokunma', 'Hemen dokun', 'Çift dokun', 'Uzun bas'],
        0,
      ),
      (
        'Stroop: Kelime "Mavi" ama renk kırmızı. Karar neye göre verilir?',
        ['Renk', 'Kelime', 'Ses', 'Boyut'],
        0,
      ),
      (
        'Go uyarısı (yeşil) geldiğinde doğru tepki nedir?',
        ['Hızlı dokunuş', 'Bekle', 'Kaydır', 'Hiçbir şey'],
        0,
      ),
      (
        'Yanlış alarm (false alarm) ne demektir?',
        [
          'No-Go\'ya dokunmak',
          'Go\'yu kaçırmak',
          'Doğru dokunuş',
          'Zaman aşımı yok',
        ],
        0,
      ),
    ];
    final p = prompts[i % prompts.length];
    final options = List.of(p.$2)..shuffle(_rng);
    final correct = p.$2[p.$3];
    return QuizQuestion(
      id: 'gonogo_$i',
      categoryId: QuizCategoryId.goNoGo.name,
      prompt: p.$1,
      options: options,
      correctIndex: options.indexOf(correct),
    );
  }

  List<QuizQuestion> _logicalPool() {
    const bank = <(String, List<String>, int)>[
      (
        'Tüm analistler hızlıdır. Bazı hızlılar dikkatlidir. Hangisi kesin doğrudur?',
        [
          'Bazı analistler dikkatli olabilir',
          'Tüm analistler dikkatlidir',
          'Hiçbir analist dikkatli değildir',
          'Tüm dikkatliler analisttir',
        ],
        0,
      ),
      (
        'A, B\'den uzun; B, C\'den uzun. Hangisi kesin?',
        ['A, C\'den uzundur', 'C, A\'dan uzundur', 'A = C', 'B en uzundur'],
        0,
      ),
      (
        'Her pazartesi toplantı olur. Bugün pazartesi. Sonuç?',
        ['Toplantı vardır', 'Toplantı yoktur', 'Belirsiz', 'İptal'],
        0,
      ),
      (
        'Hiçbir kedi köpek değildir. Bazı hayvanlar kedidir. Hangisi doğru?',
        [
          'Bazı hayvanlar köpek değildir',
          'Tüm hayvanlar kedidir',
          'Tüm kediler köpektir',
          'Hiçbir hayvan kedi değildir',
        ],
        0,
      ),
      (
        'Eğer yağmur yağarsa maç iptal. Maç oynandı. Sonuç?',
        ['Yağmur yağmamıştır', 'Yağmur yağmıştır', 'Belirsiz', 'İptal olmuş'],
        0,
      ),
      (
        '3, 6, 12, 24, ? dizisinde sonraki sayı?',
        ['48', '36', '30', '42'],
        0,
      ),
      (
        'Kitap : Okumak :: Çatal : ?',
        ['Yemek', 'Yazmak', 'Koşmak', 'Çizmek'],
        0,
      ),
      (
        'Hangi sayı diğerlerinden farklıdır: 2, 3, 5, 7, 9, 11?',
        ['9', '2', '11', '7'],
        0,
      ),
    ];

    return [
      for (var i = 0; i < bank.length; i++)
        () {
          final source = bank[i];
          final opts = List.of(source.$2)..shuffle(_rng);
          return QuizQuestion(
            id: 'logic_$i',
            categoryId: QuizCategoryId.logicalReasoning.name,
            prompt: source.$1,
            options: opts,
            correctIndex: opts.indexOf(source.$2[source.$3]),
            hint: 'Kesin sonuç ile olası sonucu ayır.',
          );
        }(),
    ];
  }

  List<QuizQuestion> _englishPool() {
    const bank = [
      (
        'Choose the synonym of "rapid":',
        ['fast', 'slow', 'late', 'weak'],
        0,
      ),
      (
        'Fill in: She ___ to work every day.',
        ['goes', 'go', 'going', 'gone'],
        0,
      ),
      (
        'Opposite of "increase":',
        ['decrease', 'expand', 'raise', 'grow'],
        0,
      ),
      (
        'Which sentence is correct?',
        [
          'He has finished the test.',
          'He have finished the test.',
          'He finishing the test.',
          'He finish the test yesterday.',
        ],
        0,
      ),
      (
        'Meaning of "deadline":',
        [
          'A time by which something must be done',
          'A starting point',
          'A holiday',
          'A meeting room',
        ],
        0,
      ),
      (
        'Pick the correct preposition: interested ___ music.',
        ['in', 'on', 'at', 'for'],
        0,
      ),
      (
        '"Candidate" most nearly means:',
        ['applicant', 'manager', 'building', 'schedule'],
        0,
      ),
      (
        'Past tense of "write":',
        ['wrote', 'writed', 'written', 'writing'],
        0,
      ),
    ];

    return [
      for (var i = 0; i < bank.length; i++)
        () {
          final source = bank[i];
          final opts = List.of(source.$2)..shuffle(_rng);
          return QuizQuestion(
            id: 'en_$i',
            categoryId: QuizCategoryId.english.name,
            prompt: source.$1,
            options: opts,
            correctIndex: opts.indexOf(source.$2[source.$3]),
          );
        }(),
    ];
  }

  QuizQuestion _stub(QuizCategoryId categoryId, int index) {
    final n = index + 1;
    final answer = n * 2;
    final options = <int>{answer};
    while (options.length < 4) {
      options.add(answer + _rng.nextInt(9) - 4);
    }
    final list = options.map((e) => '$e').toList()..shuffle(_rng);
    return QuizQuestion(
      id: '${categoryId.name}_stub_$index',
      categoryId: categoryId.name,
      prompt: 'Alıştırma $n: $n + $n = ?',
      options: list,
      correctIndex: list.indexOf('$answer'),
      hint: 'Stub soru — havuzu 20\'ye tamamlar.',
    );
  }
}
