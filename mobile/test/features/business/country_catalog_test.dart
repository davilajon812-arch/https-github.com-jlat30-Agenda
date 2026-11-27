import 'package:citaly/features/business/presentation/widgets/onboarding_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('catálogo de países', () {
    test('los códigos son únicos y de dos letras', () {
      final codes = countries.map((c) => c.code).toList();
      expect(codes.toSet().length, codes.length);
      for (final code in codes) {
        expect(RegExp(r'^[A-Z]{2}$').hasMatch(code), isTrue,
            reason: '$code no es un código ISO de país');
      }
    });

    test('cada país trae moneda, prefijo y zona válidos', () {
      for (final country in countries) {
        expect(country.name.trim(), isNotEmpty);
        expect(RegExp(r'^[A-Z]{3}$').hasMatch(country.currency), isTrue,
            reason: '${country.code} tiene moneda inválida');
        expect(RegExp(r'^[0-9]{1,4}$').hasMatch(country.dialCode), isTrue,
            reason: '${country.code} tiene prefijo inválido');
        for (final zone in country.allTimezones) {
          expect(
            RegExp(r'^[A-Za-z]+/[A-Za-z_]+(/[A-Za-z_]+)?$').hasMatch(zone),
            isTrue,
            reason: '${country.code} tiene la zona inválida "$zone"',
          );
        }
      }
    });

    test('incluye los mercados hispanohablantes de Sudamérica', () {
      final codes = countries.map((c) => c.code).toSet();
      expect(
        codes,
        containsAll(<String>['AR', 'CL', 'EC', 'BO', 'PY', 'UY', 'VE', 'PR']),
      );
    });

    test('los países con varias zonas las declaran', () {
      final mexico = countryByCode('MX');
      expect(mexico.allTimezones, contains('America/Tijuana'));

      final chile = countryByCode('CL');
      expect(chile.allTimezones, contains('Pacific/Easter'));

      final ecuador = countryByCode('EC');
      expect(ecuador.allTimezones, contains('Pacific/Galapagos'));
    });

    test('un código desconocido cae en Nicaragua', () {
      expect(countryByCode('ZZ').code, 'NI');
    });
  });

  group('listas derivadas', () {
    test('las monedas cubren todos los países sin repetirse', () {
      final distinct = countries.map((c) => c.currency).toSet();
      expect(currencies.toSet(), distinct);
      expect(currencies.length, distinct.length);
    });

    test('las zonas cubren todos los países sin repetirse', () {
      final distinct = {
        for (final country in countries) ...country.allTimezones,
      };
      expect(timezones.toSet(), distinct);
      expect(timezones.length, distinct.length);
    });

    test('la zona principal de cada país está en la lista', () {
      for (final country in countries) {
        expect(timezones, contains(country.timezone));
      }
    });
  });
}
