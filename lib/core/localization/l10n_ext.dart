import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'locale_provider.dart';

/// Convenience helpers for reading localized strings.
extension TranslateX on BuildContext {
  /// Watch translations (rebuilds on language change).
  String tr(String key, [Map<String, String>? params]) =>
      watch<LocaleProvider>().t(key, params);

  /// Read translations without listening.
  String trRead(String key, [Map<String, String>? params]) =>
      read<LocaleProvider>().t(key, params);

  LocaleProvider get localeProvider => watch<LocaleProvider>();
}
