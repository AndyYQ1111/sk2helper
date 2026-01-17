import 'package:flutter/services.dart';
import 'package:sk2helper/models.dart';

import 'sk2helper_platform_interface.dart';

class Sk2helper {
  static final _methodChannel = const MethodChannel('sk2helper');

  Future<String?> getPlatformVersion() {
    return Sk2helperPlatform.instance.getPlatformVersion();
  }

  // 初始化
  static Future<void> initialize() async {
    await _methodChannel.invokeMethod('initialize');
  }

  // 获取产品列表
  static Future<List<Product>> fetchProducts(List<String> productIDs) async {
    try {
      final List<dynamic> productList = await _methodChannel.invokeMethod(
        'fetchProducts',
        {"productIDs": productIDs},
      );

      return productList.map((product) {
        return Product.fromMap(Map<String, dynamic>.from(product));
      }).toList();
    } on PlatformException catch (e) {
      throw StoreKitError(e.code, e.message);
    }
  }

  // 购买产品
  static Future<Transaction> purchase(String productId) async {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        await _methodChannel.invokeMethod('buyProduct', {
          'productId': productId,
        }),
      );
      return Transaction.fromMap(result);
    } on PlatformException catch (e) {
      throw StoreKitError(e.code, e.message, data: e.details);
    }
  }

  // 恢复购买
  static Future<List<RestoredPurchase>> restore() async {
    try {
      final List<dynamic> result = await _methodChannel.invokeMethod(
        'restorePurchases',
      );
      return result.map((item) {
        return RestoredPurchase.fromMap(Map<String, dynamic>.from(item));
      }).toList();
    } on PlatformException catch (e) {
      throw StoreKitError(e.code, e.message);
    }
  }

  // 检查是否有活跃订阅
  static Future<bool> hasActiveSubscription() async {
    try {
      return await _methodChannel.invokeMethod('hasActiveSubscription');
    } on PlatformException catch (e) {
      throw StoreKitError(e.code, e.message);
    }
  }

  // 获取购买历史
  static Future<List<String>> fetchPurchaseHistory() async {
    try {
      final List<dynamic> history = await _methodChannel.invokeMethod(
        'getPurchaseHistory',
      );
      return history.cast<String>();
    } on PlatformException catch (e) {
      throw StoreKitError(e.code, e.message);
    }
  }

  // 获取订阅状态
  static Future<Subscription?> getSubscriptionStatus(String productId) async {
    try {
      final dynamic result = await _methodChannel.invokeMethod(
        'getSubscriptionStatus',
        {'productId': productId},
      );
      if (result == null) return null;
      return Subscription.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw StoreKitError(e.code, e.message);
    }
  }
}
