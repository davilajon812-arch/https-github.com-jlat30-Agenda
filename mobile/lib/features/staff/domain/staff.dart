/// Empleado que atiende citas.
class StaffMember {
  const StaffMember({
    required this.id,
    required this.businessId,
    required this.displayName,
    this.phone,
    this.color = '#0F766E',
    this.isActive = true,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      displayName: json['display_name'] as String,
      phone: json['phone'] as String?,
      color: json['color'] as String? ?? '#0F766E',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  final String id;
  final String businessId;
  final String displayName;
  final String? phone;
  final String color;
  final bool isActive;
}

/// Franja del horario semanal (weekday: 0 = domingo … 6 = sábado).
class ScheduleSlot {
  const ScheduleSlot({
    required this.weekday,
    required this.startTime,
    required this.endTime,
    this.id,
  });

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) {
    return ScheduleSlot(
      id: json['id'] as String?,
      weekday: (json['weekday'] as num).toInt(),
      startTime: TimeOfDayJson.parse(json['start_time'] as String),
      endTime: TimeOfDayJson.parse(json['end_time'] as String),
    );
  }

  final String? id;
  final int weekday;
  final TimeOfDayJson startTime;
  final TimeOfDayJson endTime;

  Map<String, dynamic> toJson() => {
        'weekday': weekday,
        'start_time': startTime.toHms(),
        'end_time': endTime.toHms(),
      };
}

/// Bloqueo de agenda (vacaciones, descanso, ausencia puntual).
class StaffBlock {
  const StaffBlock({
    required this.id,
    required this.staffId,
    required this.startsAt,
    required this.endsAt,
    required this.kind,
    this.reason,
  });

  factory StaffBlock.fromJson(Map<String, dynamic> json) {
    return StaffBlock(
      id: json['id'] as String,
      staffId: json['staff_id'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
      endsAt: DateTime.parse(json['ends_at'] as String).toLocal(),
      kind: json['kind'] as String? ?? 'bloqueo',
      reason: json['reason'] as String?,
    );
  }

  final String id;
  final String staffId;
  final DateTime startsAt;
  final DateTime endsAt;
  final String kind;
  final String? reason;
}

/// Hora del día en formato `HH:mm` (se envía como `HH:mm:ss` a Postgres).
class TimeOfDayJson implements Comparable<TimeOfDayJson> {
  const TimeOfDayJson(this.hour, this.minute);

  factory TimeOfDayJson.parse(String value) {
    final parts = value.split(':');
    return TimeOfDayJson(
      int.parse(parts[0]),
      parts.length > 1 ? int.parse(parts[1]) : 0,
    );
  }

  final int hour;
  final int minute;

  int get minutesOfDay => hour * 60 + minute;

  String get label =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String toHms() => '$label:00';

  @override
  int compareTo(TimeOfDayJson other) =>
      minutesOfDay.compareTo(other.minutesOfDay);

  @override
  bool operator ==(Object other) =>
      other is TimeOfDayJson && other.minutesOfDay == minutesOfDay;

  @override
  int get hashCode => minutesOfDay.hashCode;
}
