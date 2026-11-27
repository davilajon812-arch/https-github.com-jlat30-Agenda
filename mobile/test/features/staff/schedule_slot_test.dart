import 'package:citurno/core/l10n/labels.dart';
import 'package:citurno/features/staff/domain/staff.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers.dart';

void main() {
  group('TimeOfDayJson', () {
    test('interpreta HH:mm y HH:mm:ss', () {
      expect(TimeOfDayJson.parse('09:30').label, '09:30');
      expect(TimeOfDayJson.parse('18:00:00').label, '18:00');
    });

    test('se envia a Postgres como HH:mm:ss', () {
      expect(const TimeOfDayJson(8, 5).toHms(), '08:05:00');
    });

    test('compara por minutos del dia', () {
      expect(
        const TimeOfDayJson(9, 0).compareTo(const TimeOfDayJson(10, 0)),
        lessThan(0),
      );
      expect(
        const TimeOfDayJson(9, 0) == TimeOfDayJson.parse('09:00'),
        isTrue,
      );
    });
  });

  group('weekdaySundayZero', () {
    test('el domingo es 0 y el lunes es 1', () {
      expect(weekdaySundayZero(DateTime(2027, 3, 14)), 0);
      expect(weekdaySundayZero(DateTime(2027, 3, 15)), 1);
      expect(weekdaySundayZero(DateTime(2027, 3, 20)), 6);
    });
  });

  group('weekdayLabel', () {
    test('devuelve el nombre en espanol', () {
      final l10n = spanishLocalizations();

      expect(weekdayLabel(l10n, 1), 'Lunes');
      expect(weekdayLabel(l10n, 6), 'Sábado');
    });
  });

  group('ScheduleSlot.fromJson', () {
    test('lee el horario de Supabase', () {
      final slot = ScheduleSlot.fromJson({
        'id': 'x1',
        'weekday': 4,
        'start_time': '09:00:00',
        'end_time': '18:00:00',
      });

      expect(slot.weekday, 4);
      expect(slot.startTime.label, '09:00');
      expect(slot.endTime.label, '18:00');
      expect(slot.toJson()['start_time'], '09:00:00');
    });
  });
}
