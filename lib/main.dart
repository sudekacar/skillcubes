import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/localization/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_provider.dart';
import 'core/services/category_provider.dart';
import 'core/services/game_stats_store.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: LightPalette.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final prefs = await SharedPreferences.getInstance();

  await NotificationService.instance.init(prefs: prefs);

  final api = ApiService(prefs);
  final auth = AuthProvider(api);
  await auth.tryRestoreSession();

  final categories = CategoryProvider(api);
  if (api.isAuthenticated) {
    await categories.refresh();
    // Restore daily streak reminder for returning sessions.
    await NotificationService.instance.ensureDailyReminderScheduled();
  }

  final store = GameStatsStore(prefs);
  await store.load();

  final themeProvider = ThemeProvider(prefs);

  final localeProvider = LocaleProvider(prefs);
  await localeProvider.load();

  runApp(
    SkillCubesApp(
      api: api,
      auth: auth,
      categories: categories,
      store: store,
      themeProvider: themeProvider,
      localeProvider: localeProvider,
    ),
  );
}

/// Root widget wiring theme, locale, auth, API, and navigation.
class SkillCubesApp extends StatefulWidget {
  const SkillCubesApp({
    super.key,
    required this.api,
    required this.auth,
    required this.categories,
    required this.store,
    required this.themeProvider,
    required this.localeProvider,
  });

  final ApiService api;
  final AuthProvider auth;
  final CategoryProvider categories;
  final GameStatsStore store;
  final ThemeProvider themeProvider;
  final LocaleProvider localeProvider;

  @override
  State<SkillCubesApp> createState() => _SkillCubesAppState();
}

class _SkillCubesAppState extends State<SkillCubesApp> {
  late final _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: widget.api),
        ChangeNotifierProvider.value(value: widget.auth),
        ChangeNotifierProvider.value(value: widget.categories),
        ChangeNotifierProvider.value(value: widget.store),
        ChangeNotifierProvider.value(value: widget.themeProvider),
        ChangeNotifierProvider.value(value: widget.localeProvider),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, theme, locale, _) {
          final isDark = theme.isDark;
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor:
                  isDark ? DarkPalette.background : LightPalette.background,
              systemNavigationBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
            ),
          );
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: MediaQuery.textScalerOf(context).clamp(
                minScaleFactor: 1,
                maxScaleFactor: 1.15,
              ),
            ),
            child: MaterialApp.router(
            title: 'SkillCubes',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: theme.themeMode,
            locale: locale.locale,
            supportedLocales: const [
              Locale('tr', 'TR'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
            ),
          );
        },
      ),
    );
  }
}
