import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

enum UserType { seeker, provider }

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  UserType _userType = UserType.seeker;

  ThemeMode get themeMode => _themeMode;
  UserType get userType => _userType;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.window.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  ThemeData get lightTheme => _userType == UserType.seeker
      ? AppTheme.seekerLightTheme
      : AppTheme.providerLightTheme;

  ThemeData get darkTheme => _userType == UserType.seeker
      ? AppTheme.seekerDarkTheme
      : AppTheme.providerDarkTheme;

  ThemeProvider() {
    _loadThemePreference();
  }

  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    _saveThemePreference();
    notifyListeners();
  }

  void setUserType(UserType userType) {
    _userType = userType;
    _saveUserTypePreference();
    notifyListeners();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt('themeMode') ?? 0;
    _themeMode = ThemeMode.values[themeModeIndex];

    final userTypeIndex = prefs.getInt('userType') ?? 0;
    _userType = UserType.values[userTypeIndex];

    notifyListeners();
  }

  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', _themeMode.index);
  }

  Future<void> _saveUserTypePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userType', _userType.index);
  }
}
