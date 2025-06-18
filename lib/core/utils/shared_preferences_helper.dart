import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userRoleKey = 'userRole';
  static const String _userIdKey = 'userId';
  static const String _userEmailKey = 'userEmail';
  static const String _onboardingKey = 'showOnboarding';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<Map<String, String?>> getLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'role': prefs.getString(_userRoleKey),
      'userId': prefs.getString(_userIdKey),
      'email': prefs.getString(_userEmailKey),
    };
  }

  static Future<bool> shouldShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? true;
  }

  static Future<void> setLoginState({
    required bool isLoggedIn,
    required String role,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
    await prefs.setString(_userRoleKey, role);
    await prefs.setString(_userIdKey, userId);
  }

  static Future<void> saveLoginState({
    required String userId,
    required String role,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userRoleKey, role);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userEmailKey, email);
  }

  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, false);
  }

  static Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
  }
}
