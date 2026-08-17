import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/l10n_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skillcubes_logo.dart';

/// Boot splash: animated logo + rotating status lines, then routes to login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _statusKeys = [
    'splash_status_session',
    'splash_status_modules',
    'splash_status_connection',
  ];

  late final AnimationController _pulseController;
  late final AnimationController _rotateController;
  late final AnimationController _fadeController;
  late final Animation<double> _pulse;
  late final Animation<double> _fadeIn;

  Timer? _statusTimer;
  Timer? _navTimer;
  int _statusIndex = 0;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();

    _pulse = Tween<double>(begin: 0.92, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _statusTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (!mounted) return;
      setState(() => _statusIndex = (_statusIndex + 1) % _statusKeys.length);
    });

    _navTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      context.go('/login');
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _navTimer?.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Smooth scale pulse + gentle rotation — no title text.
                AnimatedBuilder(
                  animation: Listenable.merge([_pulse, _rotateController]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulse.value,
                      child: Transform.rotate(
                        angle: _rotateController.value * 0.35,
                        child: child,
                      ),
                    );
                  },
                  child: const SkillCubesLogo(size: 156),
                ),
                const SizedBox(height: 36),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    context.tr(_statusKeys[_statusIndex]),
                    key: ValueKey(_statusIndex),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
