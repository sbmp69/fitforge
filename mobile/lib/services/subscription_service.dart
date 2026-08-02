import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SubscriptionService {
  // The key is loaded from the .env file for security
  static String get _revenueCatApiKey => dotenv.env['REVENUECAT_API_KEY_ANDROID'] ?? '';

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
      final result = await Purchases.purchasePackage(package);
      if (result.customerInfo.entitlements.all['premium']?.isActive == true) {
        _isPremium = true;
        return true;
      }
    } catch (e) {
      debugPrint('Failed to purchase package: $e');
    }
    return false;
  }

  static Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      if (customerInfo.entitlements.all['premium']?.isActive == true) {
        _isPremium = true;
        return true;
      }
    } catch (e) {
      debugPrint('Failed to restore purchases: $e');
    }
    return false;
  }
}
