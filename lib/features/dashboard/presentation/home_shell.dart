import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/l10n_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';

/// Bottom-nav shell hosting Train / Leaderboard / Profile branches.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    AppHaptics.selection();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: AppColors.borderOf(context))),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: navigationShell.currentIndex,
            onTap: _onTap,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.sports_esports_outlined),
                activeIcon: const Icon(Icons.sports_esports),
                label: context.tr('nav_train'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.leaderboard_outlined),
                activeIcon: const Icon(Icons.leaderboard),
                label: context.tr('nav_leaderboard'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person),
                label: context.tr('nav_profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
