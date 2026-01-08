import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'data_export_import_service.dart';

/// 自动备份服务
class AutoBackupService {
  static const String LAST_AUTO_BACKUP_KEY = 'last_auto_backup_time';
  static const String AUTO_BACKUP_ENABLED_KEY = 'auto_backup_enabled';
  static const int AUTO_BACKUP_INTERVAL_DAYS = 30; // 每30天自动备份一次
  static const int BACKUP_RETENTION_DAYS = 90; // 备份文件保留90天

  /// 检查并执行自动备份
  static Future<bool> checkAndBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 检查是否启用自动备份（默认启用）
      final isEnabled = prefs.getBool(AUTO_BACKUP_ENABLED_KEY) ?? true;
      if (!isEnabled) {
        if (kDebugMode) {
          print('自动备份已禁用');
        }
        return false;
      }

      final lastBackupStr = prefs.getString(LAST_AUTO_BACKUP_KEY);

      // 判断是否需要备份
      bool needsBackup = false;
      if (lastBackupStr == null) {
        // 首次启动时不自动备份，等待用户手动备份或下次定期检查
        needsBackup = false;
        if (kDebugMode) {
          print('首次启动，跳过自动备份（等待用户手动备份或下次定期检查）');
        }
      } else {
        final lastBackup = DateTime.parse(lastBackupStr);
        final daysSinceLastBackup = DateTime.now()
            .difference(lastBackup)
            .inDays;
        needsBackup = daysSinceLastBackup >= AUTO_BACKUP_INTERVAL_DAYS;
        if (kDebugMode) {
          print('距离上次自动备份: $daysSinceLastBackup 天');
        }
      }

      if (needsBackup) {
        if (kDebugMode) {
          print('开始执行自动备份...');
        }

        final backupService = DataExportImportService();
        final timestamp = DateTime.now().toIso8601String().split('T')[0];
        final fileName = 'auto_backup_$timestamp.zip';

        await backupService.exportToZipFile(fileName: fileName);

        // 更新最后备份时间
        await prefs.setString(
          LAST_AUTO_BACKUP_KEY,
          DateTime.now().toIso8601String(),
        );

        // 清理过期的备份文件
        await _cleanupOldBackups();

        if (kDebugMode) {
          print('自动备份完成: $fileName');
        }

        return true;
      } else {
        if (kDebugMode) {
          print('无需自动备份');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('自动备份失败: $e');
      }
      return false;
    }
  }

  /// 启用或禁用自动备份
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AUTO_BACKUP_ENABLED_KEY, enabled);
    if (kDebugMode) {
      print('自动备份已${enabled ? "启用" : "禁用"}');
    }
  }

  /// 获取自动备份状态
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AUTO_BACKUP_ENABLED_KEY) ?? true;
  }

  /// 获取最后备份时间
  static Future<DateTime?> getLastBackupTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBackupStr = prefs.getString(LAST_AUTO_BACKUP_KEY);
      if (lastBackupStr != null) {
        return DateTime.parse(lastBackupStr);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('获取最后备份时间失败: $e');
      }
      return null;
    }
  }

  /// 获取下次备份时间
  static Future<DateTime?> getNextBackupTime() async {
    final lastBackup = await getLastBackupTime();
    if (lastBackup != null) {
      return lastBackup.add(const Duration(days: AUTO_BACKUP_INTERVAL_DAYS));
    }
    return null;
  }

  /// 手动触发立即备份
  static Future<bool> backupNow() async {
    try {
      if (kDebugMode) {
        print('手动触发自动备份...');
      }

      final backupService = DataExportImportService();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'manual_backup_$timestamp.zip';

      await backupService.exportToZipFile(fileName: fileName);

      // 更新最后备份时间
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        LAST_AUTO_BACKUP_KEY,
        DateTime.now().toIso8601String(),
      );

      if (kDebugMode) {
        print('手动备份完成: $fileName');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('手动备份失败: $e');
      }
      return false;
    }
  }

  /// 清理过期的备份文件
  static Future<void> _cleanupOldBackups() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir
          .listSync()
          .where(
            (file) =>
                file is File &&
                (file.path.endsWith('.zip') ||
                    file.path.endsWith('.drmbak') ||
                    file.path.endsWith('.json')),
          )
          .cast<File>()
          .toList();

      final cutoffDate = DateTime.now().subtract(
        const Duration(days: BACKUP_RETENTION_DAYS),
      );

      int deletedCount = 0;
      for (final file in files) {
        try {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
            deletedCount++;
            if (kDebugMode) {
              print('删除过期备份文件: ${file.path.split('/').last}');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('删除备份文件失败: ${file.path}, 错误: $e');
          }
        }
      }

      if (kDebugMode && deletedCount > 0) {
        print('清理完成，删除了 $deletedCount 个过期备份文件');
      }
    } catch (e) {
      if (kDebugMode) {
        print('清理备份文件失败: $e');
      }
    }
  }

  /// 手动清理过期备份文件
  static Future<int> cleanupOldBackups() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir
          .listSync()
          .where(
            (file) =>
                file is File &&
                (file.path.endsWith('.zip') ||
                    file.path.endsWith('.drmbak') ||
                    file.path.endsWith('.json')),
          )
          .cast<File>()
          .toList();

      final cutoffDate = DateTime.now().subtract(
        const Duration(days: BACKUP_RETENTION_DAYS),
      );

      int deletedCount = 0;
      for (final file in files) {
        try {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
            deletedCount++;
            if (kDebugMode) {
              print('删除过期备份文件: ${file.path.split('/').last}');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('删除备份文件失败: ${file.path}, 错误: $e');
          }
        }
      }

      if (kDebugMode) {
        print('手动清理完成，删除了 $deletedCount 个过期备份文件');
      }
      return deletedCount;
    } catch (e) {
      if (kDebugMode) {
        print('手动清理备份文件失败: $e');
      }
      return 0;
    }
  }
}
