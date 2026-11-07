import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/business.dart';

/// Negocios del usuario; se recarga cuando cambia la sesión.
final myBusinessesProvider = FutureProvider<List<BusinessMembership>>((ref) {
  ref.watch(currentUserProvider);
  return ref.watch(businessRepositoryProvider).fetchMemberships();
});

/// Negocio activo (el primero del usuario mientras no haya selector).
final activeBusinessProvider = Provider<BusinessMembership?>((ref) {
  final memberships = ref.watch(myBusinessesProvider).value;
  if (memberships == null || memberships.isEmpty) return null;
  return memberships.first;
});

/// Verdadero cuando el usuario ya tiene al menos un negocio.
final hasBusinessProvider = Provider<bool>((ref) {
  return ref.watch(activeBusinessProvider) != null;
});
