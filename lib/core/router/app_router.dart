import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai_coach/emma_chat_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/dashboard/presentation/home_shell.dart';
import '../../features/games/arcade/arcade_catalog.dart';
import '../../features/games/arcade/arcade_game_screen.dart';
import '../../features/games/charts/charts_game_screen.dart';
import '../../features/games/funnel/funnel_game_screen.dart';
import '../../features/games/go_nogo/go_nogo_game_screen.dart';
import '../../features/games/pattern/pattern_game_screen.dart';
import '../../features/games/presentation/games_hub_screen.dart';
import '../../features/games/quick_math/quick_math_game_screen.dart';
import '../../features/games/ratio/ratio_game_screen.dart';
import '../../features/leaderboard/presentation/leaderboard_screen.dart';
import '../../features/marathon/presentation/marathon_screen.dart';
import '../../features/problems/presentation/problems_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/quiz/domain/quiz_category.dart';
import '../../features/quiz/presentation/quiz_screen.dart';
import '../../features/premium/checkout_screen.dart';
import '../../features/premium/premium_plan.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../widgets/snappy_sheet.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

/// Instant / snappy page transitions for nested dashboard routes.
CustomTransitionPage<void> _snappyPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: kSnappyForward,
    reverseTransitionDuration: kSnappyReverse,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Tiny opacity ramp — avoids heavy slide stacks feeling sluggish.
      final t = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: Tween<double>(begin: 0.92, end: 1).animate(t),
        child: child,
      );
    },
  );
}

/// Central go_router configuration for SkillCubes.
///
/// Flow: `/` (Splash) → `/login` → `/dashboard`
GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          final registered = state.uri.queryParameters['registered'] == '1';
          return LoginScreen(
            initialEmail: email,
            showRegisterSuccess: registered,
          );
        },
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/checkout',
        pageBuilder: (context, state) {
          final plan = PremiumPlan.fromQuery(
            state.uri.queryParameters['plan'],
          );
          return _snappyPage(
            key: state.pageKey,
            child: CheckoutScreen(plan: plan),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const GamesHubScreen(),
                routes: [
                  GoRoute(
                    path: 'quiz/local/:slug',
                    pageBuilder: (context, state) {
                      final slug = state.pathParameters['slug'];
                      final local = QuizCategory.tryParse(slug) ??
                          QuizCategoryId.quickMath;
                      return _snappyPage(
                        key: state.pageKey,
                        child: QuizScreen(
                          remoteCategoryId: local.index + 1,
                          localFallback: local,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'quiz/:categoryId',
                    pageBuilder: (context, state) {
                      final raw = state.pathParameters['categoryId'] ?? '1';
                      final remoteId = int.tryParse(raw) ?? 1;
                      return _snappyPage(
                        key: state.pageKey,
                        child: QuizScreen(remoteCategoryId: remoteId),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'arcade/:kind',
                    pageBuilder: (context, state) {
                      final kind = ArcadeKind.tryParse(
                            state.pathParameters['kind'],
                          ) ??
                          ArcadeKind.speedTap;
                      final categoryId = int.tryParse(
                            state.uri.queryParameters['categoryId'] ?? '',
                          ) ??
                          0;
                      final slug = state.uri.queryParameters['slug'] ?? '';
                      final title = state.uri.queryParameters['title'] ?? '';
                      return _snappyPage(
                        key: state.pageKey,
                        child: ArcadeGameScreen(
                          kind: kind,
                          categoryId: categoryId,
                          categorySlug: slug,
                          title: title,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'emma',
                    pageBuilder: (context, state) => _snappyPage(
                      key: state.pageKey,
                      child: const EmmaChatScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'funnel',
                    pageBuilder: (context, state) => _snappyPage(
                      key: state.pageKey,
                      child: const FunnelGameScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'pattern',
                    pageBuilder: (context, state) => _snappyPage(
                      key: state.pageKey,
                      child: const PatternGameScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'quick-math',
                    pageBuilder: (context, state) => _snappyPage(
                      key: state.pageKey,
                      child: const QuickMathGameScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'ratio',
                    pageBuilder: (context, state) => _snappyPage(
                      key: state.pageKey,
                      child: const RatioGameScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'charts',
                    pageBuilder: (context, state) => _snappyPage(
                      key: state.pageKey,
                      child: const ChartsGameScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'go-nogo',
                    pageBuilder: (context, state) => _snappyPage(
                      key: state.pageKey,
                      child: const GoNoGoGameScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'problems',
                    pageBuilder: (context, state) => _snappyPage(
                      key: state.pageKey,
                      child: const ProblemsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'marathon',
                    pageBuilder: (context, state) => _snappyPage(
                      key: state.pageKey,
                      child: const MarathonScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/leaderboard',
                builder: (context, state) => const LeaderboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
