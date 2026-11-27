import 'package:turnia/features/client_booking/domain/booking_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseBookingSlug', () {
    test('acepta el enlace completo del negocio', () {
      expect(
        parseBookingSlug('https://turnia.app/r/barberia-demo'),
        'barberia-demo',
      );
    });

    test('acepta el enlace con token de seguimiento', () {
      expect(
        parseBookingSlug(
          'https://turnia.app/r/barberia-demo?c=abc123',
        ),
        'barberia-demo',
      );
    });

    test('acepta el código suelto', () {
      expect(parseBookingSlug('  barberia-demo '), 'barberia-demo');
    });

    test('rechaza enlaces que no son de reservas', () {
      expect(parseBookingSlug('https://turnia.app/privacidad'), isNull);
      expect(parseBookingSlug('https://turnia.app'), isNull);
      expect(parseBookingSlug(''), isNull);
      expect(parseBookingSlug('ab'), isNull);
      expect(parseBookingSlug('con espacios'), isNull);
    });
  });

  group('parseBookingToken', () {
    test('extrae el token del enlace', () {
      expect(
        parseBookingToken('https://turnia.app/r/x?c=abc123'),
        'abc123',
      );
    });

    test('sin token devuelve null', () {
      expect(parseBookingToken('https://turnia.app/r/x'), isNull);
      expect(parseBookingToken('barberia-demo'), isNull);
    });
  });

  test('bookingLink arma el enlace sin barras duplicadas', () {
    expect(
      bookingLink('https://turnia.app/', 'mi-barberia'),
      'https://turnia.app/r/mi-barberia',
    );
    expect(
      bookingLink('https://turnia.app', 'mi-barberia'),
      'https://turnia.app/r/mi-barberia',
    );
  });
}
