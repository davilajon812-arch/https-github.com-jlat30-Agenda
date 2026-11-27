import 'package:citaly/core/config/app_config.dart';
import 'package:citaly/core/providers/app_providers.dart';
import 'package:citaly/features/auth/presentation/providers/auth_providers.dart';
import 'package:citaly/features/billing/domain/plan.dart';
import 'package:citaly/features/billing/presentation/providers/billing_providers.dart';
import 'package:citaly/features/business/domain/business.dart';
import 'package:citaly/features/business/presentation/business_manage_screen.dart';
import 'package:citaly/features/business/presentation/providers/business_providers.dart';
import 'package:citaly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _barberia = Business(
  id: 'b1',
  name: 'Barbería El Buen Corte',
  slug: 'barberia-el-buen-corte',
  countryCode: 'NI',
  currency: 'NIO',
  timezone: 'America/Managua',
  industry: 'barberia',
  phone: '50588880000',
);

const _salon = Business(
  id: 'b2',
  name: 'Salón Aurora',
  slug: 'salon-aurora',
  countryCode: 'NI',
  currency: 'NIO',
  timezone: 'America/Managua',
  industry: 'salon_belleza',
);

const _memberships = [
  BusinessMembership(business: _barberia, role: 'owner'),
  BusinessMembership(business: _salon, role: 'owner'),
];

Entitlements _entitlements(String planId) {
  final free = planId == 'free';
  return Entitlements.fromJson({
    'business_id': 'b1',
    'plan': {
      'id': planId,
      'name': free ? 'Gratis' : 'Pro',
      'max_staff': free ? 1 : null,
      'max_appointments_per_month': free ? 30 : null,
      'features': <String, dynamic>{},
    },
    'status': 'active',
    'source': 'manual',
    'auto_renewing': false,
    'current_period_end': null,
    'product_id': null,
    'usage': {
      'staff_count': 1,
      'appointments_this_month': 0,
      'messages_this_month': 0,
    },
    'remaining': {
      'staff': free ? 0 : null,
      'appointments_per_month': free ? 30 : null,
      'messages_per_month': 0,
    },
    'upgrade_to': free ? 'pro' : null,
  });
}

Future<Widget> _app({
  List<BusinessMembership> memberships = _memberships,
  String? selectedId,
  Entitlements? entitlements,
}) async {
  SharedPreferences.setMockInitialValues({
    'selected_business_id': ?selectedId,
  });
  final prefs = await SharedPreferences.getInstance();

  final router = GoRouter(
    initialLocation: '/business',
    routes: [
      GoRoute(
        path: '/business',
        builder: (context, state) => const BusinessManageScreen(),
      ),
      GoRoute(
        path: '/plan',
        builder: (context, state) => const Scaffold(body: Text('PLANES')),
      ),
    ],
  );
  addTearDown(router.dispose);

  final plan = entitlements;
  final entitlementsOverride = plan == null
      ? null
      : entitelementsProvider.overrideWith((ref) async => plan);

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appConfigProvider.overrideWithValue(
        const AppConfig(
          flavor: AppFlavor.prod,
          supabaseUrl: 'https://proyecto.supabase.co',
          supabaseAnonKey: 'anon',
          apiBaseUrl: 'https://api.test',
        ),
      ),
      currentUserProvider.overrideWithValue(null),
      myBusinessesProvider.overrideWith((ref) async => memberships),
      ?entitlementsOverride,
    ],
    child: MaterialApp.router(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  group('negocio activo', () {
    test('sin elección usa el primero del usuario', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          myBusinessesProvider.overrideWith((ref) async => _memberships),
        ],
      );
      addTearDown(container.dispose);

      await container.read(myBusinessesProvider.future);

      expect(container.read(activeBusinessProvider)?.business.id, 'b1');
    });

    test('respeta el negocio seleccionado y lo recuerda', () async {
      SharedPreferences.setMockInitialValues({'selected_business_id': 'b2'});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          myBusinessesProvider.overrideWith((ref) async => _memberships),
        ],
      );
      addTearDown(container.dispose);

      await container.read(myBusinessesProvider.future);
      expect(container.read(activeBusinessProvider)?.business.id, 'b2');

      await container.read(selectedBusinessIdProvider.notifier).select('b1');

      expect(container.read(activeBusinessProvider)?.business.id, 'b1');
      expect(prefs.getString('selected_business_id'), 'b1');
    });

    test('si el negocio guardado ya no existe vuelve al primero', () async {
      SharedPreferences.setMockInitialValues({
        'selected_business_id': 'negocio-borrado',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          myBusinessesProvider.overrideWith((ref) async => _memberships),
        ],
      );
      addTearDown(container.dispose);

      await container.read(myBusinessesProvider.future);

      expect(container.read(activeBusinessProvider)?.business.id, 'b1');
      expect(container.read(hasMultipleBusinessesProvider), isTrue);
    });
  });

  group('pantalla Mi negocio', () {
    testWidgets('con varios negocios muestra el selector', (tester) async {
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();

      expect(find.text('Tus negocios'), findsOneWidget);
      // El negocio activo aparece en el selector y en el resumen.
      expect(find.text('Barbería El Buen Corte'), findsNWidgets(2));
      expect(find.text('Salón Aurora'), findsOneWidget);
      expect(find.text('Editar datos'), findsOneWidget);
      expect(find.text('Agregar negocio'), findsOneWidget);
    });

    testWidgets('con un solo negocio no muestra el selector', (tester) async {
      await tester.pumpWidget(
        await _app(
          memberships: const [BusinessMembership(business: _barberia, role: 'owner')],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tus negocios'), findsNothing);
      expect(find.text('Barbería El Buen Corte'), findsOneWidget);
    });

    testWidgets('editar abre el formulario con los datos actuales', (
      tester,
    ) async {
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Editar datos'));
      await tester.pumpAndSettle();

      expect(find.text('Datos del negocio'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);
      // El nombre viene precargado.
      expect(
        find.widgetWithText(TextFormField, 'Barbería El Buen Corte'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, '50588880000'),
        findsOneWidget,
      );
    });

    testWidgets('agregar negocio en plan Gratis pide Pro', (tester) async {
      await tester.pumpWidget(
        await _app(entitlements: _entitlements('free')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Agregar negocio'));
      await tester.pumpAndSettle();

      expect(find.text('Necesitas el plan Pro'), findsOneWidget);
      expect(find.text('Ver planes'), findsOneWidget);

      await tester.tap(find.text('Ver planes'));
      await tester.pumpAndSettle();

      expect(find.text('PLANES'), findsOneWidget);
    });

    testWidgets('agregar negocio en Pro abre el formulario vacío', (
      tester,
    ) async {
      await tester.pumpWidget(
        await _app(entitlements: _entitlements('pro')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Agregar negocio'));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo negocio'), findsOneWidget);
      expect(find.text('Crear negocio'), findsOneWidget);
    });
  });
}
