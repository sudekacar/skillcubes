import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/visual_question.dart';
import 'shape_glyphs.dart';

const _barPalette = [
  ShapeGlyphs.sky,
  ShapeGlyphs.indigo,
  ShapeGlyphs.emerald,
  ShapeGlyphs.amber,
  ShapeGlyphs.rose,
  ShapeGlyphs.violet,
];

/// Colorful glowing bar chart for "Grafik Okuma" questions.
class ChartQuestionView extends StatelessWidget {
  const ChartQuestionView({super.key, required this.data});

  final ChartVisual data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxY = data.bars
        .map((b) => b.value)
        .fold<double>(1, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          data.questionLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxY * 1.25,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: scheme.outline.withValues(alpha: 0.25),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, meta) {
                      if (v == meta.max || v == 0) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        v.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (i < 0 || i >= data.bars.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          data.bars[i].label,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _barPalette[i % _barPalette.length],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < data.bars.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: data.bars[i].value,
                        width: 28,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            _barPalette[i % _barPalette.length]
                                .withValues(alpha: 0.55),
                            _barPalette[i % _barPalette.length],
                          ],
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY * 1.25,
                          color: scheme.outline.withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                    showingTooltipIndicators: const [],
                  ),
              ],
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) =>
                      scheme.surface.withValues(alpha: 0.95),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final bar = data.bars[group.x.toInt()];
                    return BarTooltipItem(
                      '${bar.label}: ${bar.value.toInt()}',
                      TextStyle(
                        color: _barPalette[group.x.toInt() % _barPalette.length],
                        fontWeight: FontWeight.w800,
                      ),
                    );
                  },
                ),
              ),
            ),
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeOutCubic,
          ),
        ),
        const SizedBox(height: 8),
        // Glow legend chips
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            for (var i = 0; i < data.bars.length; i++)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _barPalette[i % _barPalette.length]
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _barPalette[i % _barPalette.length]
                        .withValues(alpha: 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _barPalette[i % _barPalette.length]
                          .withValues(alpha: 0.25),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  '${data.bars[i].label} = ${data.bars[i].value.toInt()}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _barPalette[i % _barPalette.length],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
