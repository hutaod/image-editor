import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'dart:io';
import 'vip_service.dart';

/// RevenueCat 购买系统服务
class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  final VipService _vipService = VipService();

  // 初始化状态
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// 初始化 RevenueCat 购买系统
  /// [uid] 用户ID，从外部传入
  Future<void> initPurchaseSDK(String uid) async {
    if (_isInitialized) {
      print('RevenueCat 已经初始化过了');
      return;
    }

    WidgetsFlutterBinding.ensureInitialized();
    try {
      await Purchases.setLogLevel(LogLevel.debug);

      PurchasesConfiguration? configuration;

      if (Platform.isIOS) {
        configuration = PurchasesConfiguration(
          "appl_fvBjWrRCVMQeBLdvMQtsrORuwUc",
        );
      } else if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(
          "goog_LDIQikhvPVMyuCQszbsLnhUqwvW",
        );
      } else {
        print('不支持的平台: ${Platform.operatingSystem}');
        return;
      }
      print('configuration123: $configuration');

      configuration.appUserID = uid;

      await Purchases.configure(configuration);

      _isInitialized = true;
      print('RevenueCat 初始化成功，用户ID: $uid');
    } catch (e) {
      print('RevenueCat 初始化失败: $e');
      _isInitialized = false;
    }
  }

  /// 显示应用内购买付费墙
  Future<bool> showIAPPaywall() async {
    if (!_isInitialized) {
      print('RevenueCat 未初始化');
      return false;
    }

    PaywallResult? paywallResult;
    try {
      paywallResult = await RevenueCatUI.presentPaywall();
    } catch (e) {
      print('Paywall error: $e');
      return false;
    }

    if (paywallResult == PaywallResult.purchased) {
      try {
        CustomerInfo customerInfo = await Purchases.getCustomerInfo();
        if (customerInfo.entitlements.all["Pro"]?.isActive ?? false) {
          print('VIP购买成功');
          // 购买成功后刷新服务器端会员状态
          await _vipService.refreshVipStatus();
          return true;
        }
      } catch (e) {
        print('获取用户信息失败: $e');
      }
    } else if (paywallResult == PaywallResult.cancelled) {
      print('用户取消购买');
    } else if (paywallResult == PaywallResult.error) {
      print('购买失败');
    }

    return false;
  }

  /// 恢复购买
  Future<bool> restorePurchases() async {
    try {
      if (!_isInitialized) {
        print('RevenueCat 未初始化');
        return false;
      }

      await Purchases.restorePurchases();
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      if (customerInfo.entitlements.all["Pro"]?.isActive ?? false) {
        print('恢复购买成功');
        // 恢复购买成功后也刷新会员状态
        await _vipService.refreshVipStatus();
        return true;
      }
      print('恢复购买完成，但未找到有效订阅');
      return false;
    } catch (e) {
      print('恢复购买失败: $e');
      return false;
    }
  }

  /// 检查用户是否为会员
  Future<bool> isPremiumUser() async {
    try {
      if (!_isInitialized) {
        print('RevenueCat 未初始化');
        return false;
      }

      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all["Pro"]?.isActive ?? false;
    } catch (e) {
      print('检查会员状态失败: $e');
      return false;
    }
  }

  /// 获取用户信息
  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      if (!_isInitialized) {
        print('RevenueCat 未初始化');
        return null;
      }

      return await Purchases.getCustomerInfo();
    } catch (e) {
      print('获取用户信息失败: $e');
      return null;
    }
  }

  /// 获取可用的产品列表
  Future<List<StoreProduct>> getAvailableProducts() async {
    try {
      if (!_isInitialized) {
        print('RevenueCat 未初始化');
        return [];
      }

      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        final products = <StoreProduct>[];
        for (final package in offerings.current!.availablePackages) {
          products.add(package.storeProduct);
        }
        return products;
      }
      return [];
    } catch (e) {
      print('获取产品列表失败: $e');
      return [];
    }
  }

  /// 购买指定产品
  Future<bool> purchaseProduct(StoreProduct product) async {
    try {
      if (!_isInitialized) {
        print('RevenueCat 未初始化');
        return false;
      }

      final purchaseResult = await Purchases.purchaseStoreProduct(product);

      if (purchaseResult.customerInfo.entitlements.all["Pro"]?.isActive ??
          false) {
        print('产品购买成功: ${product.identifier}');
        // 购买成功后刷新会员状态
        await _vipService.refreshVipStatus();
        return true;
      }

      return false;
    } catch (e) {
      print('购买产品失败: $e');
      return false;
    }
  }

  /// 购买指定套餐
  Future<bool> purchasePackage(Package package) async {
    try {
      if (!_isInitialized) {
        print('RevenueCat 未初始化');
        return false;
      }

      final purchaseResult = await Purchases.purchasePackage(package);

      if (purchaseResult.customerInfo.entitlements.all["Pro"]?.isActive ??
          false) {
        print('套餐购买成功: ${package.identifier}');
        // 购买成功后刷新会员状态
        await _vipService.refreshVipStatus();
        return true;
      }

      return false;
    } catch (e) {
      print('购买套餐失败: $e');
      return false;
    }
  }

  /// 获取当前套餐信息
  Future<Offerings?> getCurrentOfferings() async {
    try {
      if (!_isInitialized) {
        print('RevenueCat 未初始化');
        return null;
      }

      return await Purchases.getOfferings();
    } catch (e) {
      print('获取套餐信息失败: $e');
      return null;
    }
  }

  /// 检查特定权益是否激活
  Future<bool> hasActiveEntitlement(String entitlementId) async {
    try {
      if (!_isInitialized) {
        print('RevenueCat 未初始化');
        return false;
      }

      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (e) {
      print('检查权益状态失败: $e');
      return false;
    }
  }

  /// 获取用户购买历史
  Future<List<Map<String, dynamic>>> getPurchaseHistory() async {
    try {
      if (!_isInitialized) {
        print('RevenueCat 未初始化');
        return [];
      }

      final customerInfo = await Purchases.getCustomerInfo();
      final transactions = <Map<String, dynamic>>[];

      for (final entry in customerInfo.allPurchaseDates.entries) {
        transactions.add({
          'productIdentifier': entry.key,
          'purchaseDate': entry.value,
          'transactionIdentifier': entry.key,
        });
      }

      return transactions;
    } catch (e) {
      print('获取购买历史失败: $e');
      return [];
    }
  }

  /// 设置用户属性
  Future<void> setUserAttributes(Map<String, String> attributes) async {
    try {
      if (!_isInitialized) {
        print('RevenueCat 未初始化');
        return;
      }

      for (final entry in attributes.entries) {
        await Purchases.setAttributes({entry.key: entry.value});
      }

      print('用户属性设置成功: $attributes');
    } catch (e) {
      print('设置用户属性失败: $e');
    }
  }

  /// 同步本地会员状态与RevenueCat
  Future<void> syncVipStatus() async {
    try {
      if (!_isInitialized) {
        print('RevenueCat 未初始化');
        return;
      }

      final isPremium = await isPremiumUser();
      await _vipService.setMockVipStatus(isPremium);

      print('会员状态同步完成: $isPremium');
    } catch (e) {
      print('同步会员状态失败: $e');
    }
  }
}
