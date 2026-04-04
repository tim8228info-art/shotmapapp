import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Subscription service using in_app_purchase plugin.
/// Uses Play Billing Library 7.x on Android (PBL >= 6.0.1).
/// Falls back to stub on web for preview purposes.
///
/// Purchase state persistence strategy:
/// 1. On successful purchase/restore → save to SharedPreferences immediately
/// 2. On app startup → read cached state first, then verify with store
/// 3. Purchase stream listener is registered at init (acts as transaction observer)
/// 4. Completer used for restore to avoid fragile timing-based waits
///
/// IMPORTANT: Auto-navigation is controlled by [purchasedByUser].
/// Only user-initiated purchase/restore sets this flag to true.
/// Silent restore on startup does NOT trigger auto-navigation,
/// so the PaywallScreen stays visible until the user takes action.
class SubscriptionService extends ChangeNotifier {
  static const String _productId = 'com.shotmap.pins.monthly';
  static const String _prefKey = 'is_subscribed';
  // ignore: unused_field
  static const String _prefKeyExpiry = 'subscription_expiry';
  static const String _prefKeyLastVerified = 'subscription_last_verified';

  bool _isSubscribed = false;
  bool _isLoading = false;
  bool _isAvailable = false;
  bool _initCompleted = false;
  String? _errorMessage;

  /// Flag: true ONLY when the user explicitly completed a purchase or restore
  /// on the PaywallScreen. Silent background restore does NOT set this.
  /// PaywallScreen uses this to decide whether to auto-navigate.
  bool _purchasedByUser = false;

  /// Whether the current purchase stream event came from a user-initiated action
  bool _userInitiatedAction = false;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  /// Completer that resolves when initial restore check finishes.
  Completer<void>? _restoreCompleter;

  bool get isSubscribed => _isSubscribed;
  bool get isLoading => _isLoading;
  bool get isAvailable => _isAvailable;
  bool get initCompleted => _initCompleted;
  String? get errorMessage => _errorMessage;
  bool get purchasedByUser => _purchasedByUser;

  SubscriptionService() {
    _init();
  }

  /// Wait for initialization to complete (use in splash/routing logic).
  Future<void> waitForInit() async {
    if (_initCompleted) return;
    // Poll until init is done (max 5 seconds)
    for (int i = 0; i < 50; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_initCompleted) return;
    }
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    // Web: always subscribed for demo/preview
    if (kIsWeb) {
      _isSubscribed = true;
      _isAvailable = true;
      _isLoading = false;
      _initCompleted = true;
      _purchasedByUser = true;
      await prefs.setBool(_prefKey, true);
      notifyListeners();
      return;
    }

    // STEP 1: Immediately restore cached subscription state
    // This ensures premium features are available instantly on launch
    _isSubscribed = prefs.getBool(_prefKey) ?? false;

    // STEP 2: Initialize IAP and register transaction observer
    _isAvailable = await InAppPurchase.instance.isAvailable();

    if (_isAvailable) {
      // Register purchase stream listener EARLY (acts as SKPaymentQueue observer)
      // This is critical: must be registered before any purchases/restores
      _purchaseSubscription = InAppPurchase.instance.purchaseStream.listen(
        _onPurchaseUpdated,
        onDone: () => _purchaseSubscription?.cancel(),
        onError: (error) {
          if (kDebugMode) {
            debugPrint('[SubscriptionService] purchase stream error: $error');
          }
        },
      );

      // STEP 3: Silently verify subscription with store in background
      // _userInitiatedAction is false here, so _purchasedByUser stays false
      await _silentRestore(prefs);
    }

    _isLoading = false;
    _initCompleted = true;
    notifyListeners();
  }

  Future<void> _silentRestore(SharedPreferences prefs) async {
    try {
      _restoreCompleter = Completer<void>();

      // _userInitiatedAction stays false for silent restore
      _userInitiatedAction = false;

      await InAppPurchase.instance.restorePurchases();

      // Wait for restore results with a timeout (not a blind delay)
      await _restoreCompleter!.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('[SubscriptionService] silent restore timed out');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SubscriptionService] silent restore error: $e');
      }
    } finally {
      _restoreCompleter = null;
    }

    // If store didn't find active subscription, keep cached state
    // (subscription may have been purchased on another device)
    if (kDebugMode) {
      debugPrint('[SubscriptionService] after restore: isSubscribed=$_isSubscribed, purchasedByUser=$_purchasedByUser');
    }
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      if (kDebugMode) {
        debugPrint(
          '[SubscriptionService] purchase update: '
          'productID=${purchase.productID}, '
          'status=${purchase.status}, '
          'userInitiated=$_userInitiatedAction',
        );
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Verify and deliver the product.
        // Only persist to SharedPreferences if user-initiated,
        // so silent restore does NOT poison the cache.
        _setSubscribed(true, persistToPrefs: _userInitiatedAction);

        // Only set purchasedByUser if this was a user-initiated action
        if (_userInitiatedAction) {
          _purchasedByUser = true;
        }

        if (purchase.pendingCompletePurchase) {
          InAppPurchase.instance.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        _errorMessage = purchase.error?.message ?? '購入エラーが発生しました';
        _isLoading = false;
        notifyListeners();
      } else if (purchase.status == PurchaseStatus.canceled) {
        _isLoading = false;
        notifyListeners();
      }
    }

    // Complete the restore completer if waiting
    if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
      _restoreCompleter!.complete();
    }
  }

  /// Update subscription state in memory and optionally persist.
  /// [persistToPrefs] defaults to true for user-initiated actions,
  /// but is set to false during silent restore to prevent poisoning
  /// the cached state and auto-skipping the PaywallScreen.
  Future<void> _setSubscribed(bool value, {bool persistToPrefs = true}) async {
    _isSubscribed = value;
    _isLoading = false;

    if (persistToPrefs) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);

      // Record when we last verified the subscription
      if (value) {
        await prefs.setInt(
          _prefKeyLastVerified,
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    }

    notifyListeners();
  }

  /// Purchase the monthly subscription plan.
  Future<void> purchaseMonthlyPlan() async {
    if (kIsWeb) {
      _purchasedByUser = true;
      await _setSubscribed(true);
      return;
    }

    if (!_isAvailable) {
      _errorMessage = 'ストアが利用できません';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _userInitiatedAction = true; // Mark as user-initiated
    notifyListeners();

    try {
      final response = await InAppPurchase.instance
          .queryProductDetails({_productId});

      if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
        _errorMessage = '商品が見つかりませんでした';
        _isLoading = false;
        _userInitiatedAction = false;
        notifyListeners();
        return;
      }

      final productDetails = response.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: productDetails);
      await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      // Note: Navigation should happen in _onPurchaseUpdated callback,
      // not immediately after calling buyNonConsumable
    } catch (e) {
      _errorMessage = '購入処理でエラーが発生しました: $e';
      _isLoading = false;
      _userInitiatedAction = false;
      notifyListeners();
    }
  }

  /// Restore previous purchases.
  Future<void> restorePurchases() async {
    if (kIsWeb) {
      _purchasedByUser = true;
      await _setSubscribed(true);
      return;
    }

    if (!_isAvailable) {
      _errorMessage = 'ストアが利用できません';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _userInitiatedAction = true; // Mark as user-initiated
    notifyListeners();

    try {
      _restoreCompleter = Completer<void>();
      await InAppPurchase.instance.restorePurchases();

      // Wait for restore results with timeout
      await _restoreCompleter!.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('[SubscriptionService] restore timed out');
          }
        },
      );
    } catch (e) {
      _errorMessage = '復元エラー: $e';
    } finally {
      _restoreCompleter = null;
      _isLoading = false;
      _userInitiatedAction = false;
      notifyListeners();
    }
  }

  /// Reset purchasedByUser flag (called after navigation completes)
  void clearPurchasedByUser() {
    _purchasedByUser = false;
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
