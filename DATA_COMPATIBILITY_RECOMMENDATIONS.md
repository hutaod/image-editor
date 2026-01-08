# 数据兼容性改进建议

## 当前状态
应用已实现基本的数据兼容性机制，包括：
- ✅ Legacy Adapter 支持旧数据格式
- ✅ 新增字段有默认值
- ✅ 导入导出版本管理（1.x系列）
- ✅ 图片路径自动迁移
- ⚠️ 数据库打开失败会清空数据（有风险）

## 建议改进项

### 1. 添加数据库版本管理（高优先级）

在 `lib/services/database_migration_service.dart` 中添加：

```dart
class DatabaseMigrationService {
  static const String DB_VERSION_KEY = 'database_version';
  static const int CURRENT_VERSION = 1;

  static Future<void> migrate() async {
    final prefs = await SharedPreferences.getInstance();
    final currentVersion = prefs.getInt(DB_VERSION_KEY) ?? 0;

    if (currentVersion < CURRENT_VERSION) {
      print('开始数据库迁移: v$currentVersion -> v$CURRENT_VERSION');
      
      // 执行逐步迁移
      for (int v = currentVersion + 1; v <= CURRENT_VERSION; v++) {
        await _migrateToVersion(v);
        await prefs.setInt(DB_VERSION_KEY, v);
      }
      
      print('数据库迁移完成');
    }
  }

  static Future<void> _migrateToVersion(int version) async {
    switch (version) {
      case 1:
        // 首次安装，无需迁移
        break;
      // 未来版本的迁移逻辑
      case 2:
        // await _migrateV1ToV2();
        break;
    }
  }
}
```

在 `main.dart` 中调用：
```dart
await Hive.initFlutter();
// 注册适配器...

// 执行数据库迁移
await DatabaseMigrationService.migrate();

// 打开数据库
Box<Event> box = await Hive.openBox<Event>(eventsBoxName);
```

### 2. 数据库打开失败时先备份（高优先级）

修改 `main.dart` 第54-74行：

```dart
Box<Event> box;
try {
  box = await Hive.openBox<Event>(eventsBoxName);
  await box.flush();
} catch (e) {
  print('Debug: 数据库打开失败，可能是数据结构不兼容: $e');
  
  // 1. 先尝试备份旧数据
  bool backupSuccess = false;
  try {
    final backupService = DataExportImportService();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final backupPath = await backupService.exportToFile(
      fileName: 'auto_backup_before_migration_$timestamp.json',
    );
    print('Debug: 旧数据已备份到: $backupPath');
    backupSuccess = true;
  } catch (backupError) {
    print('Debug: 备份旧数据失败: $backupError');
  }
  
  // 2. 删除旧数据库
  await Hive.deleteBoxFromDisk(eventsBoxName);
  
  // 3. 重新创建数据库
  box = await Hive.openBox<Event>(eventsBoxName);
  await box.flush();
  print('Debug: 数据库已重新创建');
  
  // 4. 标记数据库已重建
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('_database_rebuilt', true);
  
  // 5. 如果备份成功，提示用户可以恢复
  if (backupSuccess) {
    await prefs.setBool('_has_auto_backup', true);
    await prefs.setString('_auto_backup_time', DateTime.now().toIso8601String());
  }
}
```

### 3. 添加数据完整性检查（中优先级）

在应用启动时检查数据完整性：

```dart
class DataIntegrityService {
  static Future<bool> checkIntegrity() async {
    try {
      final eventsBox = await Hive.openBox<Event>('eventsBox');
      final recordsBox = await Hive.openBox<EventRecord>('event_records');
      
      // 检查事件数据
      for (final event in eventsBox.values) {
        if (event.id.isEmpty || event.title.isEmpty) {
          print('发现无效事件: ${event.id}');
          return false;
        }
      }
      
      // 检查记录数据
      for (final record in recordsBox.values) {
        if (record.id.isEmpty || record.eventId.isEmpty) {
          print('发现无效记录: ${record.id}');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      print('数据完整性检查失败: $e');
      return false;
    }
  }
  
  static Future<void> cleanupInvalidData() async {
    // 清理无效数据的逻辑
  }
}
```

### 4. 添加自动备份机制（中优先级）

定期自动备份用户数据：

```dart
class AutoBackupService {
  static Future<void> autoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackup = prefs.getString('last_auto_backup_time');
    
    // 每7天自动备份一次
    if (lastBackup == null || 
        DateTime.now().difference(DateTime.parse(lastBackup)).inDays >= 7) {
      
      try {
        final backupService = DataExportImportService();
        final timestamp = DateFormat('yyyyMMdd').format(DateTime.now());
        await backupService.exportToFile(
          fileName: 'auto_backup_$timestamp.json',
        );
        
        await prefs.setString('last_auto_backup_time', DateTime.now().toIso8601String());
        print('自动备份完成');
      } catch (e) {
        print('自动备份失败: $e');
      }
    }
  }
}
```

### 5. SharedPreferences 数据兼容（低优先级）

当前 SharedPreferences 数据会自动保留，但建议添加清理机制：

```dart
class PreferencesCleanupService {
  static Future<void> cleanup() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    // 移除废弃的键
    final deprecatedKeys = ['old_feature_flag', 'unused_setting'];
    for (final key in deprecatedKeys) {
      if (keys.contains(key)) {
        await prefs.remove(key);
      }
    }
  }
}
```

## 实施优先级

1. **立即实施**（防止数据丢失）：
   - 数据库打开失败时先备份

2. **下个版本**（长期维护）：
   - 添加数据库版本管理
   - 添加数据完整性检查

3. **后续优化**（用户体验）：
   - 自动备份机制
   - SharedPreferences 清理

## 总结

当前应用的数据兼容性机制**基本可用**，能够处理大部分场景。但建议添加：
1. 数据库打开失败时的备份机制（防止数据丢失）
2. 版本管理机制（便于未来迁移）
3. 定期自动备份（提高数据安全性）

这些改进将显著提高应用更新时的数据安全性和用户体验。

