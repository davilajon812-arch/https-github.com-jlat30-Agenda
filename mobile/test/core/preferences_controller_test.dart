import 'package:turnia/core/preferences/preferences_controller.dart';
import 'package:turnia/core/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProviderContainer> buildContainer() async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('el tema inicia en modo sistema', () async {
    final container = await buildContainer();

    expect(container.read(preferencesProvider).themeMode, ThemeMode.system);
    expect(container.read(preferencesProvider).localeCode, isNull);
  });

  test('guarda el tema oscuro en las preferencias', () async {
    final container = await buildContainer();

    await container
        .read(preferencesProvider.notifier)
        .setThemeMode(ThemeMode.dark);

    expect(container.read(preferencesProvider).themeMode, ThemeMode.dark);
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getString('app_theme_mode'), 'dark');
  });

  test('guarda y limpia el idioma', () async {
    final container = await buildContainer();

    await container.read(preferencesProvider.notifier).setLocale('en');
    expect(container.read(preferencesProvider).localeCode, 'en');

    await container.read(preferencesProvider.notifier).setLocale(null);
    expect(container.read(preferencesProvider).localeCode, isNull);
  });
}
