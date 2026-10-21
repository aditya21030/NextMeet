import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../constants.dart';
import 'cloud_relationship_service.dart';
import 'vibration_service.dart';

class SubscriptionService extends ChangeNotifier {
  final CloudRelationshipService _cloudService = _cloudServiceInstance;
  static final _cloudServiceInstance = CloudRelationshipService();

  Offerings? offerings;
  Package? monthlyPackage;
  Package? annualPackage;
  StoreProduct? monthlyProduct;
  StoreProduct? annualProduct;
  
  bool isAvailable = false;
  bool isLoading = true;
  String? error;
  String? _activeRelId;

  static const String monthlyId = 'nextmeet_plus_monthly';
  static const String yearlyId = 'nextmeet_plus_yearly';

  Future<void> initialize(String relId) async {
    _activeRelId = relId;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // 1. Configure Purchases with RevenueCat API key and couple ID safely
      final bool alreadyConfigured = await Purchases.isConfigured;
      if (!alreadyConfigured) {
        final configuration = PurchasesConfiguration(RevenueCatConfig.apiKey)
          ..appUserID = 'rel_$relId';
        await Purchases.configure(configuration);
      } else {
        await Purchases.logIn('rel_$relId');
      }
      isAvailable = true;

      // 2. Load Offerings
      await loadProducts();

      // 3. Listen to real-time subscription status changes
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _handleCustomerInfoUpdate(customerInfo);
      });

      // 4. Sync current customer info on startup
      try {
        final initialInfo = await Purchases.getCustomerInfo();
        _handleCustomerInfoUpdate(initialInfo);
      } catch (_) {}
    } catch (e) {
      debugPrint('RevenueCat initialization notice: $e');
      isAvailable = false;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProducts() async {
    try {
      offerings = await Purchases.getOfferings();
      if (offerings != null) {
        // 1. Check designated current offering first
        if (offerings!.current != null) {
          monthlyPackage = offerings!.current!.monthly;
          annualPackage = offerings!.current!.annual;

          for (final pkg in offerings!.current!.availablePackages) {
            final pkgId = pkg.identifier.toLowerCase();
            final prodId = pkg.storeProduct.identifier.toLowerCase();
            if (monthlyPackage == null &&
                (pkgId.contains('month') ||
                    pkgId == '\$rc_monthly' ||
                    prodId.contains('month'))) {
              monthlyPackage = pkg;
            }
            if (annualPackage == null &&
                (pkgId.contains('annu') ||
                    pkgId.contains('year') ||
                    pkgId == '\$rc_annual' ||
                    prodId.contains('year') ||
                    prodId.contains('annu'))) {
              annualPackage = pkg;
            }
          }
        }

        // 2. Search all offerings if current is missing or incomplete
        if (monthlyPackage == null || annualPackage == null) {
          for (final off in offerings!.all.values) {
            for (final pkg in off.availablePackages) {
              final pkgId = pkg.identifier.toLowerCase();
              final prodId = pkg.storeProduct.identifier.toLowerCase();
              if (monthlyPackage == null &&
                  (pkgId.contains('month') ||
                      pkgId == '\$rc_monthly' ||
                      prodId.contains('month'))) {
                monthlyPackage = pkg;
              }
              if (annualPackage == null &&
                  (pkgId.contains('annu') ||
                      pkgId.contains('year') ||
                      pkgId == '\$rc_annual' ||
                      prodId.contains('year') ||
                      prodId.contains('annu'))) {
                annualPackage = pkg;
              }
            }
          }
        }
      }

      // 3. Fallback: Query Google Play StoreProducts directly if offerings/packages are missing
      if (monthlyPackage == null || annualPackage == null) {
        try {
          final products = await Purchases.getProducts(
            [
              monthlyId,
              yearlyId,
              'nextmeet_plus_monthly:monthly-plus',
              'nextmeet_plus_yearly:yearly-plus',
            ],
            productCategory: ProductCategory.subscription,
          );
          for (final p in products) {
            if (p.identifier.contains('year') || p.identifier.contains('annual')) {
              annualProduct = p;
            } else if (p.identifier.contains('month')) {
              monthlyProduct = p;
            }
          }
        } catch (e) {
          debugPrint('Purchases.getProducts direct lookup notice: $e');
        }
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('RevenueCat loadOfferings notice: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  String getPriceById(String productId) {
    if (productId == yearlyId) {
      if (annualPackage != null) {
        return annualPackage!.storeProduct.priceString;
      }
      if (annualProduct != null) {
        return annualProduct!.priceString;
      }
      return '₹499';
    } else {
      if (monthlyPackage != null) {
        return monthlyPackage!.storeProduct.priceString;
      }
      if (monthlyProduct != null) {
        return monthlyProduct!.priceString;
      }
      return '₹49';
    }
  }

  EntitlementInfo? _getActiveEntitlement(CustomerInfo customerInfo) {
    final primary = customerInfo.entitlements.all[RevenueCatConfig.entitlementId];
    if (primary != null && primary.isActive) {
      return primary;
    }
    for (final ent in customerInfo.entitlements.active.values) {
      if (ent.isActive) return ent;
    }
    return null;
  }

  Future<bool> buyProduct(bool isYearly) async {
    if (_activeRelId == null) return false;
    final relId = _activeRelId!;

    // Re-fetch products if not loaded yet
    if ((isYearly && annualPackage == null && annualProduct == null) ||
        (!isYearly && monthlyPackage == null && monthlyProduct == null)) {
      await loadProducts();
    }

    final targetPackage = isYearly ? annualPackage : monthlyPackage;
    final targetProduct = isYearly ? annualProduct : monthlyProduct;

    if (targetPackage == null && targetProduct == null) {
      error =
          'Google Play billing is currently initializing or your account cannot access this test track. Please try again in a moment.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    notifyListeners();
    VibrationService.medium();

    try {
      final PurchaseResult purchaseResult;
      if (targetPackage != null) {
        purchaseResult = await Purchases.purchasePackage(targetPackage);
      } else {
        purchaseResult = await Purchases.purchaseStoreProduct(targetProduct!);
      }
      final customerInfo = purchaseResult.customerInfo;
      final activeEntitlement = _getActiveEntitlement(customerInfo);

      if (activeEntitlement != null) {
        DateTime? expiry;
        if (activeEntitlement.expirationDate != null) {
          try {
            expiry = DateTime.parse(activeEntitlement.expirationDate!);
          } catch (_) {}
        }
        await _deliverEntitlement(
          relId: relId,
          isYearly: isYearly ||
              activeEntitlement.productIdentifier.toLowerCase().contains('year') ||
              activeEntitlement.productIdentifier.toLowerCase().contains('annual'),
          transactionId: customerInfo.originalAppUserId,
          expirationDate: expiry,
        );
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        isLoading = false;
        notifyListeners();
        return false;
      }
    } on PlatformException catch (e) {
      isLoading = false;
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        error = null;
      } else if (errorCode == PurchasesErrorCode.paymentPendingError) {
        error = 'Your payment is pending approval in Google Play.';
      } else if (errorCode == PurchasesErrorCode.storeProblemError) {
        error = 'Google Play Store is temporarily unreachable. Please try again.';
      } else {
        error = 'Purchase could not be completed. Please check your payment method in Google Play.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      isLoading = false;
      error = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    if (_activeRelId == null) return false;
    final relId = _activeRelId!;

    isLoading = true;
    notifyListeners();
    try {
      final customerInfo = await Purchases.restorePurchases();
      final activeEntitlement = _getActiveEntitlement(customerInfo);
      if (activeEntitlement != null) {
        DateTime? expiry;
        if (activeEntitlement.expirationDate != null) {
          try {
            expiry = DateTime.parse(activeEntitlement.expirationDate!);
          } catch (_) {}
        }
        final bool isYearly = activeEntitlement.productIdentifier.toLowerCase().contains('year') ||
            activeEntitlement.productIdentifier.toLowerCase().contains('annual');
        await _deliverEntitlement(
          relId: relId,
          isYearly: isYearly,
          transactionId: customerInfo.originalAppUserId,
          expirationDate: expiry,
        );
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        error = 'No active NextMeet+ subscription found to restore.';
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Restore purchases error: $e');
      error = 'Unable to restore purchases. Please verify your Google account.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _handleCustomerInfoUpdate(CustomerInfo customerInfo) async {
    if (_activeRelId == null) return;
    final activeEntitlement = _getActiveEntitlement(customerInfo);
    
    if (activeEntitlement != null) {
      DateTime? expiry;
      if (activeEntitlement.expirationDate != null) {
        try {
          expiry = DateTime.parse(activeEntitlement.expirationDate!);
        } catch (_) {}
      }
      final bool isYearly = activeEntitlement.productIdentifier.toLowerCase().contains('year') ||
          activeEntitlement.productIdentifier.toLowerCase().contains('annual');
      await _deliverEntitlement(
        relId: _activeRelId!,
        isYearly: isYearly,
        transactionId: customerInfo.originalAppUserId,
        expirationDate: expiry,
      );
    } else {
      // Only downgrade if this couple previously had an active NextMeet+ subscription that has expired
      final currentRel = await _cloudService.getRelationshipById(_activeRelId!);
      if (currentRel != null && currentRel.isPlus) {
        // Guard: Do not downgrade prematurely if their paid subscription period is still active!
        if (currentRel.premiumRenewalDate != null &&
            currentRel.premiumRenewalDate!.isAfter(DateTime.now())) {
          return;
        }
        await _cloudService.downgradeToFree(_activeRelId!);
      }
    }
  }

  Future<void> _deliverEntitlement({
    required String relId,
    required bool isYearly,
    required String transactionId,
    DateTime? expirationDate,
  }) async {
    try {
      final String planType = isYearly ? 'NextMeet+ Annual' : 'NextMeet+ Monthly';
      final DateTime renewalDate = expirationDate ??
          (isYearly
              ? DateTime.now().add(const Duration(days: 365))
              : DateTime.now().add(const Duration(days: 30)));

      await _cloudService.activateRealPremium(
        relId: relId,
        planType: planType,
        transactionId: transactionId,
        renewalDate: renewalDate,
      );

      VibrationService.success();
    } catch (e) {
      debugPrint('Error delivering entitlement: $e');
    }
  }
}
