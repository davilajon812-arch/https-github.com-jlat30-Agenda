import '../../features/appointments/domain/appointment.dart';
import '../../l10n/app_localizations.dart';

/// Nombres traducidos de estados y días de la semana.
extension AppointmentStatusLabels on AppointmentStatus {
  String label(AppLocalizations l10n) => switch (this) {
        AppointmentStatus.pendiente => l10n.statusPendiente,
        AppointmentStatus.confirmada => l10n.statusConfirmada,
        AppointmentStatus.completada => l10n.statusCompletada,
        AppointmentStatus.cancelada => l10n.statusCancelada,
        AppointmentStatus.noAsistio => l10n.statusNoAsistio,
      };
}

/// 0 = domingo … 6 = sábado (igual que `staff_schedules.weekday`).
String weekdayLabel(AppLocalizations l10n, int weekday) => switch (weekday) {
      0 => l10n.weekdaySunday,
      1 => l10n.weekdayMonday,
      2 => l10n.weekdayTuesday,
      3 => l10n.weekdayWednesday,
      4 => l10n.weekdayThursday,
      5 => l10n.weekdayFriday,
      _ => l10n.weekdaySaturday,
    };

/// Día de la semana en formato 0 = domingo para una fecha dada.
int weekdaySundayZero(DateTime date) => date.weekday % 7;
