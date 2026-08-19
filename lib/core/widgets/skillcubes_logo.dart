import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

/// SkillCubes logo with a transparent plate (no solid navy square).
///
/// Sits directly on the scaffold / app background. Optionally wraps the
/// glyph in a soft translucent squircle for contrast on dark UI.
class SkillCubesLogo extends StatelessWidget {
  const SkillCubesLogo({
    super.key,
    this.size = 96,
    this.showSoftPlate = false,
    this.fit = BoxFit.contain,
  });

  final double size;

  /// Soft translucent plate behind the glyph (not a harsh opaque square).
  final bool showSoftPlate;

  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final image = SvgPicture.asset(
      AppAssets.logoSvg,
      width: showSoftPlate ? size * 0.88 : size,
      height: showSoftPlate ? size * 0.88 : size,
      fit: fit,
      placeholderBuilder: (_) => Image.asset(
        AppAssets.logo,
        width: showSoftPlate ? size * 0.88 : size,
        height: showSoftPlate ? size * 0.88 : size,
        fit: fit,
        filterQuality: FilterQuality.high,
      ),
    );

    if (!showSoftPlate) {
      return SizedBox(
        width: size,
        height: size,
        child: ColoredBox(
          color: Colors.transparent,
          child: image,
        ),
      );
    }

    final radius = size * 0.22;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: AppColors.borderOf(context).withValues(alpha: 0.35),
        ),
      ),
      child: image,
    );
  }
}
