import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../domain/staff.dart';

/// Empleados activos del negocio.
final staffProvider =
    FutureProvider.autoDispose.family<List<StaffMember>, String>(
  (ref, businessId) => ref.watch(staffRepositoryProvider).list(businessId),
);

/// Horario semanal de un empleado.
final staffScheduleProvider =
    FutureProvider.autoDispose.family<List<ScheduleSlot>, String>(
  (ref, staffId) => ref.watch(staffRepositoryProvider).schedule(staffId),
);

/// Bloqueos (vacaciones y descansos) de un empleado.
final staffBlocksProvider =
    FutureProvider.autoDispose.family<List<StaffBlock>, String>(
  (ref, staffId) => ref.watch(staffRepositoryProvider).blocks(staffId),
);
