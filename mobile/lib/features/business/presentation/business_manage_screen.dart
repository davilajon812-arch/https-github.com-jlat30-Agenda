import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../billing/domain/plan.dart';
import '../../billing/presentation/providers/billing_providers.dart';
import '../domain/business.dart';
import 'providers/business_providers.dart';
import 'widgets/business_form_fields.dart';

/// Ajustes del negocio: elegir cuál está activo y editar sus datos.
class BusinessManageScreen extends ConsumerWidget {
  const BusinessManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final memberships = ref.watch(myBusinessesProvider);
    final active = ref.watch(activeBusinessProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.businessManageTitle)),
      body: memberships.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: l10n.errorGeneric,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(myBusinessesProvider),
        ),
        data: (list) {
          if (active == null) {
            return Center(child: Text(l10n.errorGeneric));
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              if (list.length > 1) _BusinessSelector(memberships: list),
              _BusinessSummary(
                membership: active,
                onEdit: () => _edit(context, ref, active.business),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: OutlinedButton.icon(
                  onPressed: () => _add(context, ref),
                  icon: const Icon(Icons.add_business_outlined),
                  label: Text(l10n.businessAdd),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Business business,
  ) async {
    final saved = await showBusinessFormSheet(context, ref, business: business);
    if (saved) ref.invalidate(myBusinessesProvider);
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    // Se espera el plan del negocio activo: leerlo sin esperar deja el valor en
    // nulo y el formulario se abriría para luego fallar al guardar.
    Entitlements? entitlements;
    try {
      entitlements = await ref.read(entitelementsProvider.future);
    } catch (_) {
      entitlements = null; // sin datos, la base vuelve a validar al guardar
    }
    if (entitlements != null && !entitlements.isPaid) {
      if (!context.mounted) return;
      await _showProOnlyDialog(context);
      return;
    }
    if (!context.mounted) return;

    final created = await showBusinessFormSheet(context, ref);
    if (!created) return;
    ref.invalidate(myBusinessesProvider);
  }

  Future<void> _showProOnlyDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final goToPlans = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.businessAddProTitle),
        content: Text(l10n.businessAddProMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.planLimitLater),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.businessAddProAction),
          ),
        ],
      ),
    );
    if (goToPlans == true && context.mounted) {
      context.push('/plan');
    }
  }
}

/// Lista de negocios del usuario para cambiar el activo.
class _BusinessSelector extends ConsumerWidget {
  const _BusinessSelector({required this.memberships});

  final List<BusinessMembership> memberships;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final activeId = ref.watch(activeBusinessProvider)?.business.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(l10n.businessSwitch, style: theme.textTheme.titleSmall),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.businessSwitchHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        RadioGroup<String>(
          groupValue: activeId,
          onChanged: (value) {
            if (value != null) {
              ref.read(selectedBusinessIdProvider.notifier).select(value);
            }
          },
          child: Column(
            children: [
              for (final membership in memberships)
                RadioListTile<String>(
                  value: membership.business.id,
                  title: Text(membership.business.name),
                  subtitle: Text(membership.role),
                ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }
}

/// Resumen del negocio activo con acceso a la edición.
class _BusinessSummary extends StatelessWidget {
  const _BusinessSummary({required this.membership, required this.onEdit});

  final BusinessMembership membership;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final business = membership.business;

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.storefront_outlined),
          title: Text(business.name),
          subtitle: Text(
            [
              if (business.phone != null) business.phone!,
              business.currency,
              business.timezone,
            ].join(' · '),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.businessEdit),
            ),
          ),
        ),
      ],
    );
  }
}

/// Abre el formulario de alta o edición de un negocio.
///
/// Devuelve `true` si se guardó. Con [business] edita; sin él, crea.
Future<bool> showBusinessFormSheet(
  BuildContext context,
  WidgetRef ref, {
  Business? business,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _BusinessFormSheet(business: business),
  );
  return result ?? false;
}

class _BusinessFormSheet extends ConsumerStatefulWidget {
  const _BusinessFormSheet({this.business});

  final Business? business;

  @override
  ConsumerState<_BusinessFormSheet> createState() => _BusinessFormSheetState();
}

class _BusinessFormSheetState extends ConsumerState<_BusinessFormSheet> {
  final _fieldsKey = GlobalKey<BusinessFormFieldsState>();
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final draft = _fieldsKey.currentState?.validate();
    if (draft == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final repository = ref.read(businessRepositoryProvider);
    try {
      if (widget.business == null) {
        final created = await repository.createBusiness(
          name: draft.name,
          industry: draft.industry,
          countryCode: draft.countryCode,
          currency: draft.currency,
          timezone: draft.timezone,
          phone: draft.phone,
        );
        await ref.read(selectedBusinessIdProvider.notifier).select(created.id);
      } else {
        await repository.updateBusiness(
          businessId: widget.business!.id,
          name: draft.name,
          industry: draft.industry,
          countryCode: draft.countryCode,
          currency: draft.currency,
          timezone: draft.timezone,
          phone: draft.phone,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message.contains('plan_limit_reached')
            ? l10n.businessAddProMessage
            : l10n.errorSave;
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
    final theme = Theme.of(context);
    final isEdit = widget.business != null;

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
              isEdit ? l10n.businessEditTitle : l10n.businessNewTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            BusinessFormFields(key: _fieldsKey, initial: widget.business),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? l10n.businessSave : l10n.businessCreate),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
          ],
        ),
      ),
    );
  }
}
