import 'package:fl_umeng/fl_umeng.dart';
import 'package:flutter/foundation.dart';

/// 友盟统计服务
class UmengService {
  static final UmengService _instance = UmengService._internal();
  factory UmengService() => _instance;
  UmengService._internal();

  bool _isInitialized = false;

  /// 初始化友盟SDK
  /// [androidAppKey] Android平台的AppKey
  /// [iosAppKey] iOS平台的AppKey
  /// [channel] 渠道名称，默认为"default"
  Future<bool> init({
    required String androidAppKey,
    required String iosAppKey,
    String channel = 'default',
  }) async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('友盟SDK已经初始化');
      }
      return true;
    }

    try {
      final result = await FlUMeng().init(
        androidAppKey: androidAppKey,
        iosAppKey: iosAppKey,
        channel: channel,
      );

      if (result == true) {
        _isInitialized = true;

        // 禁用应用列表收集，以符合Google Play隐私政策要求
        // enableAplCollection = false 禁用已安装应用列表收集
        await FlUMeng().setAnalyticsEnabled(
          enabled: true, // iOS: 保持统计功能开启
          enableAplCollection: false, // Android: 禁用应用列表收集
          enableImeiCollection: false, // 禁用IMEI收集
          enableImsiCollection: false, // 禁用IMSI收集
          enableIccidCollection: false, // 禁用ICCID收集
          enableUmcCfgSwitch: true, // 保持配置开关
          enableWiFiMacCollection: false, // 禁用WiFi MAC收集
        );

        if (kDebugMode) {
          print('友盟SDK初始化成功，已禁用应用列表收集');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('友盟SDK初始化失败');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('友盟SDK初始化异常: $e');
      }
      return false;
    }
  }

  /// 注意：友盟SDK初始化后会自动统计DAU，无需手动调用onResume/onPause
  /// 这些方法在原生SDK层面自动处理

  /// 页面开始统计
  Future<void> onPageStart(String pageName) async {
    if (!_isInitialized) {
      return;
    }

    try {
      await FlUMeng().onPageStart(pageName);
    } catch (e) {
      if (kDebugMode) {
        print('友盟页面开始统计异常: $e');
      }
    }
  }

  /// 页面结束统计
  Future<void> onPageEnd(String pageName) async {
    if (!_isInitialized) {
      return;
    }

    try {
      await FlUMeng().onPageEnd(pageName);
    } catch (e) {
      if (kDebugMode) {
        print('友盟页面结束统计异常: $e');
      }
    }
  }

  /// 自定义事件统计
  Future<void> onEvent(
    String eventName, {
    Map<String, dynamic>? properties,
  }) async {
    if (!_isInitialized) {
      return;
    }

    try {
      await FlUMeng().onEvent(eventName, properties ?? {});
    } catch (e) {
      if (kDebugMode) {
        print('友盟自定义事件统计异常: $e');
      }
    }
  }

  /// 用户登录（设置用户ID）
  Future<void> signIn(String userId) async {
    if (!_isInitialized) {
      return;
    }

    try {
      await FlUMeng().signIn(userId);
      if (kDebugMode) {
        print('友盟用户登录: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('友盟用户登录异常: $e');
      }
    }
  }

  /// 用户登出
  Future<void> signOff() async {
    if (!_isInitialized) {
      return;
    }

    try {
      await FlUMeng().signOff();
      if (kDebugMode) {
        print('友盟用户登出');
      }
    } catch (e) {
      if (kDebugMode) {
        print('友盟用户登出异常: $e');
      }
    }
  }
}
