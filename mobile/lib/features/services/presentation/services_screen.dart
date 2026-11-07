import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../business/presentation/providers/business_providers.dart';
import './providers/services_providers.dart';

/// Catalogo de servicios del negocio.
class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final membership = ref.watch(activeBusinessProvider);

    if (membership == null) {
      return Scaffold(body: Center(child: Text(l10n.errorGeneric)));
    }

    final businessId = membership.business.id;
    final services = ref.watch(servicesProvider(businessId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.servicesTitle)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(servicesProvider(businessId)),
        child: services.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            message: l10n.errorGeneric,
            retryLabel: l10n.commonRetry,
            onRetry: () => ref.invalidate(servicesProvider(businessId)),
          ),
          data: (items) => items.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    Icon(
                      Icons.content_cut,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.servicesEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final service = items[index];
                    return ListTile(
                      title: Text(service.name),
                      subtitle: Text(
                        '${l10n.commonMinutes(service.durationMinutes)} · '
                        '${service.price.toStringAsFixed(2)}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await showServiceFormSheet(
                              context,
                              ref,
                              businessId: businessId,
                              serviceId: service.id,
                              initialName: service.name,
                              initialDuration: service.durationMinutes,
                              initialPrice: service.price,
                            );
                          } else if (value == 'delete') {
                            await ref
                                .read(servicesRepositoryProvider)
                                .deactivate(service.id);
                            ref.invalidate(servicesProvider(businessId));
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(l10n.commonEdit),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(l10n.commonDelete),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showServiceFormSheet(
          context,
          ref,
          businessId: businessId,
        ),
        icon: const Icon(Icons.add),
        label: Text(l10n.serviceNew),
      ),
    );
  }
}

/// Formulario de alta y edición de servicios.
Future<void> showServiceFormSheet(
  BuildContext context,
  WidgetRef ref, {
  required String businessId,
  String? serviceId,
  String initialName = '',
  int initialDuration = 30,
  double initialPrice = 0,
}) {
  final nameController = TextEditingController(text: initialName);
  final durationController =
      TextEditingController(text: initialDuration.toString());
  final priceController = TextEditingController(text: initialPrice.toString());
  final formKey = GlobalKey<FormState>();
  final l10n = AppLocalizations.of(context);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              serviceId == null ? l10n.serviceNew : l10n.commonEdit,
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.serviceName),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.validationRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.serviceDuration),
              validator: (value) {
                final minutes = int.tryParse(value ?? '');
                if (minutes == null || minutes < 5 || minutes > 600) {
                  return l10n.validationRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.servicePrice),
              validator: (value) {
                final price = double.tryParse(value ?? '');
                if (price == null || price < 0) return l10n.validationRequired;
                return null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final repository = ref.read(servicesRepositoryProvider);

                if (serviceId == null) {
                  await repository.create(
                    businessId: businessId,
                    name: nameController.text,
                    durationMinutes: int.parse(durationController.text),
                    price: double.parse(priceController.text),
                  );
                } else {
                  await repository.update(
                    serviceId: serviceId,
                    name: nameController.text,
                    durationMinutes: int.parse(durationController.text),
                    price: double.parse(priceController.text),
                  );
                }

                ref.invalidate(servicesProvider(businessId));
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    ),
  );
}
