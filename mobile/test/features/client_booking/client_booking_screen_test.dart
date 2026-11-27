import 'package:citaly/core/config/app_config.dart';
import 'package:citaly/core/providers/app_providers.dart';
import 'package:citaly/features/client_booking/presentation/client_booking_screen.dart';
import 'package:citaly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Future<bool> Function(Uri) openLink,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPreferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        appConfigProvider.overrideWithValue(
          const AppConfig(
            flavor: AppFlavor.dev,
            supabaseUrl: 'https://proyecto.supabase.co',
            supabaseAnonKey: 'anon',
            apiBaseUrl: 'https://api.test',
          ),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ClientBookingScreen(openLink: openLink),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('abre el enlace completo que pegó el cliente', (tester) async {
    Uri? opened;
    await _pump(
      tester,
      openLink: (uri) async {
        opened = uri;
        return true;
      },
    );

    await tester.enterText(
      find.byType(TextField),
      'https://citaly.app/r/barberia-demo',
    );
    await tester.tap(find.text('Abrir reservas'));
    await tester.pumpAndSettle();

    expect(opened, Uri.parse('https://citaly.app/r/barberia-demo'));
    expect(find.text('Última reserva'), findsOneWidget);
  });

  testWidgets('con un código suelto arma el enlace del host configurado',
      (tester) async {
    Uri? opened;
    await _pump(
      tester,
      openLink: (uri) async {
        opened = uri;
        return true;
      },
    );

    await tester.enterText(find.byType(TextField), 'barberia-demo');
    await tester.tap(find.text('Abrir reservas'));
    await tester.pumpAndSettle();

    expect(opened, Uri.parse('https://api.test/r/barberia-demo'));
  });

  testWidgets('conserva el token al abrir un enlace suelto', (tester) async {
    Uri? opened;
    await _pump(
      tester,
      openLink: (uri) async {
        opened = uri;
        return true;
      },
    );

    await tester.enterText(
      find.byType(TextField),
      'https://citaly.app/r/barberia-demo?c=abc123',
    );
    await tester.tap(find.text('Abrir reservas'));
    await tester.pumpAndSettle();

    expect(opened!.queryParameters['c'], 'abc123');
  });

  testWidgets('avisa cuando el texto no parece un enlace de reservas',
      (tester) async {
    var calls = 0;
    await _pump(
      tester,
      openLink: (uri) async {
        calls += 1;
        return true;
      },
    );

    await tester.enterText(
      find.byType(TextField),
      'https://citaly.app/privacidad',
    );
    await tester.tap(find.text('Abrir reservas'));
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(
      find.text('Ese enlace no parece de reservas. Pídele al negocio el suyo.'),
      findsOneWidget,
    );

    // Un código suelto con espacios tampoco es válido.
    await tester.enterText(find.byType(TextField), 'mi barberia');
    await tester.tap(find.text('Abrir reservas'));
    await tester.pumpAndSettle();

    expect(calls, 0);
  });

  testWidgets('muestra la última reserva guardada', (tester) async {
    await _pump(
      tester,
      openLink: (uri) async => true,
      prefs: {
        ClientBookingScreen.lastLinkKey:
            'https://citaly.app/r/barberia-demo?c=abc123',
      },
    );

    expect(find.text('Última reserva'), findsOneWidget);
    expect(find.text('/r/barberia-demo'), findsOneWidget);
  });
}
