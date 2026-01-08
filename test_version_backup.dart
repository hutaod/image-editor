import 'package:flutter/foundation.dart';
import 'lib/services/auto_backup_service.dart';

void main() async {
  print('=== 版本备份功能测试 ===');

  try {
    // 1. 获取当前版本信息
    print('\n1. 获取当前版本信息:');
    final currentVersion = await AutoBackupService.getCurrentVersionInfo();
    print('当前版本: ${currentVersion['version']}');
    print('构建号: ${currentVersion['buildNumber']}');
    print('包名: ${currentVersion['packageName']}');

    // 2. 获取上次记录的版本信息
    print('\n2. 获取上次记录的版本信息:');
    final lastVersion = await AutoBackupService.getLastVersionInfo();
    print('上次版本: ${lastVersion['version']}');
    print('上次构建号: ${lastVersion['buildNumber']}');

    // 3. 检查备份状态
    print('\n3. 检查备份状态:');
    final lastBackup = await AutoBackupService.getLastBackupTime();
    final nextBackup = await AutoBackupService.getNextBackupTime();
    print('上次备份时间: ${lastBackup?.toString() ?? '无'}');
    print('下次备份时间: ${nextBackup?.toString() ?? '无'}');

    // 4. 执行备份检查
    print('\n4. 执行备份检查:');
    final backupResult = await AutoBackupService.checkAndBackup();
    print('备份结果: ${backupResult ? '已创建备份' : '无需备份'}');

    // 5. 测试强制版本更新（模拟版本变化）
    print('\n5. 测试强制版本更新:');
    await AutoBackupService.forceVersionUpdate();
    print('已清除版本信息');

    // 6. 再次执行备份检查（应该触发更新前备份）
    print('\n6. 再次执行备份检查（模拟版本更新）:');
    final updateBackupResult = await AutoBackupService.checkAndBackup();
    print('更新备份结果: ${updateBackupResult ? '已创建更新前备份' : '未创建备份'}');

    print('\n=== 测试完成 ===');
  } catch (e) {
    print('测试失败: $e');
  }
}
