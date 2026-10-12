import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../data/lotus_api.dart';

/// Produkt-IDs – müssen in der Play Console genau so angelegt werden
/// (und in supabase/functions/verify-purchase/index.ts stehen).
class StoreProducts {
  static const plus = 'lotus_plus_monatlich';
  static const donations = ['spende_klein', 'spende_mittel', 'spende_gross'];
  static const success = 'beitrag_erfolg';
  static const all = {plus, ...donations, success};
  static bool isConsumable(String id) => id != plus;
}

enum StoreEventType { pending, success, error }

class StoreEvent {
  const StoreEvent(this.type, this.productId, [this.error]);

  final StoreEventType type;
  final String productId;
  final Object? error;
}

/// Käufe über Google Play. Jeder Kauf wird erst serverseitig bei Google geprüft
/// (Edge Function verify-purchase) und danach abgeschlossen – nichts wird nur in der App freigeschaltet.
class Store {
  Store(this._api);

  final LotusApi _api;
  final _iap = InAppPurchase.instance;
  final _events = StreamController<StoreEvent>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Map<String, ProductDetails>? _products;

  Stream<StoreEvent> get events => _events.stream;

  /// Startet das Abhören von Käufen (auch von Käufen, die beim letzten Start offen blieben).
  void start() {
    if (kIsWeb || _subscription != null) return;
    _subscription = _iap.purchaseStream.listen(_handle, onError: (Object e) => debugPrint('Store: $e'));
  }

  /// Produkte mit Preisen aus dem Store; leer, wenn Käufe hier nicht möglich sind.
  Future<Map<String, ProductDetails>> products() async {
    if (_products != null) return _products!;
    if (kIsWeb || !await _iap.isAvailable()) return _products = {};
    final response = await _iap.queryProductDetails(StoreProducts.all);
    return _products = {for (final p in response.productDetails) p.id: p};
  }

  Future<void> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product, applicationUserName: _api.currentUserId);
    if (StoreProducts.isConsumable(product.id)) {
      await _iap.buyConsumable(purchaseParam: param);
    } else {
      await _iap.buyNonConsumable(purchaseParam: param);
    }
  }

  Future<void> restore() => _iap.restorePurchases(applicationUserName: _api.currentUserId);

  Future<void> _handle(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _events.add(StoreEvent(StoreEventType.pending, purchase.productID));
        case PurchaseStatus.canceled:
          break;
        case PurchaseStatus.error:
          _events.add(StoreEvent(StoreEventType.error, purchase.productID, purchase.error));
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            final product = _products?[purchase.productID];
            await _api.verifyPurchase(
              productId: purchase.productID,
              purchaseToken: purchase.verificationData.serverVerificationData,
              amountMicros: product == null ? null : (product.rawPrice * 1000000).round(),
              currency: product?.currencyCode,
            );
            if (purchase.pendingCompletePurchase) await _iap.completePurchase(purchase);
            _events.add(StoreEvent(StoreEventType.success, purchase.productID));
          } catch (e) {
            // Nicht abschließen: Google erstattet unbestätigte Käufe nach 3 Tagen automatisch.
            _events.add(StoreEvent(StoreEventType.error, purchase.productID, e));
          }
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    _events.close();
  }
}
