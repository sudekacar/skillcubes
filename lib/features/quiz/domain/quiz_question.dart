/// A single multiple-choice quiz item.
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.categoryId,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    this.hint,
  });

  final String id;
  final String categoryId;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String? hint;

  QuizQuestion copyWithCategory(String categoryId) => QuizQuestion(
        id: id,
        categoryId: categoryId,
        prompt: prompt,
        options: options,
        correctIndex: correctIndex,
        hint: hint,
      );
}
