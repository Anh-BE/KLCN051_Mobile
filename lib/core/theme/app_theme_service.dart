import 'package:flutter/material.dart';
import '../utils/storage_service.dart';

class AppThemeService {
  static final AppThemeService _instance = AppThemeService._internal();
  factory AppThemeService() => _instance;
  AppThemeService._internal();

  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  ThemeMode get currentThemeMode => themeModeNotifier.value;

  bool get isDarkMode {
    if (themeModeNotifier.value == ThemeMode.dark) return true;
    if (themeModeNotifier.value == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  Future<void> init() async {
    final savedMode = await StorageService.getThemeMode();
    if (savedMode == 'dark') {
      themeModeNotifier.value = ThemeMode.dark;
    } else if (savedMode == 'system') {
      themeModeNotifier.value = ThemeMode.system;
    } else {
      themeModeNotifier.value = ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == themeModeNotifier.value) return;
    themeModeNotifier.value = mode;
    final String modeStr = mode == ThemeMode.dark
        ? 'dark'
        : (mode == ThemeMode.system ? 'system' : 'light');
    await StorageService.setThemeMode(modeStr);
  }
}
