import 'package:flutter/material.dart';

import '../../domain/visual_question.dart';
import 'shape_glyphs.dart';

/// Sci-fi funnel transformation board for "Funnel Dönüşüm".
class FunnelQuestionView extends StatelessWidget {
  const FunnelQuestionView({super.key, required this.data});

  final FunnelVisual data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'GİRDİ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        _GlyphRail(
          glyphs: data.inputs,
          indexed: true,
        ),
        const SizedBox(height: 14),
        _RuleFlowBox(order: data.ruleOrder),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ShapeGlyphs.indigo.withValues(alpha: 0.35),
            ),
            color: ShapeGlyphs.indigo.withValues(alpha: isDark ? 0.12 : 0.06),
          ),
          child: Text(
            'Doğru çıktı sırasını seç',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _GlyphRail extends StatelessWidget {
  const _GlyphRail({required this.glyphs, this.indexed = false});

  final List<String> glyphs;
  final bool indexed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < glyphs.length; i++)
          Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      ShapeGlyphs.colorFor(glyphs[i]).withValues(alpha: 0.22),
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                  border: Border.all(
                    color: ShapeGlyphs.colorFor(glyphs[i]).withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ShapeGlyphs.colorFor(glyphs[i])
                          .withValues(alpha: 0.28),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: ShapeGlyphs.build(glyphs[i], size: 28),
                ),
              ),
              if (indexed) ...[
                const SizedBox(height: 4),
                Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _RuleFlowBox extends StatelessWidget {
  const _RuleFlowBox({required this.order});

  final List<int> order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ShapeGlyphs.sky.withValues(alpha: 0.45),
          width: 1.4,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ShapeGlyphs.sky.withValues(alpha: 0.14),
            ShapeGlyphs.indigo.withValues(alpha: 0.1),
            scheme.surface,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: ShapeGlyphs.sky.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_fix_high, size: 16, color: ShapeGlyphs.sky),
              const SizedBox(width: 6),
              Text(
                'DÖNÜŞÜM KURALI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: ShapeGlyphs.sky,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < order.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: ShapeGlyphs.indigo.withValues(alpha: 0.8),
                      ),
                    ),
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ShapeGlyphs.indigo.withValues(alpha: 0.18),
                      border: Border.all(color: ShapeGlyphs.indigo),
                      boxShadow: [
                        BoxShadow(
                          color: ShapeGlyphs.indigo.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      '${order[i]}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: ShapeGlyphs.indigo,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            order.join(' → '),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
