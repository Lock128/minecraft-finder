import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/feature_flags.dart';

/// Product ID for the one-time Pro unlock.
/// Must match the product ID configured in App Store Connect and Google Play Console.
const String kProProductId = 'mc_finder_pro_unlock';

/// Set of all product IDs offered.
const Set<String> kProductIds = {kProProductId};

/// Manages Pro tier status via App Store / Play Store in-app purchases.
///
/// Exposes [isPro] for the widget tree to conditionally enable features.
/// Persists purchase state locally via SharedPreferences so the app doesn't
/// need to re-verify on every cold start (but still supports restore).
class ProStatusProvider extends ChangeNotifier {
  static const String _proKey = 'is_pro_unlocked';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isPro = false;
  bool get isPro => _isPro;

  bool _isAvailable = false;
  bool get isStoreAvailable => _isAvailable;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  bool _purchasePending = false;
  bool get purchasePending => _purchasePending;

  String? _error;
  String? get error => _error;

  ProStatusProvider() {
    _init();
  }

  Future<void> _init() async {
    // When monetization is disabled, grant full access to everyone
    if (!FeatureFlags.enableMonetization) {
      _isPro = true;
      _isAvailable = false;
      notifyListeners();
      return;
    }

    // Load cached pro status immediately so the UI can render
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool(_proKey) ?? false;
    notifyListeners();

    // IAP is not available on web
    if (kIsWeb) {
      _isAvailable = false;
      return;
    }

    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) return;

    // Listen to purchase updates
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdated,
      onDone: _onDone,
      onError: _onError,
    );

    // Load products from the store
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(kProductIds);
    if (response.error != null) {
      _error = response.error!.message;
      notifyListeners();
      return;
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP: Products not found: ${response.notFoundIDs}');
    }

    _products = response.productDetails;
    notifyListeners();
  }

  /// Initiates the purchase flow for the Pro unlock.
  Future<void> buyPro() async {
    if (_products.isEmpty) {
      _error = 'Products not loaded. Please try again.';
      notifyListeners();
      return;
    }

    final productDetails = _products.firstWhere(
      (p) => p.id == kProProductId,
      orElse: () => _products.first,
    );

    final purchaseParam = PurchaseParam(productDetails: productDetails);

    // Non-consumable purchase (one-time unlock)
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Restores previous purchases (e.g. after reinstall or new device).
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
          _error = null;
          notifyListeners();
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _purchasePending = false;
          _error = null;
          _unlockPro();
          // Complete the purchase (required by both stores)
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.error:
          _purchasePending = false;
          _error = purchase.error?.message ?? 'Purchase failed';
          notifyListeners();
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          _purchasePending = false;
          _error = null;
          notifyListeners();
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          break;
      }
    }
  }

  Future<void> _unlockPro() async {
    _isPro = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_proKey, true);
  }

  void _onDone() {
    _subscription?.cancel();
  }

  void _onError(dynamic error) {
    debugPrint('IAP stream error: $error');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
