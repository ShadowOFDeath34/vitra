import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat entegrasyonu.
/// Ürün ID'leri: RevenueCat dashboard'da tanımlanacak.
class PremiumService {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  static const _entitlementId = 'Vitra Pro';

  Future<void> init() async {
    final androidKey = dotenv.env['REVENUECAT_ANDROID_KEY'] ?? '';
    final iosKey     = dotenv.env['REVENUECAT_IOS_KEY'] ?? '';

    await Purchases.setLogLevel(LogLevel.error);

    final String key;
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (androidKey.isEmpty || androidKey.startsWith('BURAYA')) return;
      key = androidKey;
    } else {
      if (iosKey.isEmpty || iosKey.startsWith('BURAYA')) return;
      key = iosKey;
    }

    await Purchases.configure(PurchasesConfiguration(key));
  }

  Future<bool> isPremium() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(_entitlementId);
    } catch (_) {
      return false;
    }
  }

  Future<List<Package>> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> purchase(Package package) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return result.customerInfo.entitlements.active
          .containsKey(_entitlementId);
    } on PurchasesErrorCode catch (_) {
      return false;
    }
  }

  Future<bool> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.containsKey(_entitlementId);
    } catch (_) {
      return false;
    }
  }
}
