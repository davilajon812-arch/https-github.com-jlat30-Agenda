import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/appointments/data/appointments_repository.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/billing/data/play_billing.dart';
import '../../features/business/data/business_repository.dart';
import '../../features/clients/data/clients_repository.dart';
import '../../features/services/data/services_repository.dart';
import '../../features/staff/data/staff_repository.dart';
import '../api/agenda_api.dart';
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

final servicesRepositoryProvider = Provider<ServicesRepository>(
  (ref) => ServicesRepository(ref.watch(supabaseClientProvider)),
);

final clientsRepositoryProvider = Provider<ClientsRepository>(
  (ref) => ClientsRepository(ref.watch(supabaseClientProvider)),
);

final staffRepositoryProvider = Provider<StaffRepository>(
  (ref) => StaffRepository(ref.watch(supabaseClientProvider)),
);

final appointmentsRepositoryProvider = Provider<AppointmentsRepository>(
  (ref) => AppointmentsRepository(ref.watch(supabaseClientProvider)),
);

/// Cliente de la API del backend (disponibilidad y reglas de negocio).
final agendaApiProvider = Provider<AgendaApi>((ref) {
  final api = AgendaApi(
    baseUrl: ref.watch(appConfigProvider).apiBaseUrl,
    supabaseClient: ref.watch(supabaseClientProvider),
  );
  ref.onDispose(api.dispose);
  return api;
});

/// Envoltorio de Google Play Billing.
final playBillingProvider = Provider<PlayBilling>((ref) => PlayBilling());
