import 'package:citaly/core/providers/app_providers.dart';
import 'package:citaly/features/appointments/data/appointments_repository.dart';
import 'package:citaly/features/appointments/domain/appointment.dart';
import 'package:citaly/features/appointments/presentation/widgets/payment_section.dart';
import 'package:citaly/features/business/domain/business.dart';
import 'package:citaly/features/business/presentation/providers/business_providers.dart';
import 'package:citaly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _business = Business(
  id: 'b1',
  name: 'Barbería El Buen Corte',
  slug: 'barberia-el-buen-corte',
  countryCode: 'NI',
  currency: 'NIO',
  timezone: 'America/Managua',
  industry: 'barberia',
);

class _FakeAppointments extends AppointmentsRepository {
  _FakeAppointments()
      : super(
          SupabaseClient(
            'https://proyecto.supabase.co',
            'anon',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        );

  double? paidAmount;
  PaymentMethod? paidMethod;
  String? clearedId;

  @override
  Future<void> registerPayment({
    required String appointmentId,
    required double amount,
    required PaymentMethod method,
  }) async {
    paidAmount = amount;
    paidMethod = method;
  }

  @override
  Future<void> clearPayment(String appointmentId) async {
    clearedId = appointmentId;
  }
}

Appointment _appointment({bool paid = false, double price = 300}) {
  final start = DateTime(2026, 3, 11, 10);
  return Appointment(
    id: 'a1',
    businessId: 'b1',
    clientId: 'c1',
    startsAt: start,
    endsAt: start.add(const Duration(minutes: 30)),
    status: AppointmentStatus.completada,
    clientName: 'Ana Pérez',
    price: price,
    paidAt: paid ? start.add(const Duration(minutes: 45)) : null,
    amountPaid: paid ? price : null,
    paymentMethod: paid ? PaymentMethod.efectivo : null,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Appointment appointment,
  _FakeAppointments repository,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        myBusinessesProvider.overrideWith(
          (ref) => const [BusinessMembership(business: _business, role: 'owner')],
        ),
        appointmentsRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PaymentSection(appointment: appointment),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  testWidgets('registra el pago con el precio precargado y el medio elegido',
      (tester) async {
    final repository = _FakeAppointments();
    await _pump(tester, _appointment(), repository);

    expect(find.text('Sin cobrar'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Registrar pago'));
    await tester.pumpAndSettle();

    final amount = tester.widget<TextField>(find.byType(TextField));
    expect(amount.controller!.text, '300.00');

    await tester.tap(find.widgetWithText(ChoiceChip, 'Tarjeta'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar pago'));
    await tester.pumpAndSettle();

    expect(repository.paidAmount, 300);
    expect(repository.paidMethod, PaymentMethod.tarjeta);
    expect(find.text('Pago registrado.'), findsOneWidget);
  });

  testWidgets('no acepta un importe vacío o en cero', (tester) async {
    final repository = _FakeAppointments();
    await _pump(tester, _appointment(price: 0), repository);

    await tester.tap(find.widgetWithText(FilledButton, 'Registrar pago'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar pago'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa un importe mayor que cero.'), findsOneWidget);
    expect(repository.paidAmount, isNull);
  });

  testWidgets('deshace un cobro ya registrado', (tester) async {
    final repository = _FakeAppointments();
    await _pump(tester, _appointment(paid: true), repository);

    expect(find.text('Cobrada'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Registrar pago'), findsNothing);

    await tester.tap(find.widgetWithText(TextButton, 'Deshacer cobro'));
    await tester.pumpAndSettle();

    expect(repository.clearedId, 'a1');
    expect(find.text('Cobro eliminado.'), findsOneWidget);
  });
}
