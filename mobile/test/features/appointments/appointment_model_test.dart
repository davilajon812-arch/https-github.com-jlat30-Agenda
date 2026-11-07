import 'package:agenda_pro/features/appointments/domain/appointment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Appointment.fromJson', () {
    final json = {
      'id': 'a1',
      'business_id': 'b1',
      'client_id': 'c1',
      'clients': {'full_name': 'Cliente Uno', 'phone': '50588880000'},
      'service_id': 's1',
      'services': {'name': 'Corte'},
      'staff_id': 'st1',
      'staff_members': {'display_name': 'Carlos'},
      'starts_at': '2027-03-15T15:00:00Z',
      'ends_at': '2027-03-15T15:30:00Z',
      'status': 'pendiente',
      'price': 150,
      'notes': null,
    };

    test('lee los datos de la cita con sus relaciones', () {
      final appointment = Appointment.fromJson(json);

      expect(appointment.clientName, 'Cliente Uno');
      expect(appointment.serviceName, 'Corte');
      expect(appointment.staffName, 'Carlos');
      expect(appointment.status, AppointmentStatus.pendiente);
      expect(appointment.price, 150);
    });

    test('convierte las fechas UTC a la hora local', () {
      final appointment = Appointment.fromJson(json);

      expect(appointment.startsAt.isUtc, isFalse);
      expect(appointment.endsAt.difference(appointment.startsAt).inMinutes, 30);
    });

    test('normaliza el teléfono para wa.me', () {
      final appointment = Appointment.fromJson(json);

      expect(appointment.whatsappNumber, '50588880000');
    });
  });

  group('AppointmentStatus', () {
    test('traduce los códigos de la base de datos', () {
      expect(
        AppointmentStatus.fromCode('no_asistio'),
        AppointmentStatus.noAsistio,
      );
      expect(
        AppointmentStatus.fromCode('desconocido'),
        AppointmentStatus.pendiente,
      );
    });

    test('cancelada y no asistio liberan el horario', () {
      expect(AppointmentStatus.cancelada.isActive, isFalse);
      expect(AppointmentStatus.noAsistio.isActive, isFalse);
      expect(AppointmentStatus.confirmada.isActive, isTrue);
      expect(AppointmentStatus.completada.isFinal, isTrue);
    });
  });
}
