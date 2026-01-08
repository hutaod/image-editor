import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/event.dart';
import '../models/event_record.dart';

/// 数据库版本管理和迁移服务
class DatabaseMigrationService {
  static const String DB_VERSION_KEY = 'database_version';
  static const int CURRENT_VERSION = 1;

  /// 执行数据库迁移
  static Future<void> migrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = prefs.getInt(DB_VERSION_KEY) ?? 0;

      if (currentVersion < CURRENT_VERSION) {
        if (kDebugMode) {
          print('开始数据库迁移: v$currentVersion -> v$CURRENT_VERSION');
        }

        // 执行逐步迁移
        for (int v = currentVersion + 1; v <= CURRENT_VERSION; v++) {
          await _migrateToVersion(v);
          await prefs.setInt(DB_VERSION_KEY, v);
          if (kDebugMode) {
            print('已迁移到版本: v$v');
          }
        }

        if (kDebugMode) {
          print('数据库迁移完成');
        }
      } else {
        if (kDebugMode) {
          print('数据库版本已是最新: v$currentVersion');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('数据库迁移失败: $e');
      }
      rethrow;
    }
  }

  /// 迁移到指定版本
  static Future<void> _migrateToVersion(int version) async {
    switch (version) {
      case 1:
        // 首次安装或从无版本号升级到v1，无需特殊迁移
        if (kDebugMode) {
          print('初始化数据库版本为 v1');
        }
        break;
      // 未来版本的迁移逻辑在这里添加
      // case 2:
      //   await _migrateV1ToV2();
      //   break;
      default:
        if (kDebugMode) {
          print('未知的迁移版本: v$version');
        }
    }
  }

  /// 检查数据完整性
  static Future<bool> checkIntegrity() async {
    try {
      if (kDebugMode) {
        print('开始数据完整性检查...');
      }

      final eventsBox = await Hive.openBox<Event>('eventsBox');
      final recordsBox = await Hive.openBox<EventRecord>('event_records');

      // 检查事件数据
      int invalidEvents = 0;
      for (final event in eventsBox.values) {
        if (event.id.isEmpty || event.title.isEmpty) {
          invalidEvents++;
          if (kDebugMode) {
            print('发现无效事件: id=${event.id}, title=${event.title}');
          }
        }
      }

      // 检查记录数据
      int invalidRecords = 0;
      for (final record in recordsBox.values) {
        if (record.id.isEmpty || record.eventId.isEmpty) {
          invalidRecords++;
          if (kDebugMode) {
            print('发现无效记录: id=${record.id}, eventId=${record.eventId}');
          }
        }
      }

      final isValid = invalidEvents == 0 && invalidRecords == 0;

      if (kDebugMode) {
        if (isValid) {
          print('数据完整性检查通过');
        } else {
          print('数据完整性检查失败: $invalidEvents个无效事件, $invalidRecords个无效记录');
        }
      }

      return isValid;
    } catch (e) {
      if (kDebugMode) {
        print('数据完整性检查异常: $e');
      }
      return false;
    }
  }

  /// 获取数据库统计信息
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final eventsBox = await Hive.openBox<Event>('eventsBox');
      final recordsBox = await Hive.openBox<EventRecord>('event_records');
      final prefs = await SharedPreferences.getInstance();

      return {
        'version': prefs.getInt(DB_VERSION_KEY) ?? 0,
        'eventsCount': eventsBox.length,
        'recordsCount': recordsBox.length,
        'lastBackupTime': prefs.getString('_auto_backup_time'),
        'hasAutoBackup': prefs.getBool('_has_auto_backup') ?? false,
      };
    } catch (e) {
      if (kDebugMode) {
        print('获取数据库统计信息失败: $e');
      }
      return {};
    }
  }
}
