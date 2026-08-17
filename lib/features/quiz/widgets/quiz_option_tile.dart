import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../utils/question_visual_parser.dart';
import 'visuals/ratio_question_view.dart';
import 'visuals/shape_glyphs.dart';

const _optionLetters = ['A', 'B', 'C', 'D', 'E', 'F'];

/// Option row with circular letter badge + soft correct/incorrect feedback.
class QuizOptionTile extends StatelessWidget {
  const QuizOptionTile({
    super.key,
    required this.index,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.showCorrect = false,
    this.showIncorrect = false,
    this.enabled = true,
    this.categorySlug = '',
  });

  final int index;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool showCorrect;
  final bool showIncorrect;
  final bool enabled;
  final String categorySlug;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final letter = index < _optionLetters.length
        ? _optionLetters[index]
        : '${index + 1}';

    Color border;
    Color? fill;
    Color badgeBg;
    Color badgeFg;

    if (showCorrect) {
      border = AppColors.mint;
      fill = AppColors.mint.withValues(alpha: 0.14);
      badgeBg = AppColors.mint;
      badgeFg = Colors.white;
    } else if (showIncorrect) {
      border = AppColors.accentRed;
      fill = AppColors.accentRed.withValues(alpha: 0.12);
      badgeBg = AppColors.accentRed;
      badgeFg = Colors.white;
    } else if (selected) {
      border = scheme.primary;
      fill = scheme.primary.withValues(alpha: 0.08);
      badgeBg = scheme.primary;
      badgeFg = scheme.onPrimary;
    } else {
      border = AppColors.borderOf(context);
      fill = null;
      badgeBg = scheme.primary.withValues(alpha: 0.12);
      badgeFg = scheme.primary;
    }

    return AppCard(
      useInk: false,
      color: fill,
      borderColor: border,
      onTap: enabled ? onTap : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: badgeBg,
              shape: BoxShape.circle,
            ),
            child: Text(
              letter,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: badgeFg,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _OptionBody(label: label, categorySlug: categorySlug)),
          if (showCorrect)
            const Icon(Icons.check_circle, color: AppColors.mint, size: 22)
          else if (showIncorrect)
            const Icon(Icons.cancel, color: AppColors.accentRed, size: 22),
        ],
      ),
    );
  }
}

class _OptionBody extends StatelessWidget {
  const _OptionBody({required this.label, required this.categorySlug});

  final String label;
  final String categorySlug;

  @override
  Widget build(BuildContext context) {
    final slug = categorySlug.toLowerCase();
    final fraction = QuestionVisualParser.parseFraction(label);
    if (fraction != null &&
        (slug.contains('ratio') || slug.contains('oran') || label.contains('/'))) {
      final accents = [ShapeGlyphs.indigo, ShapeGlyphs.emerald, ShapeGlyphs.amber, ShapeGlyphs.sky];
      // Use hash of fraction for stable accent
      final accent = accents[(fraction.num + fraction.den) % accents.length];
      return RatioOptionChip(
        num: fraction.num,
        den: fraction.den,
        accent: accent,
      );
    }

    final looksLikeShapes = label.runes.length >= 2 &&
        label.runes.every((r) {
          final s = String.fromCharCode(r);
          return '▲△■∎█▢●○◆◇♦★☆✚+┼'.contains(s) || s.trim().isEmpty;
        });

    if (looksLikeShapes ||
        slug.contains('funnel') ||
        (label.isNotEmpty && !RegExp(r'^[A-Za-z0-9 /]+$').hasMatch(label))) {
      final shapes = QuestionVisualParser.parseShapeSequence(label);
      if (shapes.length >= 2) {
        return ShapeGlyphs.sequence(shapes, size: 24, gap: 5);
      }
    }

    return Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        height: 1.3,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
