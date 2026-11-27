import 'package:turnia/features/business/data/business_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('slugify', () {
    test('convierte acentos y espacios en un slug válido', () {
      expect(slugify('Barbería Don José'), 'barberia-don-jose');
    });

    test('elimina caracteres no permitidos y guiones repetidos', () {
      expect(slugify('  Salón   "Bella"  #1 '), 'salon-bella-1');
    });

    test('nunca devuelve un slug menor a 3 caracteres', () {
      expect(slugify('a'), 'negocio');
    });

    test('limita el largo a 60 caracteres', () {
      final slug = slugify('a' * 100);
      expect(slug.length, lessThanOrEqualTo(60));
    });
  });
}
