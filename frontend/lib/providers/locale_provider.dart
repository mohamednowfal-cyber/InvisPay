import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

class LocaleNotifier extends Notifier<Locale> {
  static const String _prefKey = 'selected_locale';

  @override
  Locale build() {
    _loadLocale();
    return const Locale('en');
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_prefKey) ?? 'en';
    state = Locale(languageCode);
  }

  Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, languageCode);
    state = Locale(languageCode);
  }

  Future<bool> hasUserSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_prefKey);
  }
}

class AppLanguage {
  final String name;
  final String nativeName;
  final String code;

  const AppLanguage({
    required this.name,
    required this.nativeName,
    required this.code,
  });
}

const List<AppLanguage> supportedLanguages = [
  AppLanguage(name: 'English', nativeName: 'English', code: 'en'),
  AppLanguage(name: 'Hindi', nativeName: 'हिन्दी', code: 'hi'),
  AppLanguage(name: 'Tamil', nativeName: 'தமிழ்', code: 'ta'),
  AppLanguage(name: 'Telugu', nativeName: 'తెలుగు', code: 'te'),
  AppLanguage(name: 'Malayalam', nativeName: 'മലയാളം', code: 'ml'),
  AppLanguage(name: 'Kannada', nativeName: 'ಕನ್ನಡ', code: 'kn'),
  AppLanguage(name: 'Marathi', nativeName: 'मराठी', code: 'mr'),
  AppLanguage(name: 'Bengali', nativeName: 'বাংলা', code: 'bn'),
  AppLanguage(name: 'Gujarati', nativeName: 'ગુજરાતી', code: 'gu'),
  AppLanguage(name: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ', code: 'pa'),
  AppLanguage(name: 'Odia', nativeName: 'ଓଡ଼ିଆ', code: 'or'),
  AppLanguage(name: 'Urdu', nativeName: 'اردو', code: 'ur'),
];
