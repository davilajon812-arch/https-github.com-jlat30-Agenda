import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/agenda_api.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../data/play_billing.dart';
import '../../domain/plan.dart';

/// Catálogo de planes (límites y features; precios vienen de Play).
final plansProvider = FutureProvider<List<Plan>>(
  (ref) => ref.watch(agendaApiProvider).plans(),
);

/// Plan activo del negocio seleccionado.
final entitelementsProvider = FutureProvider<Entitlements?>((ref) async {
  final membership = ref.watch(activeBusinessProvider);
  if (membership == null) return null;
  return ref.watch(agendaApiProvider).entitlements(membership.business.id);
});

/// Producto de Play cargado para un plan (precio y moneda reales).
final playProductProvider =
    FutureProvider.family<PlayProduct?, String>((ref, productId) async {
  final billing = ref.watch(playBillingProvider);
  final productIds = ref.watch(plansProvider).value
          ?.map((plan) => plan.playProductId)
          .whereType<String>()
          .toSet() ??
      <String>{};
  if (productIds.isEmpty || !await billing.loadProducts(productIds)) {
    return null;
  }
  final product = billing.productFor(productId);
  if (product == null) return null;
  return PlayProduct(id: product.id, price: product.price, title: product.title);
});

/// Producto listo para mostrar (precio formateado por Play).
class PlayProduct {
  const PlayProduct({required this.id, required this.price, required this.title});

  final String id;
  final String price;
  final String title;
}

/// Estado de la compra en curso.
class PurchaseState {
  const PurchaseState({
    this.processing = false,
    this.error,
    this.lastPlanId,
    this.hasPendingVerification = false,
    this.paymentPending = false,
  });

  final bool processing;
  final String? error;
  final String? lastPlanId;

  /// Una compra se cobró pero no se pudo verificar; se puede reintentar.
  final bool hasPendingVerification;

  /// Google todavía no confirmó el pago (métodos diferidos).
  final bool paymentPending;

  PurchaseState copyWith({
    bool? processing,
    String? error,
    String? lastPlanId,
    bool? hasPendingVerification,
    bool? paymentPending,
    bool clearError = false,
  }) {
    return PurchaseState(
      processing: processing ?? this.processing,
      error: clearError ? null : (error ?? this.error),
      lastPlanId: lastPlanId ?? this.lastPlanId,
      hasPendingVerification:
          hasPendingVerification ?? this.hasPendingVerification,
      paymentPending: paymentPending ?? this.paymentPending,
    );
  }
}

/// Datos necesarios para revalidar una compra ya cobrada.
class _PendingPurchase {
  const _PendingPurchase({
    required this.businessId,
    required this.productId,
    required this.purchaseToken,
    required this.complete,
  });

  final String businessId;
  final String productId;
  final String purchaseToken;
  final Future<void> Function() complete;
}

/// Orquesta la compra: Play -> verificación en backend -> completar.
class PurchaseController extends Notifier<PurchaseState> {
  _PendingPurchase? _pending;

  @override
  PurchaseState build() => const PurchaseState();

  /// Compra una suscripción y devuelve true si quedó verificada.
  Future<bool> purchase({
    required String businessId,
    required String productId,
  }) async {
    state = state.copyWith(processing: true, clearError: true);
    try {
      final billing = ref.read(playBillingProvider);
      final started = await billing.buySubscription(productId);
      if (started != PurchaseStartResult.started) {
        state = state.copyWith(
          processing: false,
          error: 'La tienda no está disponible en este dispositivo.',
        );
        return false;
      }

      // El resultado real llega por el stream; ver _handlePurchase.
      state = state.copyWith(processing: false);
      return true;
    } on AgendaApiException catch (error) {
      state = state.copyWith(processing: false, error: error.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        processing: false,
        error: 'No se pudo iniciar la compra.',
      );
      return false;
    }
  }

  /// Verifica la compra en el backend y, si es válida, la completa en Play.
  ///
  /// Si la verificación falla se guarda la compra para poder reintentarla: el
  /// cobro ya ocurrió y no se debe descartar.
  Future<bool> verifyAndComplete({
    required String businessId,
    required String productId,
    required String purchaseToken,
    required Future<void> Function() complete,
  }) async {
    state = state.copyWith(processing: true, clearError: true);
    try {
      final entitlements = await ref.read(agendaApiProvider).verifyPurchase(
            businessId: businessId,
            productId: productId,
            purchaseToken: purchaseToken,
          );
      await complete();
      _pending = null;
      state = state.copyWith(
        processing: false,
        lastPlanId: entitlements.plan.id,
        hasPendingVerification: false,
        paymentPending: false,
      );
      ref.invalidate(entitelementsProvider);
      return true;
    } on AgendaApiException catch (error) {
      _rememberPending(businessId, productId, purchaseToken, complete);
      state = state.copyWith(processing: false, error: error.message);
      return false;
    } catch (_) {
      _rememberPending(businessId, productId, purchaseToken, complete);
      state = state.copyWith(
        processing: false,
        error: 'No se pudo verificar la compra.',
      );
      return false;
    }
  }

  /// Reintenta la verificación de una compra que quedó sin completar.
  Future<bool> retryVerification() async {
    final pending = _pending;
    if (pending == null) return false;
    return verifyAndComplete(
      businessId: pending.businessId,
      productId: pending.productId,
      purchaseToken: pending.purchaseToken,
      complete: pending.complete,
    );
  }

  /// Marca que Google aún no confirmó el pago (no hay nada que verificar).
  void markPaymentPending() {
    state = state.copyWith(paymentPending: true, clearError: true);
  }

  void clearError() => state = state.copyWith(clearError: true);

  void _rememberPending(
    String businessId,
    String productId,
    String purchaseToken,
    Future<void> Function() complete,
  ) {
    _pending = _PendingPurchase(
      businessId: businessId,
      productId: productId,
      purchaseToken: purchaseToken,
      complete: complete,
    );
    state = state.copyWith(hasPendingVerification: true);
  }
}

final purchaseControllerProvider =
    NotifierProvider<PurchaseController, PurchaseState>(PurchaseController.new);
