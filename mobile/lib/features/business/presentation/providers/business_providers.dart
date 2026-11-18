import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/business.dart';

/// Negocios del usuario; se recarga cuando cambia la sesión.
final myBusinessesProvider = FutureProvider<List<BusinessMembership>>((ref) {
  ref.watch(currentUserProvider);
  return ref.watch(businessRepositoryProvider).fetchMemberships();
});

/// Negocio elegido por el usuario, recordado entre sesiones.
class SelectedBusinessController extends Notifier<String?> {
  static const _storageKey = 'selected_business_id';

  @override
  String? build() => ref.watch(sharedPreferencesProvider).getString(_storageKey);

  Future<void> select(String businessId) async {
    state = businessId;
    await ref.read(sharedPreferencesProvider).setString(_storageKey, businessId);
  }

  Future<void> clear() async {
    state = null;
    await ref.read(sharedPreferencesProvider).remove(_storageKey);
  }
}

final selectedBusinessIdProvider =
    NotifierProvider<SelectedBusinessController, String?>(
  SelectedBusinessController.new,
);

/// Negocio activo: el elegido o, si no hay elección, el primero del usuario.
final activeBusinessProvider = Provider<BusinessMembership?>((ref) {
  final memberships = ref.watch(myBusinessesProvider).value ?? const [];
  if (memberships.isEmpty) return null;

  final selectedId = ref.watch(selectedBusinessIdProvider);
  if (selectedId != null) {
    for (final membership in memberships) {
      if (membership.business.id == selectedId) return membership;
    }
  }
  return memberships.first;
});

/// Verdadero cuando el usuario ya tiene al menos un negocio.
final hasBusinessProvider = Provider<bool>((ref) {
  return ref.watch(activeBusinessProvider) != null;
});

/// Verdadero cuando el usuario pertenece a más de un negocio.
final hasMultipleBusinessesProvider = Provider<bool>((ref) {
  return (ref.watch(myBusinessesProvider).value ?? const []).length > 1;
});
