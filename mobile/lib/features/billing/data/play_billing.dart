import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

/// Resultado de iniciar una compra.
enum PurchaseStartResult { started, unavailable, productNotFound }

/// Envoltorio de Google Play Billing (`in_app_purchase`).
///
/// Flujo obligatorio: comprar -> verificar en el backend -> `completePurchase`.
/// Si la verificación falla NO se completa la compra: Google reembolsa
/// automáticamente a los 3 días y el cliente no queda cobrado sin plan.
class PlayBilling {
  PlayBilling({InAppPurchase? inAppPurchase})
      : _iap = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _iap;
  final Map<String, ProductDetails> _products = {};

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  Map<String, ProductDetails> get products => Map.unmodifiable(_products);

  /// Producto de Play ya cargado (para mostrar el precio real).
  ProductDetails? productFor(String? productId) =>
      productId == null ? null : _products[productId];

  /// Indica si la tienda está disponible en el dispositivo.
  Future<bool> isAvailable() => _iap.isAvailable();

  /// Carga los productos de suscripción indicados.
  Future<bool> loadProducts(Iterable<String> productIds) async {
    final ids = productIds.where((id) => id.isNotEmpty).toSet();
    if (ids.isEmpty) return false;
    if (!await _iap.isAvailable()) return false;

    final response = await _iap.queryProductDetails(ids);
    if (response.productDetails.isEmpty) return false;

    _products
      ..clear()
      ..addEntries(
        response.productDetails.map((product) => MapEntry(product.id, product)),
      );
    return _products.isNotEmpty;
  }

  /// Inicia la compra de una suscripción.
  Future<PurchaseStartResult> buySubscription(String productId) async {
    final product = _products[productId];
    if (product == null) return PurchaseStartResult.productNotFound;
    if (!await _iap.isAvailable()) return PurchaseStartResult.unavailable;

    final started = await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    return started ? PurchaseStartResult.started : PurchaseStartResult.unavailable;
  }

  /// Restaura compras previas (reinstalaciones o cambio de dispositivo).
  Future<void> restore() => _iap.restorePurchases();

  /// Cierra la compra. Solo llamar DESPUÉS de que el backend la verificó.
  Future<void> complete(PurchaseDetails purchase) => _iap.completePurchase(purchase);
}
