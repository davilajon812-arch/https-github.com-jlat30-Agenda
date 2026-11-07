import 'package:agenda_pro/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('usa el flavor dev y el host del emulador por defecto', () {
      final config = AppConfig.fromEnvironment();

      expect(config.flavor, AppFlavor.dev);
      expect(config.isDev, isTrue);
      expect(config.apiBaseUrl, 'http://10.0.2.2:8000');
      expect(config.androidPackageName, 'com.agendapro.agenda_pro');
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
