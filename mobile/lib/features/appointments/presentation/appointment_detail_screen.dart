import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/l10n/labels.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/whatsapp_launcher.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../business/presentation/providers/business_providers.dart';
import '../domain/appointment.dart';
import './providers/agenda_providers.dart';
import 'widgets/payment_section.dart';
import 'widgets/status_chip.dart';

/// Detalle de una cita con acciones de estado y WhatsApp.
class AppointmentDetailScreen extends ConsumerWidget {
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final appointment = ref.watch(appointmentProvider(appointmentId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appointmentDetailTitle)),
      body: appointment.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: l10n.errorNotFound,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(appointmentProvider(appointmentId)),
        ),
        data: (data) => _AppointmentBody(appointment: data),
      ),
    );
  }
}

class _AppointmentBody extends ConsumerWidget {
  const _AppointmentBody({required this.appointment});

  final Appointment appointment;

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    AppointmentStatus status,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(appointmentsRepositoryProvider)
          .changeStatus(appointment.id, status);
      ref.invalidate(appointmentProvider(appointment.id));
      ref.invalidate(agendaProvider);
      ref.invalidate(clientVisitsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.appointmentUpdated)),
      );
    } on PostgrestException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorSave)),
      );
    }
  }

  Future<void> _openWhatsApp(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final businessName =
        ref.read(activeBusinessProvider)?.business.name ?? l10n.appTitle;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final when = DateFormat("EEE d MMM 'a las' HH:mm", locale)
        .format(appointment.startsAt);

    final message = 'Hola ${appointment.clientName ?? ''}, te recordamos tu cita '
        '${appointment.serviceName != null ? 'de ${appointment.serviceName} ' : ''}'
        'el $when en $businessName. ¡Te esperamos!';

    final opened = await openWhatsApp(
      phone: appointment.whatsappNumber,
      message: message,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneric)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        appointment.clientName ?? l10n.appointmentClient,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    StatusChip(status: appointment.status),
                  ],
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.event,
                  label: l10n.appointmentWhen,
                  value: DateFormat('EEEE d MMM, HH:mm', locale)
                      .format(appointment.startsAt),
                ),
                if (appointment.serviceName != null)
                  _DetailRow(
                    icon: Icons.content_cut,
                    label: l10n.appointmentService,
                    value:
                        '${appointment.serviceName} · ${l10n.commonMinutes(appointment.duration.inMinutes)}',
                  ),
                if (appointment.staffName != null)
                  _DetailRow(
                    icon: Icons.person_outline,
                    label: l10n.appointmentStaff,
                    value: appointment.staffName!,
                  ),
                if (appointment.price != null)
                  _DetailRow(
                    icon: Icons.payments_outlined,
                    label: l10n.appointmentPrice,
                    value: appointment.price!.toStringAsFixed(2),
                  ),
                if (appointment.notes != null &&
                    appointment.notes!.trim().isNotEmpty)
                  _DetailRow(
                    icon: Icons.notes,
                    label: l10n.appointmentNotes,
                    value: appointment.notes!,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (appointment.status != AppointmentStatus.cancelada ||
            appointment.isPaid) ...[
          PaymentSection(appointment: appointment),
          const SizedBox(height: 12),
        ],
        FilledButton.tonalIcon(
          onPressed: appointment.whatsappNumber.isEmpty
              ? null
              : () => _openWhatsApp(context, ref),
          icon: const Icon(Icons.chat_bubble_outline),
          label: Text(l10n.agendaWhatsapp),
        ),
        const SizedBox(height: 24),
        Text(l10n.appointmentChangeStatus, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (appointment.status == AppointmentStatus.pendiente)
          _ActionTile(
            icon: Icons.check_circle_outline,
            label: l10n.appointmentConfirm,
            onTap: () =>
                _setStatus(context, ref, AppointmentStatus.confirmada),
          ),
        if (appointment.status == AppointmentStatus.confirmada)
          _ActionTile(
            icon: Icons.task_alt,
            label: l10n.appointmentComplete,
            onTap: () => _setStatus(context, ref, AppointmentStatus.completada),
          ),
        if (appointment.status.isActive) ...[
          _ActionTile(
            icon: Icons.person_off_outlined,
            label: l10n.appointmentNoShow,
            onTap: () => _setStatus(context, ref, AppointmentStatus.noAsistio),
          ),
          _ActionTile(
            icon: Icons.cancel_outlined,
            label: l10n.appointmentCancel,
            isDestructive: true,
            onTap: () => _setStatus(context, ref, AppointmentStatus.cancelada),
          ),
        ],
        if (appointment.status.isFinal)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              appointment.status.label(l10n),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isDestructive ? scheme.error : scheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
