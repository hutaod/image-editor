import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

/// 生物识别验证服务
class BiometricAuthService {
  static final BiometricAuthService _instance =
      BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// 检查设备是否支持生物识别
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// 检查是否有可用的生物识别方法
  Future<bool> hasAvailableBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// 获取可用的生物识别方法列表
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// 获取生物识别方法的友好名称
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return '指纹';
      case BiometricType.face:
        return '面容';
      case BiometricType.iris:
        return '虹膜';
      case BiometricType.strong:
        return '强生物识别';
      case BiometricType.weak:
        return '弱生物识别';
    }
  }

  /// 获取主要生物识别方法的友好名称
  Future<String> getPrimaryBiometricName() async {
    final available = await getAvailableBiometrics();
    if (available.isEmpty) return '生物识别';

    // 优先选择指纹或面容
    if (available.contains(BiometricType.fingerprint)) {
      return '指纹';
    } else if (available.contains(BiometricType.face)) {
      return '面容';
    } else if (available.contains(BiometricType.iris)) {
      return '虹膜';
    } else {
      return '生物识别';
    }
  }

  /// 执行生物识别验证
  Future<BiometricAuthResult> authenticate({
    String? reason,
    String? cancelButton,
    String? goToSettingsButton,
    String? goToSettingsDescription,
  }) async {
    try {
      print('Debug: 开始生物识别验证');

      // 检查设备支持
      final isSupported = await isDeviceSupported().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('Debug: 设备支持检查超时');
          return false;
        },
      );
      print('Debug: 设备支持生物识别: $isSupported');
      if (!isSupported) {
        return BiometricAuthResult(
          success: false,
          error: '设备不支持生物识别',
          errorCode: 'device_not_supported',
        );
      }

      // 检查是否有可用的生物识别方法
      final hasAvailable = await hasAvailableBiometrics().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('Debug: 生物识别方法检查超时');
          return false;
        },
      );
      print('Debug: 有可用的生物识别方法: $hasAvailable');
      if (!hasAvailable) {
        return BiometricAuthResult(
          success: false,
          error: '未设置生物识别',
          errorCode: 'no_biometrics_available',
        );
      }

      // 执行验证
      print('Debug: 开始执行生物识别验证');
      final bool didAuthenticate = await _localAuth
          .authenticate(
            localizedReason: reason ?? '请验证身份以查看隐藏事件',
            options: const AuthenticationOptions(
              biometricOnly: false, // 改为false，允许使用密码等备用方式
              stickyAuth: false, // 改为false，避免卡死
            ),
          )
          .timeout(
            const Duration(seconds: 30), // 添加30秒超时
            onTimeout: () {
              print('Debug: 生物识别验证超时');
              return false;
            },
          );

      print('Debug: 生物识别验证结果: $didAuthenticate');

      return BiometricAuthResult(
        success: didAuthenticate,
        error: didAuthenticate ? null : '验证失败',
        errorCode: didAuthenticate ? null : 'authentication_failed',
      );
    } on PlatformException catch (e) {
      String errorMessage = '验证失败';
      String errorCode = 'unknown_error';

      switch (e.code) {
        case auth_error.notAvailable:
          errorMessage = '生物识别不可用';
          errorCode = 'not_available';
          break;
        case auth_error.notEnrolled:
          errorMessage = '未设置生物识别';
          errorCode = 'not_enrolled';
          break;
        case auth_error.lockedOut:
          errorMessage = '生物识别被锁定，请稍后再试';
          errorCode = 'locked_out';
          break;
        case auth_error.permanentlyLockedOut:
          errorMessage = '生物识别被永久锁定，请使用其他方式解锁';
          errorCode = 'permanently_locked_out';
          break;
        case auth_error.biometricOnlyNotSupported:
          errorMessage = '设备不支持生物识别';
          errorCode = 'biometric_only_not_supported';
          break;
        case 'UserCancel':
          errorMessage = '用户取消';
          errorCode = 'user_cancel';
          break;
        case 'SystemCancel':
          errorMessage = '系统取消';
          errorCode = 'system_cancel';
          break;
        case 'InvalidContext':
          errorMessage = '无效上下文';
          errorCode = 'invalid_context';
          break;
        case 'NotInteractive':
          errorMessage = '无法交互';
          errorCode = 'not_interactive';
          break;
        default:
          errorMessage = '验证失败: ${e.message}';
          errorCode = 'platform_exception';
      }

      return BiometricAuthResult(
        success: false,
        error: errorMessage,
        errorCode: errorCode,
      );
    } catch (e) {
      return BiometricAuthResult(
        success: false,
        error: '验证失败: $e',
        errorCode: 'unknown_error',
      );
    }
  }
}

/// 生物识别验证结果
class BiometricAuthResult {
  final bool success;
  final String? error;
  final String? errorCode;

  BiometricAuthResult({required this.success, this.error, this.errorCode});
}
