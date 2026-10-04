import 'package:flutter/material.dart';
import '../utils/storage_service.dart';
import 'app_strings.dart';

class AppLanguageService {
  static final AppLanguageService _instance = AppLanguageService._internal();
  factory AppLanguageService() => _instance;
  AppLanguageService._internal();

  final ValueNotifier<String> languageNotifier = ValueNotifier<String>('vi');

  String get currentLanguage => languageNotifier.value;
  bool get isVietnamese => languageNotifier.value == 'vi';

  Future<void> init() async {
    final savedLang = await StorageService.getLanguage();
    if (savedLang != null && (savedLang == 'vi' || savedLang == 'en')) {
      languageNotifier.value = savedLang;
    }
  }

  Future<void> setLanguage(String langCode) async {
    if (langCode == languageNotifier.value) return;
    languageNotifier.value = langCode;
    await StorageService.setLanguage(langCode);
  }

  String tr(String key) => AppStrings.get(key, lang: languageNotifier.value);
}

// Global helper function similar to $t('key') in Vue / React i18n
String tr(String key) => AppLanguageService().tr(key);
