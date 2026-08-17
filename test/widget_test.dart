import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:skillcubes/core/localization/locale_provider.dart';
import 'package:skillcubes/core/services/api_service.dart';
import 'package:skillcubes/core/services/auth_provider.dart';
import 'package:skillcubes/core/services/category_provider.dart';
import 'package:skillcubes/core/services/game_stats_store.dart';
import 'package:skillcubes/core/theme/theme_provider.dart';
import 'package:skillcubes/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SkillCubes boots to splash', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final api = ApiService(prefs);
    final auth = AuthProvider(api);
    final categories = CategoryProvider(api);
    final store = GameStatsStore(prefs);
    await store.load();
    final theme = ThemeProvider(prefs);
    final locale = LocaleProvider(prefs);
    await locale.load();

    await tester.pumpWidget(
      SkillCubesApp(
        api: api,
        auth: auth,
        categories: categories,
        store: store,
        themeProvider: theme,
        localeProvider: locale,
      ),
    );
    await tester.pump();
    expect(find.text('Oturum kontrol ediliyor...'), findsOneWidget);
  });
}
