import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/agenda_api.dart';
import '../../../core/providers/app_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../billing/domain/plan.dart';
import '../../billing/presentation/widgets/plan_limit_dialog.dart';
import '../../clients/domain/client.dart';
import '../../clients/presentation/providers/clients_providers.dart';
import '../../clients/presentation/widgets/client_form_sheet.dart';
import '../../services/domain/service.dart';
import '../../services/presentation/providers/services_providers.dart';
import '../../staff/domain/staff.dart';
import '../../staff/presentation/providers/staff_providers.dart';
import './providers/agenda_providers.dart';

/// Abre el formulario rápido de nueva cita (cliente → servicio → horario).
Future<void> showNewAppointmentSheet(
  BuildContext context, {
  required String businessId,
  required DateTime initialDate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // La hoja puede crecer hasta pantalla completa: sin esto el título queda
    // debajo de la barra de estado.
    useSafeArea: true,
    builder: (_) => NewAppointmentSheet(
      businessId: businessId,
      initialDate: initialDate,
    ),
  );
}

class NewAppointmentSheet extends ConsumerStatefulWidget {
  const NewAppointmentSheet({
    super.key,
    required this.businessId,
    required this.initialDate,
  });

  final String businessId;
  final DateTime initialDate;

  @override
  ConsumerState<NewAppointmentSheet> createState() => _NewAppointmentSheetState();
}

class _NewAppointmentSheetState extends ConsumerState<NewAppointmentSheet> {
  Client? _client;
  Service? _service;
  String? _staffId;
  late DateTime _date;
  ({String staffId, DateTime startsAt})? _slot;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _slot = null;
      });
    }
  }

  Future<void> _createClient() async {
    final created = await ClientFormSheet.show(
      context,
      businessId: widget.businessId,
    );
    if (created != null) {
      setState(() => _client = created);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_client == null || _service == null || _slot == null) {
      setState(() => _error = l10n.validationRequired);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(agendaApiProvider).createAppointment(
            businessId: widget.businessId,
            clientId: _client!.id,
            serviceId: _service!.id,
            staffId: _slot!.staffId,
            startsAt: _slot!.startsAt,
            price: _service!.price,
          );

      if (!mounted) return;
      ref.invalidate(agendaProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.newAppointmentCreated)),
      );
    } on PlanLimitException catch (error) {
      if (!mounted) return;
      Navigator.of(context).pop();
      await showPlanLimitDialog(context, error);
    } on AgendaApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.statusCode == 409 ? l10n.errorConflict : error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.errorSave);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final clients = ref.watch(
      clientsProvider((businessId: widget.businessId, search: '')),
    );
    final services = ref.watch(servicesProvider(widget.businessId));
    final staff = ref.watch(staffProvider(widget.businessId));

    final availabilityQuery = _service == null
        ? null
        : (
            businessId: widget.businessId,
            serviceId: _service!.id,
            date: _date,
            staffId: _staffId,
          );
    final availability = availabilityQuery == null
        ? null
        : ref.watch(availabilityProvider(availabilityQuery));

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.newAppointmentTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // 1. Cliente
            _SectionLabel(text: l10n.newAppointmentClient),
            clients.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Text(l10n.errorGeneric),
              data: (items) => Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _client?.id,
                      isExpanded: true,
                      decoration: const InputDecoration(),
                      hint: Text(l10n.appointmentClient),
                      items: [
                        for (final client in items)
                          DropdownMenuItem(
                            value: client.id,
                            child: Text(
                              client.fullName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        _client = items.firstWhere((c) => c.id == value);
                      }),
                    ),
                  ),
                  IconButton(
                    onPressed: _createClient,
                    icon: const Icon(Icons.person_add_alt),
                    tooltip: l10n.newClientInline,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Servicio y empleado
            _SectionLabel(text: l10n.newAppointmentService),
            services.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Text(l10n.errorGeneric),
              data: (items) => DropdownButtonFormField<String>(
                initialValue: _service?.id,
                isExpanded: true,
                hint: Text(l10n.appointmentService),
                items: [
                  for (final service in items)
                    DropdownMenuItem(
                      value: service.id,
                      child: Text(
                        '${service.name} · ${l10n.commonMinutes(service.durationMinutes)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _service = items.firstWhere((s) => s.id == value);
                  _slot = null;
                }),
              ),
            ),
            const SizedBox(height: 12),
            staff.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (items) => DropdownButtonFormField<String?>(
                initialValue: _staffId,
                isExpanded: true,
                hint: Text(l10n.newAppointmentAnyStaff),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.newAppointmentAnyStaff),
                  ),
                  for (final StaffMember member in items)
                    DropdownMenuItem<String?>(
                      value: member.id,
                      child: Text(member.displayName),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _staffId = value;
                  _slot = null;
                }),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Horario libre (calculado por el backend)
            _SectionLabel(text: l10n.newAppointmentSlot),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(DateFormat('EEE d MMM', locale).format(_date)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (availabilityQuery == null)
              Text(
                l10n.newAppointmentNeedService,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              availability!.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Text(
                  error is AgendaApiException ? l10n.errorBackend : l10n.errorGeneric,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                data: (day) => day.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          l10n.newAppointmentNoSlots,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final entry in day.staff)
                            if (entry.slots.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 4),
                                child: Text(
                                  entry.staffName,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final slot in entry.slots)
                                    ChoiceChip(
                                      label: Text(
                                        DateFormat.Hm(locale)
                                            .format(slot.startsAt),
                                      ),
                                      selected: _slot?.startsAt
                                              .isAtSameMomentAs(slot.startsAt) ??
                                          false,
                                      onSelected: (_) => setState(() {
                                        _slot = (
                                          staffId: entry.staffId,
                                          startsAt: slot.startsAt,
                                        );
                                      }),
                                    ),
                                ],
                              ),
                            ],
                        ],
                      ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
