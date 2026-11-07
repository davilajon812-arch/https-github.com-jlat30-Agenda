import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../business/presentation/providers/business_providers.dart';
import './providers/staff_providers.dart';

/// Empleados del negocio; al tocar uno se edita su horario y bloqueos.
class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final membership = ref.watch(activeBusinessProvider);

    if (membership == null) {
      return Scaffold(body: Center(child: Text(l10n.errorGeneric)));
    }

    final businessId = membership.business.id;
    final staff = ref.watch(staffProvider(businessId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.staffTitle)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(staffProvider(businessId)),
        child: staff.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            message: l10n.errorGeneric,
            retryLabel: l10n.commonRetry,
            onRetry: () => ref.invalidate(staffProvider(businessId)),
          ),
          data: (items) => items.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    Icon(
                      Icons.badge_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.staffEmpty,
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
                    final member = items[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            _colorFromHex(member.color, Theme.of(context)),
                        child: Text(
                          member.displayName.characters.first.toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(member.displayName),
                      subtitle: Text(l10n.staffScheduleTitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/staff/${member.id}/schedule'),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: membership.isOwner
          ? FloatingActionButton.extended(
              onPressed: () => _showStaffForm(context, ref, businessId),
              icon: const Icon(Icons.person_add_alt),
              label: Text(l10n.staffNew),
            )
          : null,
    );
  }

  static Color _colorFromHex(String hex, ThemeData theme) {
    final value = hex.replaceFirst('#', '');
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null || value.length != 6) return theme.colorScheme.primary;
    return Color(0xFF000000 | parsed);
  }

  Future<void> _showStaffForm(
    BuildContext context,
    WidgetRef ref,
    String businessId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    await showModalBottomSheet<void>(
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
                l10n.staffNew,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.staffName),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.validationRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l10n.clientPhone),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  await ref.read(staffRepositoryProvider).create(
                        businessId: businessId,
                        displayName: nameController.text,
                        phone: phoneController.text.trim().isEmpty
                            ? null
                            : phoneController.text.trim(),
                      );
                  ref.invalidate(staffProvider(businessId));
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
}
