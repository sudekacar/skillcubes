import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../data/question_repository.dart';
import '../domain/quiz_category.dart';
import '../domain/quiz_question.dart';

/// Manages a single quiz session for one category.
class QuizController extends ChangeNotifier {
  QuizController({
    required this.remoteCategoryId,
    this.localFallback,
    this.title = '',
    this.categorySlug = '',
    this.isLocked = false,
    QuestionRepository? repository,
  }) : _repository = repository ?? QuestionRepository();

  /// Backend category primary key (`GET /questions?category_id=`).
  final int remoteCategoryId;

  /// Used only when the API is unavailable (guest / offline).
  final QuizCategoryId? localFallback;

  final String title;
  final String categorySlug;

  /// True when freemium limits this category to a teaser pack.
  bool isLocked;

  final QuestionRepository _repository;

  List<QuizQuestion> _questions = const [];
  int _index = 0;
  int _correct = 0;
  int? _selected;
  bool _answered = false;
  bool _finished = false;
  bool _loading = true;
  String? _error;
  DateTime? _questionStartedAt;
  final List<double> _responseTimes = [];

  /// Fired once when the user tries to advance past the free teaser (Q3+).
  bool paywallRequested = false;

  List<QuizQuestion> get questions => _questions;
  int get index => _index;
  int get correctCount => _correct;
  int? get selectedIndex => _selected;
  bool get answered => _answered;
  bool get finished => _finished;
  bool get loading => _loading;
  String? get error => _error;
  int get total => _questions.length;
  int get displayNumber => total == 0 ? 0 : _index + 1;
  List<double> get responseTimes => List.unmodifiable(_responseTimes);

  /// Display total for the progress header (teaser = pack size, else 20).
  int get progressTotal {
    if (total == 0) {
      return isLocked ? 2 : AppConstants.questionsPerCategory;
    }
    return total;
  }

  DateTime? get questionStartedAt => _questionStartedAt;

  /// Elapsed seconds on the current question (live).
  double get currentQuestionElapsedSec {
    final started = _questionStartedAt;
    if (started == null) return 0;
    return DateTime.now().difference(started).inMilliseconds / 1000.0;
  }

  QuizQuestion get current {
    if (_questions.isEmpty) {
      throw StateError('Quiz has no questions loaded');
    }
    return _questions[_index];
  }

  /// Resets to Question 1 with a fresh pack from API (or local fallback).
  Future<void> start() async {
    _loading = true;
    _error = null;
    _index = 0;
    _correct = 0;
    _selected = null;
    _answered = false;
    _finished = false;
    paywallRequested = false;
    _responseTimes.clear();
    _questionStartedAt = null;
    notifyListeners();

    try {
      try {
        _questions = await _repository.questionsForRemote(remoteCategoryId);
      } on ApiException {
        final fallback = localFallback ?? QuizCategoryId.quickMath;
        _questions = _repository.questionsFor(fallback);
        isLocked = false;
      } catch (_) {
        final fallback = localFallback ?? QuizCategoryId.quickMath;
        _questions = _repository.questionsFor(fallback);
        isLocked = false;
      }
      _questionStartedAt = DateTime.now();
    } catch (e) {
      _error = e.toString();
      _questions = const [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void selectOption(int optionIndex) {
    if (_answered || _finished || _questions.isEmpty) return;
    _selected = optionIndex;
    _answered = true;
    final started = _questionStartedAt;
    if (started != null) {
      final secs =
          DateTime.now().difference(started).inMilliseconds / 1000.0;
      _responseTimes.add(double.parse(secs.toStringAsFixed(2)));
    }
    if (optionIndex == current.correctIndex) {
      _correct++;
    }
    notifyListeners();
  }

  /// Advances to the next question, or marks the session finished.
  ///
  /// For locked categories, requesting question #3 triggers [paywallRequested].
  void next() {
    if (!_answered) return;

    // Freemium: finishing the 2-question teaser (about to enter Q3 world).
    if (isLocked && _index + 1 >= total && total < AppConstants.questionsPerCategory) {
      paywallRequested = true;
      _finished = true;
      notifyListeners();
      return;
    }

    if (_index + 1 >= total) {
      _finished = true;
      notifyListeners();
      return;
    }

    final nextIndex = _index + 1;
    // Explicit Q3 gate if a longer pack somehow loaded while still locked.
    if (isLocked && nextIndex >= 2) {
      paywallRequested = true;
      notifyListeners();
      return;
    }

    _index = nextIndex;
    _selected = null;
    _answered = false;
    _questionStartedAt = DateTime.now();
    notifyListeners();
  }

  void clearPaywallRequest() {
    paywallRequested = false;
    notifyListeners();
  }

  Future<void> syncProgressToBackend({required int score}) async {
    await _repository.syncProgress(
      categoryId: remoteCategoryId,
      completedQuestions: _correct,
      score: score,
    );
  }
}
