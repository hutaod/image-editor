import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
// import 'dart:developer' as developer;
import 'network_service.dart';

/// 公共打印函数
void log(String message, {String? name, int level = 500}) {
  if (kDebugMode) {
    // 使用 developer.log 输出专业日志
    // developer.log(message, name: name ?? 'VipService', level: level);

    // // 同时使用 debugPrint 确保在 Flutter 控制台可见
    // debugPrint('[$name] $message');
  }
}

/// VIP会员服务
class VipService {
  static final VipService _instance = VipService._internal();
  factory VipService() => _instance;
  VipService._internal();

  final NetworkService _networkService = NetworkService();

  // 本地存储的键名
  static const String _vipStatusKey = 'vip_status';
  static const String _vipExpireTimeKey = 'vip_expire_time';
  static const String _hiddenEventsCountKey = 'hidden_events_count';

  /// 刷新会员状态
  Future<bool> refreshVipStatus() async {
    try {
      log('🔄 开始刷新会员状态...', name: 'VipService');

      // 调用服务器API获取会员状态
      log('📡 发送会员状态请求到: /api/vip/refresh', name: 'VipService');

      // 发送POST请求，包含请求体
      final response = await _networkService.post('/api/vip/refresh');

      log('📡 会员状态响应状态码: ${response.statusCode}', name: 'VipService');
      log('📡 会员状态响应数据: ${response.data}', name: 'VipService');

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        log('📡 解析响应数据: $responseData', name: 'VipService');

        // 从嵌套的data字段中获取实际数据
        final data = responseData['data'] as Map<String, dynamic>?;
        if (data == null) {
          log('❌ 响应数据中缺少data字段', name: 'VipService');
          return false;
        }

        final isVip = data['isPremium'] ?? false;

        // expiryDate是毫秒时间戳，直接转换
        String? expireTime;
        final expiryDateValue = data['expiryDate'];
        if (expiryDateValue != null) {
          final dateTime = DateTime.fromMillisecondsSinceEpoch(expiryDateValue);
          expireTime = dateTime.toIso8601String();
        }

        log(
          '📡 解析结果: isVip=$isVip, expireTime=$expireTime',
          name: 'VipService',
        );

        // 保存到本地
        await _saveVipStatus(isVip, expireTime);

        // 验证保存结果
        final savedVip = await isVipUser();
        log(
          '✅ 会员状态刷新成功: isVip=$isVip, expireTime=$expireTime, 本地验证=$savedVip',
          name: 'VipService',
        );
        return true;
      } else {
        log('❌ 获取会员状态失败: ${response.statusCode}', name: 'VipService');
        log('❌ 错误响应: ${response.data}', name: 'VipService');
        return false;
      }
    } catch (e) {
      log('❌ 刷新会员状态异常: $e', name: 'VipService');
      if (e.toString().contains('DioException')) {
        log('❌ 网络请求异常详情: $e', name: 'VipService');
      }
      return false;
    }
  }

  /// 检查是否为VIP用户
  Future<bool> isVipUser() async {
    try {
      log('🔍 开始检查VIP用户状态...', name: 'VipService');

      final prefs = await SharedPreferences.getInstance();
      final isVip = prefs.getBool(_vipStatusKey) ?? false;
      final expireTimeStr = prefs.getString(_vipExpireTimeKey);

      log(
        '🔍 本地存储状态: isVip=$isVip, expireTimeStr=$expireTimeStr',
        name: 'VipService',
      );

      if (!isVip || expireTimeStr == null) {
        log('🔍 非VIP用户或过期时间为空', name: 'VipService');
        return false;
      }

      // 检查是否过期
      final expireTime = DateTime.tryParse(expireTimeStr);
      final now = DateTime.now();
      log('🔍 过期时间解析: $expireTime, 当前时间: $now', name: 'VipService');

      if (expireTime == null || expireTime.isBefore(now)) {
        log('🔍 会员已过期，更新本地状态', name: 'VipService');
        // 已过期，更新本地状态
        await _saveVipStatus(false, null);
        return false;
      }

      log('✅ 用户是有效VIP，过期时间: $expireTime', name: 'VipService');
      return true;
    } catch (e) {
      log('❌ 检查VIP状态失败: $e', name: 'VipService');
      return false;
    }
  }

  /// 获取VIP过期时间
  Future<DateTime?> getVipExpireTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expireTimeStr = prefs.getString(_vipExpireTimeKey);

      if (expireTimeStr != null) {
        return DateTime.tryParse(expireTimeStr);
      }

      return null;
    } catch (e) {
      log('获取VIP过期时间失败: $e', name: 'VipService');
      return null;
    }
  }

  /// 保存VIP状态到本地
  Future<void> _saveVipStatus(bool isVip, String? expireTime) async {
    try {
      log(
        '💾 开始保存VIP状态到本地: isVip=$isVip, expireTime=$expireTime',
        name: 'VipService',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_vipStatusKey, isVip);
      log('💾 已保存VIP状态: $isVip', name: 'VipService');

      if (expireTime != null) {
        await prefs.setString(_vipExpireTimeKey, expireTime);
        log('💾 已保存过期时间: $expireTime', name: 'VipService');
      } else {
        await prefs.remove(_vipExpireTimeKey);
        log('💾 已清除过期时间', name: 'VipService');
      }

      // 验证保存结果
      final savedIsVip = prefs.getBool(_vipStatusKey);
      final savedExpireTime = prefs.getString(_vipExpireTimeKey);
      log(
        '✅ VIP状态保存完成: 验证isVip=$savedIsVip, 验证expireTime=$savedExpireTime',
        name: 'VipService',
      );
    } catch (e) {
      log('❌ 保存VIP状态失败: $e', name: 'VipService');
    }
  }

  /// 清除VIP状态
  Future<void> clearVipStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_vipStatusKey);
      await prefs.remove(_vipExpireTimeKey);
      log('VIP状态已清除', name: 'VipService');
    } catch (e) {
      log('清除VIP状态失败: $e', name: 'VipService');
    }
  }

  /// 设置模拟VIP状态（用于测试）
  Future<void> setMockVipStatus(bool isVip, {DateTime? expireTime}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_vipStatusKey, isVip);

      if (expireTime != null) {
        await prefs.setString(_vipExpireTimeKey, expireTime.toIso8601String());
      } else if (isVip) {
        // 如果没有指定过期时间，设置为一年后
        final oneYearLater = DateTime.now().add(const Duration(days: 365));
        await prefs.setString(
          _vipExpireTimeKey,
          oneYearLater.toIso8601String(),
        );
      } else {
        await prefs.remove(_vipExpireTimeKey);
      }

      log(
        '模拟VIP状态已设置: isVip=$isVip, expireTime=$expireTime',
        name: 'VipService',
      );
    } catch (e) {
      log('设置模拟VIP状态失败: $e', name: 'VipService');
    }
  }

  /// 获取已隐藏事件数量
  Future<int> getHiddenEventsCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_hiddenEventsCountKey) ?? 0;
    } catch (e) {
      log('获取隐藏事件数量失败: $e', name: 'VipService');
      return 0;
    }
  }

  /// 增加隐藏事件计数
  Future<void> incrementHiddenEventsCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = await getHiddenEventsCount();
      await prefs.setInt(_hiddenEventsCountKey, currentCount + 1);
      log('隐藏事件计数已增加: ${currentCount + 1}', name: 'VipService');
    } catch (e) {
      log('增加隐藏事件计数失败: $e', name: 'VipService');
    }
  }

  /// 减少隐藏事件计数
  Future<void> decrementHiddenEventsCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = await getHiddenEventsCount();
      if (currentCount > 0) {
        await prefs.setInt(_hiddenEventsCountKey, currentCount - 1);
        log('隐藏事件计数已减少: ${currentCount - 1}', name: 'VipService');
      }
    } catch (e) {
      log('减少隐藏事件计数失败: $e', name: 'VipService');
    }
  }

  /// 重置隐藏事件计数
  Future<void> resetHiddenEventsCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_hiddenEventsCountKey, 0);
      log('隐藏事件计数已重置', name: 'VipService');
    } catch (e) {
      log('重置隐藏事件计数失败: $e', name: 'VipService');
    }
  }

  /// 检查是否可以隐藏事件
  Future<bool> canHideEvent() async {
    try {
      final isVip = await isVipUser();
      if (isVip) {
        return true; // 会员可以无限制隐藏
      }

      final hiddenCount = await getHiddenEventsCount();
      return hiddenCount < 3; // 非会员最多隐藏3个
    } catch (e) {
      log('检查是否可以隐藏事件失败: $e', name: 'VipService');
      return false;
    }
  }

  /// 获取剩余免费隐藏次数
  Future<int> getRemainingFreeHides() async {
    try {
      final isVip = await isVipUser();
      if (isVip) {
        return -1; // 会员无限制，返回-1表示无限制
      }

      final hiddenCount = await getHiddenEventsCount();
      return 3 - hiddenCount; // 最多3个免费隐藏
    } catch (e) {
      log('获取剩余免费隐藏次数失败: $e', name: 'VipService');
      return 0;
    }
  }
}
