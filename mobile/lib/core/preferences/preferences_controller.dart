import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

/// Preferencias visuales del usuario persistidas en el dispositivo.
@immutable
class AppPreferences {
  const AppPreferences({this.themeMode = ThemeMode.system, this.localeCode});

  final ThemeMode themeMode;
  final String? localeCode;

  AppPreferences copyWith({ThemeMode? themeMode, String? localeCode}) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
    );
  }
}

class PreferencesController extends Notifier<AppPreferences> {
  static const _themeKey = 'app_theme_mode';
  static const _localeKey = 'app_locale';

  @override
  AppPreferences build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppPreferences(
      themeMode: _decodeTheme(prefs.getString(_themeKey)),
      localeCode: prefs.getString(_localeKey),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await ref
        .read(sharedPreferencesProvider)
        .setString(_themeKey, mode.name);
  }

  Future<void> setLocale(String? localeCode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = AppPreferences(themeMode: state.themeMode, localeCode: localeCode);
    if (localeCode == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, localeCode);
    }
  }

  static ThemeMode _decodeTheme(String? raw) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == raw,
      orElse: () => ThemeMode.system,
    );
  }
}

final preferencesProvider =
    NotifierProvider<PreferencesController, AppPreferences>(
  PreferencesController.new,
);
