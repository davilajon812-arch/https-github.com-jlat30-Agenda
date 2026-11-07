import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../business/presentation/providers/business_providers.dart';
import '../domain/appointment.dart';
import './providers/agenda_providers.dart';
import 'new_appointment_sheet.dart';
import 'widgets/appointment_tile.dart';

enum AgendaMode { day, week }

/// Agenda del día y de la semana con el formulario rápido de nueva cita.
class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  AgendaMode _mode = AgendaMode.day;
  DateTime _anchor = DateTime.now();

  ({DateTime from, DateTime to}) _rangeFor(DateTime anchor, AgendaMode mode) {
    final start = DateTime(anchor.year, anchor.month, anchor.day);
    if (mode == AgendaMode.day) {
      return (from: start, to: start.add(const Duration(days: 1)));
    }
    final startOfWeek = start.subtract(Duration(days: anchor.weekday - 1));
    return (from: startOfWeek, to: startOfWeek.add(const Duration(days: 7)));
  }

  void _shift(int days) {
    setState(() => _anchor = _anchor.add(Duration(days: days)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final membership = ref.watch(activeBusinessProvider);

    if (membership == null) {
      return Center(child: Text(l10n.clientsEmpty));
    }

    final range = _rangeFor(_anchor, _mode);
    final query = (
      businessId: membership.business.id,
      from: range.from,
      to: range.to,
    );
    final agenda = ref.watch(agendaProvider(query));

    return Scaffold(
      body: Column(
        children: [
          _AgendaHeader(
            mode: _mode,
            anchor: _anchor,
            onModeChanged: (mode) => setState(() => _mode = mode),
            onPrevious: () => _shift(_mode == AgendaMode.day ? -1 : -7),
            onNext: () => _shift(_mode == AgendaMode.day ? 1 : 7),
            onToday: () => setState(() => _anchor = DateTime.now()),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(agendaProvider(query)),
              child: agenda.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorView(
                  message: l10n.errorGeneric,
                  retryLabel: l10n.commonRetry,
                  onRetry: () => ref.invalidate(agendaProvider(query)),
                ),
                data: (appointments) => appointments.isEmpty
                    ? _EmptyAgenda(mode: _mode)
                    : _AgendaList(appointments: appointments, mode: _mode),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showNewAppointmentSheet(
          context,
          businessId: membership.business.id,
          initialDate: _anchor,
        ),
        icon: const Icon(Icons.add),
        label: Text(l10n.agendaNewAppointment),
      ),
    );
  }
}

class _AgendaHeader extends StatelessWidget {
  const _AgendaHeader({
    required this.mode,
    required this.anchor,
    required this.onModeChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final AgendaMode mode;
  final DateTime anchor;
  final ValueChanged<AgendaMode> onModeChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final theme = Theme.of(context);

    final label = mode == AgendaMode.day
        ? DateFormat('EEE d MMM', locale).format(anchor)
        : DateFormat('d MMM', locale).format(anchor);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        children: [
          SegmentedButton<AgendaMode>(
            segments: [
              ButtonSegment(value: AgendaMode.day, label: Text(l10n.agendaDay)),
              ButtonSegment(
                value: AgendaMode.week,
                label: Text(l10n.agendaWeek),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (value) => onModeChanged(value.first),
            showSelectedIcon: false,
          ),
          Row(
            children: [
              IconButton(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
              TextButton(onPressed: onToday, child: Text(l10n.agendaToday)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgendaList extends StatelessWidget {
  const _AgendaList({required this.appointments, required this.mode});

  final List<Appointment> appointments;
  final AgendaMode mode;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final theme = Theme.of(context);

    if (mode == AgendaMode.day) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 96, top: 4),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return AppointmentTile(
            appointment: appointment,
            onTap: () => context.push('/appointments/${appointment.id}'),
          );
        },
      );
    }

    // Vista semanal: secciones por día.
    final grouped = <DateTime, List<Appointment>>{};
    for (final appointment in appointments) {
      final day = DateTime(
        appointment.startsAt.year,
        appointment.startsAt.month,
        appointment.startsAt.day,
      );
      grouped.putIfAbsent(day, () => []).add(appointment);
    }
    final days = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96, top: 4),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final items = grouped[day]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Text(
                DateFormat('EEEE d MMM', locale).format(day),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final appointment in items)
              AppointmentTile(
                appointment: appointment,
                onTap: () => context.push('/appointments/${appointment.id}'),
              ),
          ],
        );
      },
    );
  }
}

class _EmptyAgenda extends StatelessWidget {
  const _EmptyAgenda({required this.mode});

  final AgendaMode mode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.event_available_outlined,
          size: 56,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          mode == AgendaMode.day ? l10n.agendaEmptyDay : l10n.agendaEmptyWeek,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
