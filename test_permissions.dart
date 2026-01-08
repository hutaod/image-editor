import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

void main() async {
  print('🔍 测试权限和设备检测');
  print('==================');

  // 测试设备信息
  if (Platform.isAndroid) {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    print('📱 设备信息:');
    print('  品牌: ${androidInfo.brand}');
    print('  制造商: ${androidInfo.manufacturer}');
    print('  型号: ${androidInfo.model}');
    print('  系统特性: ${androidInfo.systemFeatures}');
  }

  // 测试权限状态
  print('\n🔐 权限状态:');
  final notificationStatus = await Permission.notification.status;
  final calendarStatus = await Permission.calendarWriteOnly.status;

  print('  通知权限: ${notificationStatus.name}');
  print('  日历权限: ${calendarStatus.name}');

  // 测试权限请求
  print('\n🔑 测试权限请求:');
  print('  请求通知权限...');
  final notificationResult = await Permission.notification.request();
  print('  通知权限结果: ${notificationResult.name}');

  print('  请求日历权限...');
  final calendarResult = await Permission.calendarWriteOnly.request();
  print('  日历权限结果: ${calendarResult.name}');
}
