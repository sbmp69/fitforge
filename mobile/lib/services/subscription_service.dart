import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  // TODO: Replace with your actual RevenueCat Public App-Specific API Key
  static const String _revenueCatApiKey = 'goog_XXXXXXXXXXXXXXXXXXXXXXXXX';

  static bool _isPremium = false;
  static bool get isPremium => _isPremium;

  static Future<void> initialize() async {
    try {
      await Purchases.setLogLevel(LogLevel.debug);
      
      PurchasesConfiguration configuration;
      if (defaultTargetPlatform == TargetPlatform.android) {
        configuration = PurchasesConfiguration(_revenueCatApiKey);
        await Purchases.configure(configuration);
      }
      
      await updatePremiumStatus();
    } catch (e) {
      debugPrint('Failed to initialize RevenueCat: $e');
    }
  }

  static Future<void> updatePremiumStatus() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      // "premium" is the default entitlement identifier in RevenueCat
      if (customerInfo.entitlements.all['premium']?.isActive == true) {
        _isPremium = true;
      } else {
        _isPremium = false;
      }
    } catch (e) {
      debugPrint('Failed to get customer info: $e');
      _isPremium = false;
    }
  }

  static Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('Failed to fetch offerings: $e');
      return null;
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    try {
      CustomerInfo customerInfo = await Purchases.purchasePackage(package);
      if (customerInfo.entitlements.all['premium']?.isActive == true) {
        _isPremium = true;
        return true;
      }
    } catch (e) {
      debugPrint('Failed to purchase package: $e');
    }
    return false;
  }
}
