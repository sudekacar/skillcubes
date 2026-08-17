import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import 'skillcubes_logo.dart';

/// Top app bar that always shows the SkillCubes logo beside the title.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.title,
    this.showLogo = true,
    this.actions,
    this.leading,
  });

  final String? title;
  final bool showLogo;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      title: Row(
        children: [
          if (showLogo) ...[
            const SkillCubesLogo(size: 36),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              title ?? AppConstants.appName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
