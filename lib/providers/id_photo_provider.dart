import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/id_photo_record.dart';
import '../models/id_photo_template.dart';
import '../services/database_service.dart';
import '../services/template_service.dart';

/// 证件照记录 Provider
final idPhotoRecordsProvider = StateNotifierProvider<IdPhotoRecordsNotifier, List<IdPhotoRecord>>((ref) {
  return IdPhotoRecordsNotifier();
});

class IdPhotoRecordsNotifier extends StateNotifier<List<IdPhotoRecord>> {
  IdPhotoRecordsNotifier() : super([]) {
    loadRecords();
  }

  Future<void> loadRecords() async {
    state = DatabaseService.getAllRecords();
  }

  Future<void> addRecord(IdPhotoRecord record) async {
    await DatabaseService.saveRecord(record);
    await loadRecords();
  }

  Future<void> updateRecord(IdPhotoRecord record) async {
    await DatabaseService.saveRecord(record);
    await loadRecords();
  }

  Future<void> deleteRecord(String id) async {
    await DatabaseService.deleteRecord(id);
    await loadRecords();
  }
}

/// 模板列表 Provider
final templatesProvider = Provider<List<IdPhotoTemplate>>((ref) {
  return TemplateService.getAllTemplates();
});

/// 当前选中的模板 Provider
final selectedTemplateProvider = StateProvider<IdPhotoTemplate?>((ref) => null);

/// 当前编辑的记录 Provider
final currentEditRecordProvider = StateProvider<IdPhotoRecord?>((ref) => null);
