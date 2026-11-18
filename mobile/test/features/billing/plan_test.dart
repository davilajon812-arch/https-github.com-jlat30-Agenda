import 'package:agenda_pro/features/billing/domain/plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Plan.fromJson', () {
    test('lee límites y funciones del plan', () {
      final plan = Plan.fromJson({
        'id': 'pro',
        'name': 'Pro',
        'play_product_id': 'agendapro_pro_mensual',
        'max_staff': null,
        'max_locations': null,
        'max_appointments_per_month': null,
        'max_messages_per_month': 1000,
        'features': {'reminders': true, 'advanced_reports': true},
      });

      expect(plan.isPurchasable, isTrue);
      expect(plan.maxStaff, isNull);
      expect(plan.maxAppointmentsPerMonth, isNull);
      expect(plan.feature('reminders'), isTrue);
      expect(plan.feature('advanced_reports'), isTrue);
    });

    test('el plan gratis no es comprable', () {
      final plan = Plan.fromJson({
        'id': 'free',
        'name': 'Gratis',
        'play_product_id': null,
        'features': <String, dynamic>{},
      });

      expect(plan.isPurchasable, isFalse);
    });
  });

  group('Entitlements.fromJson', () {
    test('lee el consumo y los cupos restantes', () {
      final ent = Entitlements.fromJson({
        'business_id': 'b1',
        'plan': {
          'id': 'free',
          'name': 'Gratis',
          'max_staff': 1,
          'max_appointments_per_month': 30,
          'features': <String, dynamic>{},
        },
        'status': 'active',
        'source': 'play',
        'auto_renewing': true,
        'current_period_end': '2027-01-01T00:00:00+00:00',
        'product_id': 'agendapro_pro_mensual',
        'usage': {
          'staff_count': 1,
          'appointments_this_month': 12,
          'messages_this_month': 0,
        },
        'remaining': {
          'staff': 0,
          'appointments_per_month': 18,
          'messages_per_month': 0,
        },
        'upgrade_to': 'pro',
      });

      expect(ent.isPaid, isFalse);
      expect(ent.usage.appointmentsThisMonth, 12);
      expect(ent.remainingOf('appointments_per_month'), 18);
      expect(ent.remainingOf('staff'), 0);
      expect(ent.upgradeTo, 'pro');
      expect(ent.autoRenewing, isTrue);
      expect(ent.currentPeriodEnd, isNotNull);
    });
  });

  group('PlanLimitException', () {
    test('se construye desde el detalle 402 del backend', () {
      final error = PlanLimitException.fromDetail({
        'code': 'plan_limit_reached',
        'limit': 'appointments_per_month',
        'plan': 'free',
        'upgrade_to': 'pro',
        'message': 'Alcanzaste el límite de tu plan actual',
      });

      expect(error.limit, 'appointments_per_month');
      expect(error.upgradeTo, 'pro');
      expect(error.toString(), contains('límite'));
    });
  });
}
