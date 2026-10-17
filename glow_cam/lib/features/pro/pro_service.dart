import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// GlowCam Pro: unlocks premium filters and backgrounds.
///
/// Create these product IDs in Google Play Console and App Store Connect.
/// For production, verify purchases on your server (e.g. an ASP.NET Core
/// endpoint calling the Play Developer / App Store Server APIs) before
/// trusting them; the local flag here is only a cache.
class ProService extends ChangeNotifier {
  static const monthlyId = 'glowcam_pro_monthly';
  static const yearlyId = 'glowcam_pro_yearly';
  static const _prefsKey = 'is_pro';

  /// Test builds (`--dart-define=DEMO=true`) offer a free unlock button.
  static const demoUnlockEnabled = kDebugMode || bool.fromEnvironment('DEMO');

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _isPro = false;
  bool get isPro => _isPro;

  bool storeAvailable = false;
  bool loading = true;
  bool purchasing = false;
  String? error;
  List<ProductDetails> products = [];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool(_prefsKey) ?? false;
    notifyListeners();

    try {
      storeAvailable = await _iap.isAvailable();
      if (storeAvailable) {
        _sub = _iap.purchaseStream.listen(
          _onPurchases,
          onError: (Object e) {
            error = 'تعذر إتمام عملية الشراء';
            purchasing = false;
            notifyListeners();
          },
        );
        final res = await _iap.queryProductDetails({monthlyId, yearlyId});
        products = res.productDetails..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
      }
    } catch (_) {
      storeAvailable = false;
    }
    loading = false;
    notifyListeners();
  }

  Future<void> buy(ProductDetails product) async {
    error = null;
    purchasing = true;
    notifyListeners();
    try {
      await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    } catch (_) {
      purchasing = false;
      error = 'تعذر بدء عملية الشراء';
      notifyListeners();
    }
  }

  Future<void> restore() async {
    error = null;
    await _iap.restorePurchases();
  }

  /// Test-only shortcut so features can be tried without a store account.
  Future<void> debugUnlock() async {
    if (demoUnlockEnabled) await _setPro(true);
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _setPro(true);
          purchasing = false;
        case PurchaseStatus.error:
          error = 'فشلت عملية الشراء، حاول مرة أخرى';
          purchasing = false;
        case PurchaseStatus.canceled:
          purchasing = false;
        case PurchaseStatus.pending:
          break;
      }
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
    notifyListeners();
  }

  Future<void> _setPro(bool value) async {
    _isPro = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Makes the [ProService] available to the widget tree.
class ProScope extends InheritedNotifier<ProService> {
  const ProScope({super.key, required ProService service, required super.child}) : super(notifier: service);

  static ProService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProScope>()!.notifier!;
}
