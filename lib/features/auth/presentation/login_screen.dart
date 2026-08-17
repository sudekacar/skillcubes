import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/l10n_ext.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/services/category_provider.dart';
import '../../../core/services/game_stats_store.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/skillcubes_logo.dart';

/// Dark modern login card — email/password + guest continue.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.initialEmail,
    this.showRegisterSuccess = false,
  });

  /// Prefill from registration redirect (`?email=`).
  final String? initialEmail;

  /// Show the post-registration success snackbar.
  final bool showRegisterSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.initialEmail?.trim() ?? '',
    );
    if (widget.showRegisterSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.trRead('register_success'))),
        );
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    await AppHaptics.medium();
    if (!mounted) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trRead('fill_all_fields'))),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.login(email: email, password: password);
      if (!mounted) return;
      final name = auth.user?.fullName.isNotEmpty == true
          ? auth.user!.fullName
          : email.split('@').first;
      await context.read<GameStatsStore>().setDisplayName(name);
      if (!mounted) return;
      await context.read<CategoryProvider>().refresh();
      if (!mounted) return;
      await NotificationService.instance.ensureDailyReminderScheduled();
      if (!mounted) return;
      context.go('/dashboard');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _guest() async {
    await AppHaptics.light();
    if (!mounted) return;
    final guestName = context.trRead('guest');
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    await context.read<GameStatsStore>().setDisplayName(guestName);
    if (!mounted) return;
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: context.tr('app_name'), showLogo: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const SkillCubesLogo(size: 96),
              const SizedBox(height: 16),
              Text(
                context.tr('welcome_back'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('auth_subtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted(context)),
              ),
              const SizedBox(height: 28),
              AppCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: InputDecoration(
                        hintText: context.tr('email_hint'),
                        prefixIcon: Icon(
                          Icons.mail_outline,
                          color: AppColors.muted(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      onSubmitted: (_) => _busy ? null : _login(),
                      decoration: InputDecoration(
                        hintText: context.tr('password_hint'),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: AppColors.muted(context),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.muted(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _login,
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(context.tr('login')),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _busy ? null : _guest,
                child: Text(
                  context.tr('continue_guest'),
                  style: TextStyle(color: AppColors.muted(context)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.tr('no_account'),
                    style: TextStyle(color: AppColors.muted(context)),
                  ),
                  TextButton(
                    onPressed: () {
                      AppHaptics.selection();
                      context.push('/signup');
                    },
                    child: Text(context.tr('signup')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
