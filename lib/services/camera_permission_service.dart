import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// 相机权限管理服务
class CameraPermissionService {
  CameraPermissionService._();
  static final CameraPermissionService instance = CameraPermissionService._();

  /// 检查相机权限状态
  Future<PermissionStatus> getCameraPermissionStatus() async {
    try {
      final status = await Permission.camera.status;
      if (kDebugMode) {
        print('Debug: 相机权限状态: ${status.name}');
      }
      return status;
    } catch (e) {
      if (kDebugMode) {
        print('Debug: 获取相机权限状态失败: $e');
      }
      return PermissionStatus.denied;
    }
  }

  /// 请求相机权限
  Future<PermissionStatus> requestCameraPermission() async {
    try {
      final currentStatus = await getCameraPermissionStatus();

      // 如果已经授权，直接返回
      if (currentStatus.isGranted) {
        if (kDebugMode) {
          print('Debug: 相机权限已授权，无需重复请求');
        }
        return currentStatus;
      }

      // 如果被永久拒绝，直接返回状态
      if (currentStatus.isPermanentlyDenied) {
        if (kDebugMode) {
          print('Debug: 相机权限被永久拒绝');
        }
        return currentStatus;
      }

      // 请求权限
      if (kDebugMode) {
        print('Debug: 开始请求相机权限');
      }

      final newStatus = await Permission.camera.request();

      if (kDebugMode) {
        print('Debug: 相机权限请求结果: ${newStatus.name}');
      }

      return newStatus;
    } catch (e) {
      if (kDebugMode) {
        print('Debug: 请求相机权限失败: $e');
      }
      return PermissionStatus.denied;
    }
  }

  /// 检查是否有相机权限
  Future<bool> hasCameraPermission() async {
    final status = await getCameraPermissionStatus();
    return status.isGranted;
  }

  /// 检查权限是否被永久拒绝
  Future<bool> isPermissionPermanentlyDenied() async {
    final status = await getCameraPermissionStatus();
    return status.isPermanentlyDenied;
  }
}
