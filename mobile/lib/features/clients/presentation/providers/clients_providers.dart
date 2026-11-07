import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../domain/client.dart';

/// Clientes del negocio, filtrados por el término de búsqueda.
final clientsProvider = FutureProvider.autoDispose
    .family<List<Client>, ({String businessId, String search})>(
  (ref, query) => ref.watch(clientsRepositoryProvider).search(
        businessId: query.businessId,
        term: query.search,
      ),
);

/// Cliente individual.
final clientProvider = FutureProvider.autoDispose.family<Client, String>(
  (ref, clientId) => ref.watch(clientsRepositoryProvider).fetch(clientId),
);
