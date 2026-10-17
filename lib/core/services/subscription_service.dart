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
      // 1. Configure Purchases with RevenueCat API key and couple ID
      final configuration = PurchasesConfiguration(RevenueCatConfig.apiKey)
        ..appUserID = 'rel_$relId';
      
      await Purchases.configure(configuration);
      isAvailable = true;

      // 2. Load Offerings
      await loadProducts();

      // 3. Listen to real-time subscription status changes
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _handleCustomerInfoUpdate(customerInfo);
      });
    } catch (e) {
      debugPrint('RevenueCat initialization warning: $e');
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProducts() async {
    try {
      offerings = await Purchases.getOfferings();
      if (offerings?.current != null) {
        monthlyPackage = offerings!.current!.monthly;
        annualPackage = offerings!.current!.annual;
      }
      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('RevenueCat loadOfferings error: $e');
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  String getPriceById(String productId) {
    if (productId == yearlyId) {
      if (annualPackage != null) {
        return annualPackage!.storeProduct.priceString;
      }
      return '₹499';
    } else {
      if (monthlyPackage != null) {
        return monthlyPackage!.storeProduct.priceString;
      }
      return '₹49';
    }
  }

  Future<bool> buyProduct(bool isYearly) async {
    if (_activeRelId == null) return false;
    final relId = _activeRelId!;

    final targetPackage = isYearly ? annualPackage : monthlyPackage;
    if (targetPackage == null) {
      error = 'Package not configured yet in RevenueCat. Please add products to your RevenueCat Default Offering.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    notifyListeners();
    VibrationService.medium();

    try {
      final purchaseResult = await Purchases.purchasePackage(targetPackage);
      final customerInfo = purchaseResult.customerInfo;
      final isEntitled = customerInfo.entitlements.all[RevenueCatConfig.entitlementId]?.isActive == true;

      if (isEntitled) {
        await _deliverEntitlement(
          relId: relId,
          isYearly: isYearly,
          transactionId: customerInfo.originalAppUserId,
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
      } else {
        error = e.message ?? e.toString();
      }
      notifyListeners();
      return false;
    } catch (e) {
      isLoading = false;
      error = e.toString();
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
      final isEntitled = customerInfo.entitlements.all[RevenueCatConfig.entitlementId]?.isActive == true;
      if (isEntitled) {
        await _deliverEntitlement(
          relId: relId,
          isYearly: false,
          transactionId: customerInfo.originalAppUserId,
        );
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        error = 'No active NextMeet Plus subscription found to restore.';
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _handleCustomerInfoUpdate(CustomerInfo customerInfo) async {
    if (_activeRelId == null) return;
    final isEntitled = customerInfo.entitlements.all[RevenueCatConfig.entitlementId]?.isActive == true;
    if (isEntitled) {
      await _deliverEntitlement(
        relId: _activeRelId!,
        isYearly: false,
        transactionId: customerInfo.originalAppUserId,
      );
    } else {
      await _cloudService.downgradeToFree(_activeRelId!);
    }
  }

  Future<void> _deliverEntitlement({
    required String relId,
    required bool isYearly,
    required String transactionId,
  }) async {
    try {
      final String planType = isYearly ? 'Annual Sanctuary' : 'Monthly Sanctuary';
      final DateTime renewalDate = isYearly
          ? DateTime.now().add(const Duration(days: 365))
          : DateTime.now().add(const Duration(days: 30));

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
