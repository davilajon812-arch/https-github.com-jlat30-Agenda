import 'package:agenda_pro/core/config/app_config.dart';
import 'package:agenda_pro/core/providers/app_providers.dart';
import 'package:agenda_pro/features/auth/presentation/providers/auth_providers.dart';
import 'package:agenda_pro/features/business/domain/business.dart';
import 'package:agenda_pro/features/business/presentation/providers/business_providers.dart';
import 'package:agenda_pro/features/settings/presentation/settings_screen.dart';
import 'package:agenda_pro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _business = Business(
  id: 'b1',
  name: 'Barbería Demo',
  slug: 'barberia-demo',
  countryCode: 'NI',
  currency: 'NIO',
  timezone: 'America/Managua',
);

Future<Widget> _settingsScreen() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(
        const AppConfig(
          flavor: AppFlavor.prod,
          supabaseUrl: 'https://proyecto.supabase.co',
          supabaseAnonKey: 'anon',
          apiBaseUrl: 'https://api.test',
        ),
      ),
      sharedPreferencesProvider.overrideWithValue(prefs),
      currentUserProvider.overrideWithValue(null),
      myBusinessesProvider.overrideWith(
        (ref) async => const [
          BusinessMembership(business: _business, role: 'owner'),
        ],
      ),
    ],
    child: MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SettingsScreen()),
    ),
  );
}

void main() {
  /// La lista de Ajustes es larga: se usa una pantalla alta para que todos los
  /// azulejos estén montados y sean localizables.
  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('Ajustes ofrece privacidad, términos y eliminar cuenta', (
    tester,
  ) async {
    useTallScreen(tester);
    await tester.pumpWidget(await _settingsScreen());
    await tester.pumpAndSettle();

    expect(find.text('Política de privacidad'), findsOneWidget);
    expect(find.text('Términos del servicio'), findsOneWidget);
    expect(find.text('Eliminar cuenta'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('Eliminar cuenta pide confirmación explícita', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await _settingsScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Eliminar cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar tu cuenta?'), findsOneWidget);
    expect(find.text('Eliminar definitivamente'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);

    // Cancelar no dispara la eliminación.
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar tu cuenta?'), findsNothing);
  });
}
