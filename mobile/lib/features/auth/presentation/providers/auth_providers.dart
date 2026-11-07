import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/app_providers.dart';

/// Sesión actual: emite el valor inicial y luego cada cambio de Auth.
final sessionProvider = StreamProvider<Session?>((ref) async* {
  final auth = ref.watch(supabaseClientProvider).auth;
  yield auth.currentSession;
  yield* auth.onAuthStateChange.map((state) => state.session);
});

/// Usuario autenticado (o `null` si no hay sesión).
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(sessionProvider).value?.user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
