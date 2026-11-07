import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../domain/service.dart';

/// Servicios activos del negocio.
final servicesProvider =
    FutureProvider.autoDispose.family<List<Service>, String>(
  (ref, businessId) =>
      ref.watch(servicesRepositoryProvider).list(businessId),
);
