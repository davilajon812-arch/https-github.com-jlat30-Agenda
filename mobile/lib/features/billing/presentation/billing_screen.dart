import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/error_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../business/presentation/providers/business_providers.dart';
import '../domain/plan.dart';
import 'providers/billing_providers.dart';

/// Plan actual del negocio y compra de suscripciones con Google Play.
class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _restoring = false;
  String? _purchaseError;

  @override
  void initState() {
    super.initState();
    _subscription = ref.read(playBillingProvider).purchaseStream.listen(
          _onPurchases,
          onError: (Object error) => setState(
            () => _purchaseError = AppLocalizations.of(context).billingPurchaseError,
          ),
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Cada compra se verifica en el backend y solo después se completa en Play.
  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    final membership = ref.read(activeBusinessProvider);
    if (membership == null) return;
    final l10n = AppLocalizations.of(context);
    final billing = ref.read(playBillingProvider);

    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final verified =
              await ref.read(purchaseControllerProvider.notifier).verifyAndComplete(
                    businessId: membership.business.id,
                    productId: purchase.productID,
                    purchaseToken: purchase.verificationData.serverVerificationData,
                    complete: () => billing.complete(purchase),
                  );
          if (!mounted) return;
          setState(() {
            _purchaseError = verified ? null : l10n.billingPurchaseError;
          });
          if (verified) {
            _showMessage(l10n.billingPurchaseSuccess);
          }
        case PurchaseStatus.error:
          if (!mounted) return;
          setState(() => _purchaseError = purchase.error?.message);
        case PurchaseStatus.pending:
          // Pago diferido (efectivo, transferencia): Google aún no confirma.
          ref.read(purchaseControllerProvider.notifier).markPaymentPending();
        case PurchaseStatus.canceled:
          break;
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _buy(Plan plan) async {
    final membership = ref.read(activeBusinessProvider);
    final productId = plan.playProductId;
    if (membership == null || productId == null) return;

    final started = await ref.read(purchaseControllerProvider.notifier).purchase(
          businessId: membership.business.id,
          productId: productId,
        );

    if (!started && mounted) {
      final error = ref.read(purchaseControllerProvider).error;
      if (error != null) setState(() => _purchaseError = error);
    }
  }

  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _restoring = true;
      _purchaseError = null;
    });
    await ref.read(playBillingProvider).restore();
    if (!mounted) return;
    setState(() => _restoring = false);
    _showMessage(l10n.billingRestoreStarted);
  }

  /// Reintenta verificar una compra que ya se cobró pero quedó sin completar.
  Future<void> _retryVerification() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _purchaseError = null);
    final verified =
        await ref.read(purchaseControllerProvider.notifier).retryVerification();
    if (!mounted) return;
    if (verified) _showMessage(l10n.billingPurchaseSuccess);
  }

  Future<void> _openPlaySubscriptions(Entitlements entitlements) async {
    final config = ref.read(appConfigProvider);
    final uri = Uri.parse(
      'https://play.google.com/store/account/subscriptions'
      '?package=${config.androidPackageName}'
      '${entitlements.productId == null ? '' : '&sku=${entitlements.productId}'}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entitlements = ref.watch(entitelementsProvider);
    final plans = ref.watch(plansProvider);
    final purchase = ref.watch(purchaseControllerProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(entitelementsProvider);
        ref.invalidate(plansProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          entitlements.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => ErrorView(
              message: l10n.errorGeneric,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(entitelementsProvider),
            ),
            data: (data) => data == null
                ? const SizedBox.shrink()
                : _CurrentPlanCard(
                    entitlements: data,
                    onManage: () => _openPlaySubscriptions(data),
                  ),
          ),
          if (purchase.processing)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.billingPurchasePending),
                ],
              ),
            ),
          if (_purchaseError != null || purchase.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _purchaseError ?? purchase.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (purchase.paymentPending)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 18,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.billingPurchaseWaiting)),
                ],
              ),
            ),
          if (purchase.hasPendingVerification)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.billingPendingVerificationHelp),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed:
                        purchase.processing ? null : _retryVerification,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.billingRetryVerification),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text(
            l10n.billingChoose,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          plans.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Text(l10n.errorGeneric),
            data: (items) => Column(
              children: [
                for (final plan in items)
                  _PlanCard(
                    plan: plan,
                    isCurrent:
                        entitlements.value?.plan.id == plan.id,
                    onBuy: plan.isPurchasable ? () => _buy(plan) : null,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _restoring ? null : _restore,
            icon: const Icon(Icons.restore),
            label: Text(l10n.billingRestore),
          ),
        ],
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.entitlements, required this.onManage});

  final Entitlements entitlements;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat('d MMM yyyy', locale);

    final statusLabel = switch (entitlements.status) {
      'active' => l10n.billingStatusActive,
      'grace' => l10n.billingStatusGrace,
      'paused' => l10n.billingStatusPaused,
      'canceled' => l10n.billingStatusCanceled,
      'expired' => l10n.billingStatusExpired,
      _ => l10n.billingStatusPending,
    };

    final periodLabel = entitlements.currentPeriodEnd == null
        ? null
        : entitlements.autoRenewing
            ? l10n.billingRenewsOn(dateFormat.format(entitlements.currentPeriodEnd!))
            : l10n.billingExpiresOn(dateFormat.format(entitlements.currentPeriodEnd!));

    final staffLimit = entitlements.plan.maxStaff;
    final appointmentsLimit = entitlements.plan.maxAppointmentsPerMonth;
    final messagesLimit = entitlements.plan.maxMessagesPerMonth;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.billingCurrentPlan, style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    entitlements.plan.name,
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                Chip(label: Text(statusLabel)),
              ],
            ),
            if (periodLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                periodLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (entitlements.isPaid && !entitlements.autoRenewing) ...[
              const SizedBox(height: 4),
              Text(
                l10n.billingNoRenewal,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const Divider(height: 24),
            _UsageRow(
              label: l10n.billingUsageStaff(
                entitlements.usage.staffCount,
                staffLimit?.toString() ?? l10n.billingUnlimited,
              ),
              used: entitlements.usage.staffCount,
              limit: staffLimit,
            ),
            _UsageRow(
              label: l10n.billingUsageAppointments(
                entitlements.usage.appointmentsThisMonth,
                appointmentsLimit?.toString() ?? l10n.billingUnlimited,
              ),
              used: entitlements.usage.appointmentsThisMonth,
              limit: appointmentsLimit,
            ),
            _UsageRow(
              label: l10n.billingUsageMessages(
                entitlements.usage.messagesThisMonth,
                messagesLimit?.toString() ?? l10n.billingUnlimited,
              ),
              used: entitlements.usage.messagesThisMonth,
              limit: messagesLimit,
            ),
            if (entitlements.isPaid && entitlements.source == 'play') ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onManage,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(l10n.billingManage),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.label, required this.used, required this.limit});

  final String label;
  final int used;
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        limit == null || limit == 0 ? null : (used / limit!).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          if (progress != null) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.onBuy,
  });

  final Plan plan;
  final bool isCurrent;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final productId = plan.playProductId;
    final product =
        productId == null ? null : ref.watch(playProductProvider(productId));

    final precio = plan.isPurchasable
        ? (product?.value?.price ?? l10n.billingPriceUnavailable)
        : l10n.billingPlanFree;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrent
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(plan.name, style: theme.textTheme.titleLarge),
                ),
                Text(
                  precio,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _FeatureLine(
              enabled: plan.maxStaff == null || plan.maxStaff! > 1,
              text: plan.maxStaff == null
                  ? '${l10n.staffTitle}: ${l10n.billingUnlimited}'
                  : '${l10n.staffTitle}: ${plan.maxStaff}',
            ),
            _FeatureLine(
              enabled: plan.maxAppointmentsPerMonth != 30,
              text: plan.maxAppointmentsPerMonth == null
                  ? '${l10n.navAppointments}: ${l10n.billingUnlimited}'
                  : '${l10n.navAppointments}: ${plan.maxAppointmentsPerMonth} / mes',
            ),
            _FeatureLine(
              enabled: plan.feature('reminders'),
              text: l10n.billingFeatureReminders,
            ),
            _FeatureLine(
              enabled: plan.feature('advanced_reports'),
              text: l10n.billingFeatureReports,
            ),
            _FeatureLine(
              enabled: plan.feature('custom_branding'),
              text: l10n.billingFeatureBranding,
            ),
            const SizedBox(height: 12),
            if (isCurrent)
              OutlinedButton(
                onPressed: null,
                child: Text(l10n.billingCurrent),
              )
            else if (onBuy != null)
              FilledButton(
                onPressed: onBuy,
                child: Text(l10n.billingUpgrade),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.enabled, required this.text});

  final bool enabled;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.remove_circle_outline,
            size: 16,
            color: enabled
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: enabled
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
