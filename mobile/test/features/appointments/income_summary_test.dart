import 'package:citaly/features/appointments/domain/appointment.dart';
import 'package:citaly/features/appointments/domain/income.dart';
import 'package:flutter_test/flutter_test.dart';

Appointment _appointment({
  required DateTime startsAt,
  double? price,
  double? amountPaid,
  PaymentMethod? method,
  bool paid = true,
  String? service,
  String? staff,
}) {
  return Appointment(
    id: 'a-${startsAt.toIso8601String()}-${service ?? ''}',
    businessId: 'b1',
    clientId: 'c1',
    startsAt: startsAt,
    endsAt: startsAt.add(const Duration(minutes: 30)),
    status: AppointmentStatus.completada,
    serviceName: service,
    staffName: staff,
    price: price,
    paidAt: paid ? startsAt.add(const Duration(minutes: 40)) : null,
    amountPaid: amountPaid,
    paymentMethod: method,
  );
}

void main() {
  group('IncomeSummary', () {
    test('solo cuenta las citas cobradas', () {
      final summary = IncomeSummary.fromAppointments(
        [
          _appointment(
            startsAt: DateTime(2026, 3, 10, 9),
            amountPaid: 200,
            method: PaymentMethod.efectivo,
          ),
          _appointment(startsAt: DateTime(2026, 3, 10, 11), price: 500, paid: false),
        ],
        from: DateTime(2026, 3, 10),
        to: DateTime(2026, 3, 11),
      );

      expect(summary.count, 1);
      expect(summary.total, 200);
      expect(summary.average, 200);
    });

    test('sin cobros el resumen queda vacío', () {
      final summary = IncomeSummary.fromAppointments(
        const [],
        from: DateTime(2026, 3, 10),
        to: DateTime(2026, 3, 11),
      );

      expect(summary.isEmpty, isTrue);
      expect(summary.total, 0);
      expect(summary.average, 0);
      expect(summary.byDay, isEmpty);
    });

    test('usa el precio cuando no se anotó el importe cobrado', () {
      final summary = IncomeSummary.fromAppointments(
        [_appointment(startsAt: DateTime(2026, 3, 10, 9), price: 350)],
        from: DateTime(2026, 3, 10),
        to: DateTime(2026, 3, 11),
      );

      expect(summary.total, 350);
    });

    test('agrupa por día en orden y por medio, servicio y empleado', () {
      final summary = IncomeSummary.fromAppointments(
        [
          _appointment(
            startsAt: DateTime(2026, 3, 11, 15),
            amountPaid: 100,
            method: PaymentMethod.tarjeta,
            service: 'Corte',
            staff: 'Ana',
          ),
          _appointment(
            startsAt: DateTime(2026, 3, 10, 10),
            amountPaid: 300,
            method: PaymentMethod.efectivo,
            service: 'Corte',
            staff: 'Luis',
          ),
          _appointment(
            startsAt: DateTime(2026, 3, 10, 12),
            amountPaid: 150,
            method: PaymentMethod.efectivo,
            service: 'Barba',
            staff: 'Ana',
          ),
        ],
        from: DateTime(2026, 3, 10),
        to: DateTime(2026, 3, 12),
      );

      expect(summary.total, 550);
      expect(summary.average, closeTo(183.33, 0.01));

      expect(summary.byDay.map((b) => b.key), ['2026-03-10', '2026-03-11']);
      expect(summary.byDay.map((b) => b.amount), [450, 100]);

      expect(summary.byMethod.first.key, 'efectivo');
      expect(summary.byMethod.first.amount, 450);
      expect(summary.byMethod.last.key, 'tarjeta');

      expect(summary.byService.first.key, 'Corte');
      expect(summary.byService.first.amount, 400);
      expect(summary.byService.last.key, 'Barba');

      final byStaff = {
        for (final bucket in summary.byStaff) bucket.key: bucket.amount,
      };
      expect(byStaff['Ana'], 250);
      expect(byStaff['Luis'], 300);
    });
  });

  group('incomeRange', () {
    final now = DateTime(2026, 3, 11, 16, 30); // miércoles

    test('hoy cubre el día completo', () {
      final range = incomeRange(IncomePeriod.hoy, now);
      expect(range.from, DateTime(2026, 3, 11));
      expect(range.to, DateTime(2026, 3, 12));
    });

    test('la semana empieza el lunes', () {
      final range = incomeRange(IncomePeriod.semana, now);
      expect(range.from, DateTime(2026, 3, 9));
      expect(range.to, DateTime(2026, 3, 16));
    });

    test('el mes cubre del día 1 al 1 del mes siguiente', () {
      final range = incomeRange(IncomePeriod.mes, now);
      expect(range.from, DateTime(2026, 3, 1));
      expect(range.to, DateTime(2026, 4, 1));
    });

    test('diciembre avanza al año siguiente', () {
      final range = incomeRange(IncomePeriod.mes, DateTime(2026, 12, 5));
      expect(range.to, DateTime(2027, 1, 1));
    });
  });
}
