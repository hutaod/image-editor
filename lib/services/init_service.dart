import 'network_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'vip_service.dart';
import 'revenue_cat_service.dart';
import 'data_migration_service.dart';
import 'umeng_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/event_record.dart';

class InitService {
  static final NetworkService _networkService = NetworkService();
  static final RevenueCatService _revenueCatService = RevenueCatService();
  static final VipService _vipService = VipService();
  static final UmengService _umengService = UmengService();

  /// 应用初始化 - 只调用用户初始化
  static Future<Map<String, dynamic>?> initApp() async {
    try {
      print('开始应用初始化...');

      // 1. 首先生成Token并设置认证信息
      final authSuccess = await _networkService.initializeAuth();
      if (!authSuccess) {
        print('认证初始化失败，无法继续初始化');
        return null;
      }

      // 2. 调用用户初始化API
      final userInitResult = await initUser();
      if (userInitResult == null) {
        print('用户初始化失败，无法继续初始化');
        return null;
      }

      // 3. 保存用户信息到本地
      await _saveUserInfo(userInitResult);

      // 4. 异步初始化 RevenueCat，不阻塞主流程
      _initRevenueCatAsync();

      // 5. 刷新会员状态（在用户信息获取后）
      await refreshVipStatus();

      // 6. 异步执行图片迁移，不阻塞主流程
      _migrateImagesAsync();

      // 7. 异步初始化友盟统计，不阻塞主流程
      _initUmengAsync();

      return userInitResult;
    } catch (e) {
      print('应用初始化异常: $e');
      return null;
    }
  }

  /// 异步初始化 RevenueCat，失败不影响主流程
  static void _initRevenueCatAsync() async {
    try {
      final deviceId = await _networkService.getDeviceId();
      await _revenueCatService.initPurchaseSDK(deviceId);
      print('RevenueCat 异步初始化成功');
    } catch (e) {
      print('RevenueCat 异步初始化失败: $e');
      // 失败不影响主流程，继续执行
    }
  }

  /// 刷新会员状态（在用户信息获取后调用）
  static Future<void> refreshVipStatus() async {
    try {
      print('🚀 InitService: 开始刷新会员状态...');
      final success = await _vipService.refreshVipStatus();
      if (success) {
        print('✅ InitService: 会员状态刷新成功');
      } else {
        print('❌ InitService: 会员状态刷新失败');
      }
    } catch (e) {
      print('❌ InitService: 刷新会员状态异常: $e');
    }
  }

  /// 用户初始化
  static Future<Map<String, dynamic>?> initUser() async {
    try {
      print('开始用户初始化...');

      // 获取设备信息
      final bundleId = await _networkService.getBundleId();
      final deviceId = await _networkService.getDeviceId();

      print('设备信息: bundleId=$bundleId, deviceId=$deviceId');
      print('请求体中的deviceId: $deviceId');
      print('Header中的device-id: $deviceId (通过拦截器自动添加)');

      // 准备请求体
      final requestBody = {'bundleId': bundleId, 'deviceId': deviceId};

      print('发送用户初始化请求: $requestBody');

      // 发送POST请求
      final response = await _networkService.post(
        '/api/user/init',
        data: requestBody,
      );

      print('用户初始化响应状态码: ${response.statusCode}');
      print('用户初始化响应数据: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('用户初始化成功: $data');
        return data;
      } else {
        print('用户初始化失败: ${response.statusCode}');
        print('错误响应: ${response.data}');
        return null;
      }
    } catch (e) {
      print('用户初始化异常: $e');
      if (e.toString().contains('DioException')) {
        print('网络请求异常详情: $e');
      }
      return null;
    }
  }

  /// 保存用户信息到本地
  static Future<void> _saveUserInfo(Map<String, dynamic> userInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_info', jsonEncode(userInfo));
      print('用户信息已保存到本地');
    } catch (e) {
      print('保存用户信息失败: $e');
    }
  }

  /// 获取用户信息
  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoString = prefs.getString('user_info');
      if (userInfoString != null) {
        return jsonDecode(userInfoString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('获取用户信息失败: $e');
      return null;
    }
  }

  /// 异步初始化友盟统计，失败不影响主流程
  static void _initUmengAsync() async {
    try {
      final success = await _umengService.init(
        androidAppKey: '6909adac8560e34872debb5c',
        iosAppKey: '6909adcd644c9e2c20713eea',
        channel: 'default',
      );
      if (success) {
        print('友盟统计初始化成功');
      } else {
        print('友盟统计初始化失败');
      }
    } catch (e) {
      print('友盟统计初始化异常: $e');
      // 失败不影响主流程，继续执行
    }
  }

  /// 异步执行图片迁移，不阻塞主流程
  static void _migrateImagesAsync() async {
    try {
      print('开始图片迁移...');

      // 获取所有记录
      final recordsBox = Hive.box<EventRecord>('event_records');
      final records = recordsBox.values.toList();

      if (records.isEmpty) {
        print('没有记录需要迁移');
        return;
      }

      final migrationService = DataMigrationService();

      // 更新图片路径到当前沙盒位置
      print('开始更新图片路径到当前沙盒位置...');

      // 执行路径更新
      await migrationService.updateImagePathsToCurrentSandbox(records, (
        updatedRecord,
      ) {
        // 更新记录到数据库
        recordsBox.put(updatedRecord.id, updatedRecord);
      });

      print('图片迁移完成');
    } catch (e) {
      print('图片迁移失败: $e');
    }
  }
}
