import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'cloud_relationship_service.dart';
import 'vibration_service.dart';

class SubscriptionService extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  final CloudRelationshipService _cloudService = _cloudServiceInstance;
  static final _cloudServiceInstance = CloudRelationshipService(); // Shared instance
  
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // Separate Product IDs for Monthly and Yearly to support Billing v4
  static const String monthlyId = 'nextmeet_plus_monthly';
  static const String yearlyId = 'nextmeet_plus_yearly';
  static const Set<String> _productIds = {monthlyId, yearlyId};

  List<ProductDetails> products = [];
  bool isAvailable = false;
  bool isLoading = true;
  bool isLifecycleVerifying = false;
  String? error;

  void initialize(String relId) {
    isLoading = true;
    notifyListeners();

    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseList) => _listenToPurchaseUpdated(purchaseList, relId),
      onDone: () => _subscription?.cancel(),
      onError: (err) {
        error = err.toString();
        notifyListeners();
      },
    );
    loadProducts();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> loadProducts() async {
    try {
      isAvailable = await _iap.isAvailable();
      if (!isAvailable) {
        error = "Store not available";
        isLoading = false;
        notifyListeners();
        return;
      }

      final response = await _iap.queryProductDetails(_productIds);
      if (response.error != null) {
        error = response.error!.message;
        isLoading = false;
        notifyListeners();
        return;
      }

      products = response.productDetails;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  String getPriceById(String productId) {
    if (products.isEmpty) {
      return productId == yearlyId ? '₹499' : '₹49';
    }
    
    try {
      final product = products.firstWhere((p) => p.id == productId);
      return product.price;
    } catch (_) {
      return products.first.price;
    }
  }

  // --- SUBSCRIPTION LIFECYCLE (AUTO-RESET/RENEW) ---
  Future<void> processLifecycleCheck(String relId, DateTime? renewalDate) async {
    if (renewalDate == null) return;
    final graceDate = renewalDate.add(const Duration(hours: 24));
    
    if (DateTime.now().isAfter(graceDate)) {
      print('Subscription Lifecycle: Past renewal date ($renewalDate). Verifying status...');
      isLifecycleVerifying = true;
      notifyListeners();

      try {
        await _iap.restorePurchases();
        
        final latestRel = await _cloudService.getRelationshipById(relId);
        if (latestRel != null && latestRel.isPlus && latestRel.premiumRenewalDate != null) {
          if (DateTime.now().isAfter(latestRel.premiumRenewalDate!.add(const Duration(hours: 24)))) {
             print('Lifecycle: Store verification failed. Downgrading $relId to Free.');
             await _cloudService.downgradeToFree(relId);
          } else {
             print('Lifecycle: Store verification successful. Status refreshed.');
          }
        }
      } catch (e) {
        print('Lifecycle check error: $e');
      } finally {
        isLifecycleVerifying = false;
        notifyListeners();
      }
    }
  }

  bool _wasYearlySelection = false;

  Future<void> buyProduct(ProductDetails product, bool isYearly) async {
    _wasYearlySelection = isYearly;
    VibrationService.medium();
    
    // Using standard Billing v4 purchase parameters since Subv2 is locked out in this environment.
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseList, String relId) async {
    for (var purchase in purchaseList) {
      if (purchase.status == PurchaseStatus.pending) {
        isLoading = true;
        notifyListeners();
      } else if (purchase.status == PurchaseStatus.error) {
        error = purchase.error?.message ?? "Purchase failed";
        isLoading = false;
        VibrationService.error();
        notifyListeners();
      } else if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        await _deliverEntitlement(purchase, relId, isYearly: _wasYearlySelection);
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        isLoading = false;
        notifyListeners();
      } else if (purchase.status == PurchaseStatus.canceled) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _deliverEntitlement(PurchaseDetails purchase, String relId, {bool isYearly = false}) async {
    try {
      final String planType = isYearly ? 'Annual Sanctuary' : 'Monthly Sanctuary';
      final DateTime renewalDate = isYearly 
          ? DateTime.now().add(const Duration(days: 365)) 
          : DateTime.now().add(const Duration(days: 30));

      await _cloudService.activateRealPremium(
        relId: relId,
        planType: planType,
        transactionId: purchase.purchaseID ?? 'NXM-STORE-ID',
        renewalDate: renewalDate,
      );
      
      VibrationService.success();
      print('Entitlement delivered for $relId');
    } catch (e) {
      print('Error delivering entitlement: $e');
    }
  }
}
