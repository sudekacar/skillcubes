import 'package:flutter/material.dart';

/// Shared sheet timing — crisp, native-feeling (≤150ms).
const Duration kSnappyForward = Duration(milliseconds: 120);
const Duration kSnappyReverse = Duration(milliseconds: 100);

/// Ultra-fast modal bottom sheet (slide only, no heavy fades).
Future<T?> showSnappyModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = false,
  bool isScrollControlled = true,
  Color? backgroundColor,
  ShapeBorder? shape,
}) {
  final theme = Theme.of(context);
  final bg = backgroundColor ?? theme.colorScheme.surface;
  final sheetShape = shape ??
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      );
  final barrierLabel =
      MaterialLocalizations.of(context).modalBarrierDismissLabel;

  return Navigator.of(context).push<T>(
    PageRouteBuilder<T>(
      opaque: false,
      barrierDismissible: isDismissible,
      barrierLabel: barrierLabel,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: kSnappyForward,
      reverseTransitionDuration: kSnappyReverse,
      pageBuilder: (context, animation, secondaryAnimation) {
        Widget sheet = Material(
          color: bg,
          elevation: 8,
          shadowColor: Colors.black26,
          shape: sheetShape,
          clipBehavior: Clip.antiAlias,
          child: builder(context),
        );

        if (enableDrag && isDismissible) {
          sheet = GestureDetector(
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) > 400) {
                Navigator.of(context).maybePop();
              }
            },
            child: sheet,
          );
        }

        return Align(
          alignment: Alignment.bottomCenter,
          child: isScrollControlled
              ? sheet
              : SafeArea(child: sheet),
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    ),
  );
}
