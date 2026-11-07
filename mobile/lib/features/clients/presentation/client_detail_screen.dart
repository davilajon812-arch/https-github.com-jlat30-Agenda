import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/whatsapp_launcher.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../appointments/domain/appointment.dart';
import '../../appointments/presentation/providers/agenda_providers.dart';
import '../../appointments/presentation/widgets/status_chip.dart';
import '../../business/presentation/providers/business_providers.dart';
import './providers/clients_providers.dart';
import 'widgets/client_form_sheet.dart';

/// Ficha del cliente con historial de visitas.
class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final membership = ref.watch(activeBusinessProvider);
    final client = ref.watch(clientProvider(clientId));

    if (membership == null) {
      return Scaffold(body: Center(child: Text(l10n.errorGeneric)));
    }

    final visitsQuery = (
      businessId: membership.business.id,
      clientId: clientId,
    );
    final visits = ref.watch(clientVisitsProvider(visitsQuery));

    return Scaffold(
      appBar: AppBar(
        title: Text(client.value?.fullName ?? l10n.appointmentClient),
        actions: [
          if (client.value != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                final current = client.value!;
                if (value == 'edit') {
                  final saved = await ClientFormSheet.show(
                    context,
                    businessId: membership.business.id,
                    client: current,
                  );
                  if (saved != null) {
                    ref.invalidate(clientProvider(clientId));
                    ref.invalidate(clientsProvider(
                      (businessId: membership.business.id, search: ''),
                    ));
                  }
                } else if (value == 'delete') {
                  await _delete(context, ref, current.id, visitsQuery);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text(l10n.commonEdit)),
                PopupMenuItem(value: 'delete', child: Text(l10n.commonDelete)),
              ],
            ),
        ],
      ),
      body: client.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: l10n.errorNotFound,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(clientProvider(clientId)),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.fullName,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(data.phone),
                    if (data.notes != null && data.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        data.notes!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () async {
                final l10n = AppLocalizations.of(context);
                final businessName =
                    membership.business.name.isEmpty ? l10n.appTitle : membership.business.name;
                final opened = await openWhatsApp(
                  phone: data.whatsappNumber,
                  message: 'Hola ${data.fullName}, te escribimos de $businessName.',
                );
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.errorGeneric)),
                  );
                }
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(l10n.agendaWhatsapp),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.clientHistory,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            visits.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Text(l10n.errorGeneric),
              data: (items) => items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        l10n.clientNoVisits,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (final visit in items) _VisitTile(visit: visit),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String id,
    ({String businessId, String clientId}) visitsQuery,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.clientDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(clientsRepositoryProvider).delete(id);
      ref.invalidate(clientsProvider(
        (businessId: visitsQuery.businessId, search: ''),
      ));
      if (!context.mounted) return;
      context.pop();
    } on PostgrestException catch (error) {
      if (!context.mounted) return;
      final message =
          error.code == '23503' ? l10n.clientHasVisits : l10n.errorSave;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}

class _VisitTile extends StatelessWidget {
  const _VisitTile({required this.visit});

  final Appointment visit;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: StatusChip(status: visit.status),
      title: Text(DateFormat('d MMM yyyy · HH:mm', locale).format(visit.startsAt)),
      subtitle: Text([
        if (visit.serviceName != null) visit.serviceName!,
        if (visit.staffName != null) visit.staffName!,
      ].join(' · ')),
      trailing: visit.price == null
          ? null
          : Text(visit.price!.toStringAsFixed(2)),
      onTap: () => context.push('/appointments/${visit.id}'),
    );
  }
}
