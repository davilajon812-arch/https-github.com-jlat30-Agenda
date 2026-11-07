import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/labels.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../business/presentation/providers/business_providers.dart';
import '../domain/staff.dart';
import './providers/staff_providers.dart';

/// Horario semanal y bloqueos del empleado.
class StaffScheduleScreen extends ConsumerStatefulWidget {
  const StaffScheduleScreen({super.key, required this.staffId});

  final String staffId;

  @override
  ConsumerState<StaffScheduleScreen> createState() =>
      _StaffScheduleScreenState();
}

class _StaffScheduleScreenState extends ConsumerState<StaffScheduleScreen> {
  late List<ScheduleSlot> _draft;
  bool _loaded = false;
  bool _saving = false;

  Future<void> _save(String businessId) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(staffRepositoryProvider).replaceSchedule(
            businessId: businessId,
            staffId: widget.staffId,
            slots: _draft,
          );
      ref.invalidate(staffScheduleProvider(widget.staffId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.staffScheduleSaved)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorSave)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addSlot(int weekday) async {
    final l10n = AppLocalizations.of(context);
    final range = await showTimeRangePicker(context, l10n);
    if (range == null) return;
    setState(() {
      _draft.add(
        ScheduleSlot(weekday: weekday, startTime: range.$1, endTime: range.$2),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final membership = ref.watch(activeBusinessProvider);
    final schedule = ref.watch(staffScheduleProvider(widget.staffId));
    final blocks = ref.watch(staffBlocksProvider(widget.staffId));

    if (membership == null) {
      return Scaffold(body: Center(child: Text(l10n.errorGeneric)));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.staffScheduleTitle)),
      body: schedule.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: l10n.errorGeneric,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(staffScheduleProvider(widget.staffId)),
        ),
        data: (slots) {
          if (!_loaded) {
            _draft = List<ScheduleSlot>.from(slots);
            _loaded = true;
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              for (var weekday = 0; weekday < 7; weekday++)
                _WeekdaySection(
                  weekday: weekday,
                  slots: _draft.where((s) => s.weekday == weekday).toList(),
                  canEdit: membership.isOwner,
                  onAdd: () => _addSlot(weekday),
                  onRemove: (slot) => setState(() => _draft.remove(slot)),
                ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.staffBlocksTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              blocks.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Text(l10n.errorGeneric),
                data: (items) => items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(
                          l10n.staffBlocksEmpty,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (final block in items)
                            ListTile(
                              leading: const Icon(Icons.beach_access_outlined),
                              title: Text(
                                DateFormat('d MMM yyyy HH:mm')
                                    .format(block.startsAt),
                              ),
                              subtitle: Text(
                                '${_kindLabel(l10n, block.kind)} → '
                                '${DateFormat('d MMM yyyy HH:mm').format(block.endsAt)}'
                                '${block.reason != null ? ' · ${block.reason}' : ''}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await ref
                                      .read(staffRepositoryProvider)
                                      .deleteBlock(block.id);
                                  ref.invalidate(
                                    staffBlocksProvider(widget.staffId),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () => _addBlock(
                    context,
                    membership.business.id,
                    l10n,
                  ),
                  icon: const Icon(Icons.event_busy),
                  label: Text(l10n.staffBlockNew),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: membership.isOwner
          ? FloatingActionButton.extended(
              onPressed: _saving
                  ? null
                  : () => _save(membership.business.id),
              icon: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(l10n.commonSave),
            )
          : null,
    );
  }

  String _kindLabel(AppLocalizations l10n, String kind) => switch (kind) {
        'vacacion' => l10n.staffBlockVacation,
        'descanso' => l10n.staffBlockBreak,
        _ => l10n.staffBlockOther,
      };

  Future<void> _addBlock(
    BuildContext context,
    String businessId,
    AppLocalizations l10n,
  ) async {
    final now = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (start == null || !context.mounted) return;

    final end = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: start,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (end == null) return;

    await ref.read(staffRepositoryProvider).createBlock(
          businessId: businessId,
          staffId: widget.staffId,
          startsAt: DateTime(start.year, start.month, start.day, 8),
          endsAt: DateTime(end.year, end.month, end.day, 20),
          kind: 'bloqueo',
        );
    ref.invalidate(staffBlocksProvider(widget.staffId));
  }
}

class _WeekdaySection extends StatelessWidget {
  const _WeekdaySection({
    required this.weekday,
    required this.slots,
    required this.canEdit,
    required this.onAdd,
    required this.onRemove,
  });

  final int weekday;
  final List<ScheduleSlot> slots;
  final bool canEdit;
  final VoidCallback onAdd;
  final ValueChanged<ScheduleSlot> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  weekdayLabel(l10n, weekday),
                  style: theme.textTheme.titleSmall,
                ),
              ),
              if (canEdit)
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_alarm),
                  tooltip: l10n.commonAdd,
                ),
            ],
          ),
          if (slots.isEmpty)
            Text(
              '—',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final slot in slots)
                  InputChip(
                    label: Text('${slot.startTime.label} – ${slot.endTime.label}'),
                    onDeleted: canEdit ? () => onRemove(slot) : null,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Selector de hora de inicio y fin.
Future<(TimeOfDayJson, TimeOfDayJson)?> showTimeRangePicker(
  BuildContext context,
  AppLocalizations l10n,
) async {
  final start = await showTimePicker(
    context: context,
    initialTime: const TimeOfDay(hour: 9, minute: 0),
    helpText: l10n.staffScheduleTitle,
  );
  if (start == null || !context.mounted) return null;

  final end = await showTimePicker(
    context: context,
    initialTime: const TimeOfDay(hour: 18, minute: 0),
    helpText: l10n.staffScheduleTitle,
  );
  if (end == null) return null;

  final startJson = TimeOfDayJson(start.hour, start.minute);
  final endJson = TimeOfDayJson(end.hour, end.minute);
  if (endJson.compareTo(startJson) <= 0) return null;

  return (startJson, endJson);
}
