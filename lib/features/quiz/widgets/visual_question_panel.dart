import 'package:flutter/material.dart';

import '../domain/visual_question.dart';
import '../utils/question_visual_parser.dart';
import 'visuals/chart_question_view.dart';
import 'visuals/funnel_question_view.dart';
import 'visuals/ratio_question_view.dart';

/// Routes a quiz prompt into the matching visual engine (or text fallback).
class VisualQuestionPanel extends StatefulWidget {
  const VisualQuestionPanel({
    super.key,
    required this.prompt,
    required this.categorySlug,
  });

  final String prompt;
  final String categorySlug;

  @override
  State<VisualQuestionPanel> createState() => _VisualQuestionPanelState();
}

class _VisualQuestionPanelState extends State<VisualQuestionPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  VisualQuestion? _visual;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _parseAndPlay();
  }

  @override
  void didUpdateWidget(covariant VisualQuestionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prompt != widget.prompt ||
        oldWidget.categorySlug != widget.categorySlug) {
      _parseAndPlay();
    }
  }

  void _parseAndPlay() {
    _visual = QuestionVisualParser.parse(
      prompt: widget.prompt,
      categorySlug: widget.categorySlug,
    );
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visual = _visual;

    final child = switch (visual) {
      final ChartVisual c => ChartQuestionView(data: c),
      final RatioVisual r => RatioQuestionView(data: r),
      final FunnelVisual f => FunnelQuestionView(data: f),
      null => Text(
          widget.prompt,
          style: TextStyle(
            fontSize: 17,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
    };

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: child,
      ),
    );
  }
}
