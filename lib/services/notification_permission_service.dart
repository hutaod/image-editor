import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 通知权限管理服务
/// 负责检测权限状态、处理权限请求、检测国产ROM限制等
class NotificationPermissionService {
  NotificationPermissionService._();
  static final NotificationPermissionService instance =
      NotificationPermissionService._();

  bool? _isDomesticROM;
  PermissionStatus? _notificationPermissionStatus;
  PermissionStatus? _calendarPermissionStatus;

  // 首次启动权限处理标记
  static const String _firstLaunchPermissionKey =
      'first_launch_permission_handled';
  static const String _firstLaunchCalendarPermissionKey =
      'first_launch_calendar_permission_handled';

  /// 检测是否为国产ROM（可能限制后台运行）
  Future<bool> isDomesticROM() async {
    if (_isDomesticROM != null) {
      return _isDomesticROM!;
    }

    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;

        final brand = androidInfo.brand.toLowerCase();
        final manufacturer = androidInfo.manufacturer.toLowerCase();

        // 检测国产主流品牌
        final isChineseBrand =
            brand.contains('huawei') ||
            brand.contains('xiaomi') ||
            brand.contains('oppo') ||
            brand.contains('vivo') ||
            brand.contains('oneplus') ||
            brand.contains('meizu') ||
            brand.contains('realme') ||
            brand.contains('honor') ||
            manufacturer.contains('huawei') ||
            manufacturer.contains('xiaomi') ||
            manufacturer.contains('oppo') ||
            manufacturer.contains('vivo') ||
            manufacturer.contains('oneplus') ||
            manufacturer.contains('meizu') ||
            manufacturer.contains('realme') ||
            manufacturer.contains('honor');

        // 检测国产定制系统特征
        final isChineseROM =
            androidInfo.systemFeatures.contains('android.hardware.telephony') ||
            androidInfo.model.toLowerCase().contains('mi') ||
            androidInfo.model.toLowerCase().contains('huawei') ||
            androidInfo.model.toLowerCase().contains('oppo') ||
            androidInfo.model.toLowerCase().contains('vivo');

        _isDomesticROM = isChineseBrand || isChineseROM;

        if (kDebugMode) {
          print('Debug: 国产ROM检测 - 品牌: $brand, 制造商: $manufacturer');
          print('Debug: 国产ROM检测 - 国产品牌: $isChineseBrand, 国产ROM: $isChineseROM');
          print('Debug: 最终结果: $_isDomesticROM');
        }
      } else {
        _isDomesticROM = false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Debug: 国产ROM检测失败: $e');
      }
      _isDomesticROM = false;
    }

    return _isDomesticROM!;
  }

  /// 检查通知权限状态
  Future<PermissionStatus> getNotificationPermissionStatus() async {
    try {
      _notificationPermissionStatus = await Permission.notification.status;
      return _notificationPermissionStatus!;
    } catch (e) {
      if (kDebugMode) {
        print('Debug: 获取通知权限状态失败: $e');
      }
      return PermissionStatus.denied;
    }
  }

  /// 请求通知权限（避免重复请求）
  Future<PermissionStatus> requestNotificationPermission() async {
    try {
      final currentStatus = await getNotificationPermissionStatus();

      // 如果已经授权，直接返回
      if (currentStatus.isGranted) {
        if (kDebugMode) {
          print('Debug: 通知权限已授权，无需重复请求');
        }
        return currentStatus;
      }

      // 如果被永久拒绝，直接返回状态
      if (currentStatus.isPermanentlyDenied) {
        if (kDebugMode) {
          print('Debug: 通知权限被永久拒绝');
        }
        return currentStatus;
      }

      // 请求权限
      if (kDebugMode) {
        print('Debug: 开始请求通知权限');
      }

      _notificationPermissionStatus = await Permission.notification.request();

      if (kDebugMode) {
        print('Debug: 通知权限请求结果: ${_notificationPermissionStatus!.name}');
      }

      return _notificationPermissionStatus!;
    } catch (e) {
      if (kDebugMode) {
        print('Debug: 请求通知权限失败: $e');
      }
      return PermissionStatus.denied;
    }
  }

  /// 检查是否已经处理过首次启动的权限请求
  Future<bool> hasHandledFirstLaunchPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_firstLaunchPermissionKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Debug: 检查首次启动权限处理状态失败: $e');
      }
      return false;
    }
  }

  /// 标记首次启动权限已处理
  Future<void> markFirstLaunchPermissionHandled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_firstLaunchPermissionKey, true);
      if (kDebugMode) {
        print('Debug: 已标记首次启动权限处理完成');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Debug: 标记首次启动权限处理失败: $e');
      }
    }
  }

  /// 检查是否应该显示权限引导（避免与系统弹窗重复）
  Future<bool> shouldShowPermissionGuide() async {
    final status = await getNotificationPermissionStatus();

    if (kDebugMode) {
      print(
        'Debug: 权限状态检查 - 状态: ${status.name}, 平台: ${Platform.operatingSystem}',
      );
    }

    // 如果权限已授权，不需要显示引导
    if (status.isGranted) {
      if (kDebugMode) {
        print('Debug: 权限已授权，不需要显示引导');
      }
      return false;
    }

    // 如果权限被永久拒绝，需要显示引导
    if (status.isPermanentlyDenied) {
      if (kDebugMode) {
        print('Debug: 权限被永久拒绝，需要显示引导');
      }
      return true;
    }

    // 检查是否已经处理过首次启动的权限请求
    final hasHandledFirstLaunch = await hasHandledFirstLaunchPermission();

    if (kDebugMode) {
      print('Debug: 首次启动处理状态: $hasHandledFirstLaunch');
    }

    // 对于首次启动的情况，系统会自动弹出权限弹窗，我们不需要重复显示
    if (!hasHandledFirstLaunch) {
      if (kDebugMode) {
        print('Debug: 首次启动，系统会自动弹出权限弹窗，跳过应用内引导');
      }
      // 标记已处理首次启动权限
      await markFirstLaunchPermissionHandled();
      return false;
    }

    // 非首次启动时，如果权限被拒绝，显示引导
    if (status.isDenied) {
      if (kDebugMode) {
        print('Debug: 非首次启动且权限被拒绝，需要显示引导');
      }
      return true;
    }

    // 其他情况不显示引导
    if (kDebugMode) {
      print('Debug: 其他情况，不显示引导');
    }
    return false;
  }

  /// 检查是否需要显示后台限制引导
  Future<bool> shouldShowBackgroundRestrictionGuide() async {
    final isDomestic = await isDomesticROM();
    final permissionStatus = await getNotificationPermissionStatus();

    // 国产ROM且权限被拒绝时，可能需要后台限制引导
    return isDomestic &&
        (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied);
  }

  /// 获取权限引导消息
  Future<String> getPermissionGuideMessage(dynamic l10n) async {
    final isDomestic = await isDomesticROM();
    final status = await getNotificationPermissionStatus();

    if (isDomestic) {
      return l10n.domesticPhoneCalendarPermissionGuide;
    } else {
      if (status.isPermanentlyDenied) {
        return l10n.notificationPermissionPermanentlyDenied;
      } else {
        return l10n.notificationPermissionRequest;
      }
    }
  }

  /// 获取调试信息
  Future<Map<String, dynamic>> getDebugInfo() async {
    final isDomestic = await isDomesticROM();
    final permissionStatus = await getNotificationPermissionStatus();
    final shouldShowGuide = await shouldShowPermissionGuide();
    final shouldShowBackgroundGuide =
        await shouldShowBackgroundRestrictionGuide();

    return {
      'isDomesticROM': isDomestic,
      'permissionStatus': permissionStatus.name,
      'shouldShowPermissionGuide': shouldShowGuide,
      'shouldShowBackgroundRestrictionGuide': shouldShowBackgroundGuide,
      'platform': Platform.operatingSystem,
    };
  }

  /// 获取日历权限状态
  Future<PermissionStatus> getCalendarPermissionStatus() async {
    if (_calendarPermissionStatus != null) {
      return _calendarPermissionStatus!;
    }
    try {
      _calendarPermissionStatus = await Permission.calendarWriteOnly.status;
      // 在release包中也保留调试日志
      print('Debug: 获取日历权限状态: ${_calendarPermissionStatus!.name}');
    } catch (e) {
      // 在release包中也保留调试日志
      print('Debug: 获取日历权限状态失败: $e');
      return PermissionStatus.denied;
    }
    return _calendarPermissionStatus!;
  }

  /// 请求日历权限
  Future<PermissionStatus> requestCalendarPermission() async {
    try {
      final currentStatus = await getCalendarPermissionStatus();

      // 如果已经授权，直接返回
      if (currentStatus.isGranted) {
        // 在release包中也保留调试日志
        print('Debug: 日历权限已授权，无需重复请求');
        return currentStatus;
      }

      // 如果被永久拒绝，直接返回状态
      if (currentStatus.isPermanentlyDenied) {
        // 在release包中也保留调试日志
        print('Debug: 日历权限被永久拒绝');
        return currentStatus;
      }

      // 请求权限
      // 在release包中也保留调试日志
      print('Debug: 开始请求日历权限');

      _calendarPermissionStatus = await Permission.calendarWriteOnly.request();

      // 在release包中也保留调试日志
      print('Debug: 日历权限请求结果: ${_calendarPermissionStatus!.name}');

      return _calendarPermissionStatus!;
    } catch (e) {
      // 在release包中也保留调试日志
      print('Debug: 请求日历权限失败: $e');
      return PermissionStatus.denied;
    }
  }

  /// 检查是否已经处理过首次启动的日历权限请求
  Future<bool> hasHandledFirstLaunchCalendarPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_firstLaunchCalendarPermissionKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Debug: 检查首次启动日历权限处理状态失败: $e');
      }
      return false;
    }
  }

  /// 标记首次启动日历权限已处理
  Future<void> markFirstLaunchCalendarPermissionHandled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_firstLaunchCalendarPermissionKey, true);
      if (kDebugMode) {
        print('Debug: 已标记首次启动日历权限处理完成');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Debug: 标记首次启动日历权限处理失败: $e');
      }
    }
  }

  /// 检查是否应该自动请求日历权限（无Google服务的Android设备）
  Future<bool> shouldAutoRequestCalendarPermission() async {
    try {
      if (kDebugMode) {
        print('Debug: 开始检查是否应该自动请求日历权限');
      }

      // 只对Android设备检查
      if (!Platform.isAndroid) {
        if (kDebugMode) {
          print('Debug: 非Android设备，不请求日历权限');
        }
        return false;
      }

      // 检查是否为国产ROM（通常无Google服务）
      final isDomestic = await isDomesticROM();
      if (kDebugMode) {
        print('Debug: 国产ROM检测结果: $isDomestic');
      }
      if (!isDomestic) {
        if (kDebugMode) {
          print('Debug: 非国产ROM，不请求日历权限');
        }
        return false;
      }

      // 检查是否已经处理过首次启动的日历权限请求
      final hasHandledFirstLaunch =
          await hasHandledFirstLaunchCalendarPermission();
      if (kDebugMode) {
        print('Debug: 首次启动日历权限处理状态: $hasHandledFirstLaunch');
      }
      if (hasHandledFirstLaunch) {
        if (kDebugMode) {
          print('Debug: 已处理过首次启动日历权限，不重复请求');
        }
        return false;
      }

      // 检查当前权限状态
      final currentStatus = await getCalendarPermissionStatus();
      if (kDebugMode) {
        print('Debug: 当前日历权限状态: ${currentStatus.name}');
      }
      if (currentStatus.isGranted) {
        if (kDebugMode) {
          print('Debug: 日历权限已授权，无需请求');
        }
        return false;
      }

      // 在release包中也保留调试日志
      print('Debug: 满足所有条件，应该自动请求日历权限');
      return true;
    } catch (e) {
      // 在release包中也保留调试日志
      print('Debug: 检查是否应该自动请求日历权限失败: $e');
      return false;
    }
  }

  /// 自动请求日历权限（如果适用）
  Future<void> autoRequestCalendarPermissionIfNeeded() async {
    try {
      final shouldRequest = await shouldAutoRequestCalendarPermission();
      if (!shouldRequest) {
        return;
      }

      // 在release包中也保留调试日志
      print('Debug: 自动请求日历权限（无Google服务的Android设备）');

      // 请求日历权限
      final status = await requestCalendarPermission();

      // 标记已处理首次启动日历权限
      await markFirstLaunchCalendarPermissionHandled();

      // 在release包中也保留调试日志
      print('Debug: 自动请求日历权限完成，状态: ${status.name}');
    } catch (e) {
      // 在release包中也保留调试日志
      print('Debug: 自动请求日历权限失败: $e');
    }
  }

  /// 重置缓存状态（用于重新检测）
  void resetCache() {
    _isDomesticROM = null;
    _notificationPermissionStatus = null;
    _calendarPermissionStatus = null;
  }
}
