import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/business/data/business_repository.dart';
import '../config/app_config.dart';

/// Se sobrescribe en `bootstrap.dart` con la configuración real.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider sin configurar'),
);

/// Cliente de Supabase inicializado en `bootstrap.dart`.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => throw UnimplementedError('supabaseClientProvider sin configurar'),
);

/// Preferencias locales (tema e idioma).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider sin configurar'),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

final businessRepositoryProvider = Provider<BusinessRepository>(
  (ref) => BusinessRepository(ref.watch(supabaseClientProvider)),
);
