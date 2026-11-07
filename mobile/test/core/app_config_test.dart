import 'package:agenda_pro/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('usa el flavor dev por defecto', () {
      final config = AppConfig.fromEnvironment();

      expect(config.flavor, AppFlavor.dev);
      expect(config.isDev, isTrue);
      expect(config.apiBaseUrl, 'http://localhost:8000');
    });

    test('sin variables de compilación Supabase no está configurado', () {
      final config = AppConfig.fromEnvironment();

      expect(config.supabaseUrl, isEmpty);
      expect(config.isSupabaseConfigured, isFalse);
    });

    test('respeta el flavor indicado explícitamente', () {
      final config = AppConfig.fromEnvironment(defaultFlavor: AppFlavor.prod);

      expect(config.flavor, AppFlavor.prod);
      expect(config.isDev, isFalse);
    });
  });
}
