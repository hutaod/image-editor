import 'package:hive_flutter/hive_flutter.dart';
import '../models/id_photo_record.dart';

/// 数据库服务
class DatabaseService {
  static const String _boxName = 'id_photo_records';
  static Box<IdPhotoRecord>? _box;

  /// 初始化数据库
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // 注册适配器
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(IdPhotoRecordAdapter());
    }

    // 打开 Box
    _box = await Hive.openBox<IdPhotoRecord>(_boxName);
  }

  /// 获取所有记录
  static List<IdPhotoRecord> getAllRecords() {
    if (_box == null) return [];
    return _box!.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// 根据 ID 获取记录
  static IdPhotoRecord? getRecord(String id) {
    if (_box == null) return null;
    return _box!.get(id);
  }

  /// 保存记录
  static Future<void> saveRecord(IdPhotoRecord record) async {
    if (_box == null) return;
    await _box!.put(record.id, record);
  }

  /// 删除记录
  static Future<void> deleteRecord(String id) async {
    if (_box == null) return;
    await _box!.delete(id);
  }

  /// 清空所有记录
  static Future<void> clearAll() async {
    if (_box == null) return;
    await _box!.clear();
  }

  /// 获取记录数量
  static int getRecordCount() {
    if (_box == null) return 0;
    return _box!.length;
  }
}
