import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

class SettingsState {
  final Locale locale;
  final bool isDarkMode;

  const SettingsState({
    this.locale = const Locale('fr'),
    this.isDarkMode = true,
  });

  SettingsState copyWith({Locale? locale, bool? isDarkMode}) {
    return SettingsState(
      locale: locale ?? this.locale,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(AppConstants.prefLocale) ?? 'fr';
    final darkMode = prefs.getBool(AppConstants.prefDarkMode) ?? true;
    state = state.copyWith(
      locale: Locale(localeCode),
      isDarkMode: darkMode,
    );
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLocale, locale.languageCode);
    state = state.copyWith(locale: locale);
  }

  Future<void> toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !state.isDarkMode;
    await prefs.setBool(AppConstants.prefDarkMode, newValue);
    state = state.copyWith(isDarkMode: newValue);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
