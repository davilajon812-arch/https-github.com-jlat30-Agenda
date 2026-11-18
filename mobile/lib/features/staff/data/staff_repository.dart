import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/staff.dart';

/// Empleados, horarios semanales y bloqueos.
class StaffRepository {
  StaffRepository(this._client);

  static const _columns =
      'id, business_id, display_name, phone, color, is_active';

  final SupabaseClient _client;

  Future<List<StaffMember>> list(String businessId) async {
    final rows = await _client
        .from('staff_members')
        .select(_columns)
        .eq('business_id', businessId)
        .eq('is_active', true)
        .order('display_name', ascending: true);

    return rows.map(StaffMember.fromJson).toList(growable: false);
  }

  Future<StaffMember> create({
    required String businessId,
    required String displayName,
    String? phone,
    String color = '#0F766E',
  }) async {
    final row = await _client
        .from('staff_members')
        .insert({
          'business_id': businessId,
          'display_name': displayName.trim(),
          'phone': phone,
          'color': color,
        })
        .select(_columns)
        .single();

    return StaffMember.fromJson(row);
  }

  Future<void> update({
    required String staffId,
    String? displayName,
    String? phone,
    String? color,
    bool? isActive,
  }) async {
    await _client.from('staff_members').update({
      'display_name': ?displayName?.trim(),
      'phone': ?phone,
      'color': ?color,
      'is_active': ?isActive,
    }).eq('id', staffId);
  }

  Future<void> deactivate(String staffId) async {
    await _client
        .from('staff_members')
        .update({'is_active': false}).eq('id', staffId);
  }

  Future<List<ScheduleSlot>> schedule(String staffId) async {
    final rows = await _client
        .from('staff_schedules')
        .select('id, staff_id, weekday, start_time, end_time')
        .eq('staff_id', staffId)
        .eq('is_active', true)
        .order('weekday', ascending: true)
        .order('start_time', ascending: true);

    return rows.map(ScheduleSlot.fromJson).toList(growable: false);
  }

  /// Reemplaza el horario semanal completo del empleado.
  Future<void> replaceSchedule({
    required String businessId,
    required String staffId,
    required List<ScheduleSlot> slots,
  }) async {
    await _client.from('staff_schedules').delete().eq('staff_id', staffId);

    if (slots.isEmpty) return;

    await _client.from('staff_schedules').insert([
      for (final slot in slots)
        {
          'business_id': businessId,
          'staff_id': staffId,
          ...slot.toJson(),
        },
    ]);
  }

  Future<List<StaffBlock>> blocks(String staffId) async {
    final rows = await _client
        .from('staff_blocks')
        .select('id, staff_id, starts_at, ends_at, kind, reason')
        .eq('staff_id', staffId)
        .order('starts_at', ascending: true);

    return rows.map(StaffBlock.fromJson).toList(growable: false);
  }

  Future<void> createBlock({
    required String businessId,
    required String staffId,
    required DateTime startsAt,
    required DateTime endsAt,
    required String kind,
    String? reason,
  }) async {
    await _client.from('staff_blocks').insert({
      'business_id': businessId,
      'staff_id': staffId,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt.toUtc().toIso8601String(),
      'kind': kind,
      'reason': reason,
    });
  }

  Future<void> deleteBlock(String blockId) async {
    await _client.from('staff_blocks').delete().eq('id', blockId);
  }
}
