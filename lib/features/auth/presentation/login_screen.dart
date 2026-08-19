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
import '../../../core/widgets/skillcubes_logo_mark.dart';

/// Clean, centered login — sharp typography & vector branding.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.initialEmail,
    this.showRegisterSuccess = false,
  });

  final String? initialEmail;
  final bool showRegisterSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();
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
    for (final node in [_emailFocus, _passwordFocus]) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
    required bool focused,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = focused ? scheme.primary : scheme.outline;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.muted(context),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(
        prefixIcon,
        size: 22,
        color: focused ? scheme.primary : AppColors.muted(context),
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor.withValues(alpha: 0.55)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error),
      ),
    );
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
      final store = context.read<GameStatsStore>();
      await store.clearGuestMode();
      await store.setDisplayName(name);
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
    final store = context.read<GameStatsStore>();
    await store.enableGuestMode();
    await store.setDisplayName(guestName);
    if (!mounted) return;
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 420,
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Center(child: SkillCubesLogoMark(size: 96)),
                        const SizedBox(height: 20),
                        Text(
                          context.tr('app_name'),
                          textAlign: TextAlign.center,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('welcome_back'),
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr('auth_subtitle'),
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted(context),
                            fontSize: 15,
                            height: 1.45,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          style: textTheme.bodyLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: _fieldDecoration(
                            hint: context.tr('email_hint'),
                            prefixIcon: Icons.mail_outline_rounded,
                            focused: _emailFocus.hasFocus,
                          ),
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          style: textTheme.bodyLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: _fieldDecoration(
                            hint: context.tr('password_hint'),
                            prefixIcon: Icons.lock_outline_rounded,
                            focused: _passwordFocus.hasFocus,
                            suffix: IconButton(
                              tooltip: _obscure ? 'Show' : 'Hide',
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 22,
                                color: _passwordFocus.hasFocus
                                    ? scheme.primary
                                    : AppColors.muted(context),
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _busy ? null : _login(),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 54,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _busy ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: scheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: scheme.primary.withValues(alpha: 0.35),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            child: _busy
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(context.tr('login')),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: _busy ? null : _guest,
                          style: TextButton.styleFrom(
                            foregroundColor: scheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(context.tr('continue_guest')),
                        ),
                        const SizedBox(height: 4),
                        Column(
                          children: [
                            Text(
                              context.tr('no_account'),
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.muted(context),
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () {
                                      AppHaptics.selection();
                                      context.push('/signup');
                                    },
                              style: TextButton.styleFrom(
                                foregroundColor: scheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: Text(context.tr('signup')),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
