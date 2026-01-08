import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/event_record.dart';

/// 事件记录Provider
final eventRecordsProvider =
    StateNotifierProvider<EventRecordsNotifier, List<EventRecord>>((ref) {
      return EventRecordsNotifier();
    });

/// 特定事件的记录Provider
final eventRecordsByEventIdProvider =
    Provider.family<List<EventRecord>, String>((ref, eventId) {
      final allRecords = ref.watch(eventRecordsProvider);
      return allRecords.where((record) => record.eventId == eventId).toList();
    });

/// 事件记录数量Provider
final eventRecordCountProvider = Provider.family<int, String>((ref, eventId) {
  final records = ref.watch(eventRecordsByEventIdProvider(eventId));
  return records.length;
});

class EventRecordsNotifier extends StateNotifier<List<EventRecord>> {
  EventRecordsNotifier() : super([]) {
    _loadRecords();
  }

  static const String _boxName = 'event_records';

  /// 加载所有记录
  Future<void> _loadRecords() async {
    try {
      final box = await Hive.openBox<EventRecord>(_boxName);
      state = box.values.toList();
    } catch (e) {
      print('Error loading event records: $e');
      state = [];
    }
  }

  /// 添加记录
  Future<void> addRecord(EventRecord record) async {
    try {
      final box = await Hive.openBox<EventRecord>(_boxName);
      await box.put(record.id, record);
      await box.flush();
      state = [...state, record];
    } catch (e) {
      print('Error adding event record: $e');
    }
  }

  /// 更新记录
  Future<void> updateRecord(EventRecord record) async {
    try {
      final box = await Hive.openBox<EventRecord>(_boxName);
      await box.put(record.id, record);
      await box.flush();
      state = [
        for (final r in state)
          if (r.id == record.id) record else r,
      ];
    } catch (e) {
      print('Error updating event record: $e');
    }
  }

  /// 删除记录
  Future<void> deleteRecord(String recordId) async {
    try {
      final box = await Hive.openBox<EventRecord>(_boxName);
      await box.delete(recordId);
      await box.flush();
      state = state.where((record) => record.id != recordId).toList();
    } catch (e) {
      print('Error deleting event record: $e');
    }
  }

  /// 删除事件的所有记录
  Future<void> deleteRecordsByEventId(String eventId) async {
    try {
      final box = await Hive.openBox<EventRecord>(_boxName);
      final recordsToDelete = state
          .where((record) => record.eventId == eventId)
          .toList();

      for (final record in recordsToDelete) {
        await box.delete(record.id);
      }
      await box.flush();

      state = state.where((record) => record.eventId != eventId).toList();
    } catch (e) {
      print('Error deleting event records: $e');
    }
  }

  /// 获取特定事件的记录
  List<EventRecord> getRecordsByEventId(String eventId) {
    return state.where((record) => record.eventId == eventId).toList();
  }

  /// 获取记录数量
  int getRecordCount(String eventId) {
    return state.where((record) => record.eventId == eventId).length;
  }

  /// 清空所有记录
  Future<void> clearAllRecords() async {
    try {
      final box = await Hive.openBox<EventRecord>(_boxName);
      await box.clear();
      await box.flush();
      state = [];
    } catch (e) {
      print('Error clearing all records: $e');
    }
  }

  /// 刷新记录列表（从数据库重新加载）
  void refresh() {
    _loadRecords();
  }
}
