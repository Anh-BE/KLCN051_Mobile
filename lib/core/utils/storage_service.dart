import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/model/user_model.dart';

class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';
  static const String _keySavedUsername = 'saved_username';
  static const String _keyRememberMe = 'remember_me';

  static Future<void> saveLoginData({
    required String token,
    required UserModel user,
    required bool rememberMe,
    String? username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    await prefs.setBool(_keyRememberMe, rememberMe);
    if (rememberMe && username != null) {
      await prefs.setString(_keySavedUsername, username);
    } else {
      await prefs.remove(_keySavedUsername);
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_keyUser);
    if (userStr == null) return null;
    try {
      final Map<String, dynamic> json = jsonDecode(userStr);
      return UserModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static const String _keyLanguage = 'app_language';

  static Future<String?> getSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySavedUsername);
  }

  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? true;
  }

  static const String _keyThemeMode = 'app_theme_mode';

  static Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage);
  }

  static Future<void> setLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, langCode);
  }

  static Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode);
  }

  static Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }

  static const String _keySelectedPeriodId = 'selected_period_id';
  static const String _keySelectedPeriodName = 'selected_period_name';

  static Future<void> setSelectedPeriod({
    required int periodId,
    required String periodName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySelectedPeriodId, periodId);
    await prefs.setString(_keySelectedPeriodName, periodName);
  }

  static Future<int?> getSelectedPeriodId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySelectedPeriodId);
  }

  static Future<String?> getSelectedPeriodName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedPeriodName);
  }

  static Future<void> clearSelectedPeriod() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySelectedPeriodId);
    await prefs.remove(_keySelectedPeriodName);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
    await prefs.remove(_keySelectedPeriodId);
    await prefs.remove(_keySelectedPeriodName);
  }
}
