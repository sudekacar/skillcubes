import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported app locales.
enum AppLanguage { en, tr }

extension AppLanguageX on AppLanguage {
  String get code => name;

  Locale get locale => switch (this) {
        AppLanguage.tr => const Locale('tr', 'TR'),
        AppLanguage.en => const Locale('en', 'US'),
      };

  static AppLanguage fromCode(String? code) =>
      code == 'en' ? AppLanguage.en : AppLanguage.tr;
}

/// Loads TR/EN JSON dictionaries and resolves `{placeholder}` strings.
class LocaleProvider extends ChangeNotifier {
  LocaleProvider(this._prefs);

  static const _key = 'app_language';

  final SharedPreferences _prefs;
  AppLanguage _language = AppLanguage.tr;
  Map<String, String> _strings = {};

  AppLanguage get language => _language;
  Locale get locale => _language.locale;

  /// Call once at startup after constructing the provider.
  Future<void> load() async {
    _language = AppLanguageX.fromCode(_prefs.getString(_key));
    await _loadDictionary(_language);
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language && _strings.isNotEmpty) return;
    _language = language;
    await _prefs.setString(_key, language.code);
    await _loadDictionary(language);
    notifyListeners();
  }

  Future<void> _loadDictionary(AppLanguage language) async {
    final path = 'assets/translations/${language.code}.json';
    final raw = await rootBundle.loadString(path);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _strings = map.map((k, v) => MapEntry(k, v.toString()));
  }

  /// Translate [key]. Optional [params] replace `{name}` tokens.
  String t(String key, [Map<String, String>? params]) {
    var value = _strings[key] ?? key;
    if (params != null) {
      params.forEach((k, v) {
        value = value.replaceAll('{$k}', v);
      });
    }
    return value;
  }
}
