import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_constants.dart';

/// High-resolution SkillCubes logo from SVG asset (transparent background).
class SkillCubesSvgLogo extends StatelessWidget {
  const SkillCubesSvgLogo({
    super.key,
    this.size = 120,
    this.semanticsLabel = 'SkillCubes',
  });

  final double size;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset(
          AppAssets.logoSvg,
          width: size,
          height: size,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          placeholderBuilder: (_) => Image.asset(
            AppAssets.logo,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}

/// Compact brand lockup for app bars and auth headers.
class SkillCubesBrandLockup extends StatelessWidget {
  const SkillCubesBrandLockup({
    super.key,
    this.logoSize = 34,
    this.subtitle,
  });

  final double logoSize;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SkillCubesSvgLogo(size: logoSize),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SkillCubes',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1.05,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                    height: 1.2,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
