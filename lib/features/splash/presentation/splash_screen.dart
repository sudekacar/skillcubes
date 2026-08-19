import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/l10n_ext.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/game_stats_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skillcubes_logo_mark.dart';

/// Boot splash: logo + brand fade/scale, session check, then route forward.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _holdDuration = Duration(milliseconds: 2300);
  static const _exitDuration = Duration(milliseconds: 420);

  late final AnimationController _introController;
  late final AnimationController _exitController;
  late final AnimationController _glowController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _glowPulse;

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: _exitDuration,
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    final introCurve = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );

    _logoScale = Tween<double>(begin: 0.72, end: 1).animate(introCurve);
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(introCurve);
    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.35, 1, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
      ),
    );
    _glowPulse = Tween<double>(begin: 0.55, end: 1).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _introController.forward();

    _navTimer = Timer(_holdDuration, _finishSplash);
  }

  Future<void> _finishSplash() async {
    if (!mounted) return;

    final api = context.read<ApiService>();
    final store = context.read<GameStatsStore>();
    final destination =
        api.isAuthenticated || store.isGuestMode ? '/dashboard' : '/login';

    await _exitController.forward();
    if (!mounted) return;
    context.go(destination);
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _introController.dispose();
    _exitController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgTop = isDark ? AppAccents.navy : LightPalette.background;
    final bgMid = isDark ? DarkPalette.surface : LightPalette.surfaceLight;
    final bgBottom = isDark ? const Color(0xFF071020) : const Color(0xFFE2E8F0);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _exitController,
        builder: (context, child) {
          return Opacity(
            opacity: 1 - _exitController.value,
            child: child,
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bgTop, bgMid, bgBottom],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: _glowPulse,
                builder: (context, _) {
                  return Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 280 * _glowPulse.value,
                      height: 280 * _glowPulse.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            scheme.primary.withValues(alpha: 0.22),
                            scheme.primary.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeTransition(
                        opacity: _logoOpacity,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: const SkillCubesLogoMark(size: 128),
                        ),
                      ),
                      const SizedBox(height: 28),
                      FadeTransition(
                        opacity: _titleOpacity,
                        child: SlideTransition(
                          position: _titleSlide,
                          child: Column(
                            children: [
                              Text(
                                context.tr('app_name'),
                                textAlign: TextAlign.center,
                                style: textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                context.tr('tagline'),
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.muted(context),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
