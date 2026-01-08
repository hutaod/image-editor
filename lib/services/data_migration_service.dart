import 'dart:io';
import '../models/event_record.dart';
import 'image_storage_service.dart';

/// 数据迁移服务
class DataMigrationService {
  static final DataMigrationService _instance =
      DataMigrationService._internal();
  factory DataMigrationService() => _instance;
  DataMigrationService._internal();

  /// 迁移所有记录的图片到永久存储
  Future<void> migrateImagesToPermanentStorage(
    List<EventRecord> records,
    Function(EventRecord) updateRecord,
  ) async {
    final imageStorageService = ImageStorageService();

    for (final record in records) {
      if (record.imagePaths.isNotEmpty) {
        try {
          print('检查记录 ${record.id} 的图片路径: ${record.imagePaths}');

          // 强制重新迁移所有图片，不检查路径格式
          print('记录 ${record.id} 开始强制重新迁移所有图片...');

          // 先清理无效的图片引用
          final validPaths = await imageStorageService.cleanupInvalidImages(
            record.imagePaths,
          );
          print('清理后的有效路径: $validPaths');

          if (validPaths.isNotEmpty) {
            // 迁移图片到永久存储
            final permanentPaths = await imageStorageService
                .copyImagesToPermanentStorage(validPaths);

            print('迁移后的永久路径: $permanentPaths');

            if (permanentPaths.isNotEmpty) {
              // 更新记录
              final updatedRecord = EventRecord(
                id: record.id,
                eventId: record.eventId,
                type: record.type,
                textContent: record.textContent,
                imagePaths: permanentPaths,
                createdAt: record.createdAt,
                updatedAt: DateTime.now(),
                location: record.location,
              );

              updateRecord(updatedRecord);
              print('记录 ${record.id} 迁移完成，更新了 ${permanentPaths.length} 张图片');
            } else {
              print('记录 ${record.id} 迁移失败：没有成功复制任何图片');
              // 即使迁移失败，也要更新记录，清空无效的图片路径
              final updatedRecord = EventRecord(
                id: record.id,
                eventId: record.eventId,
                type: record.type,
                textContent: record.textContent,
                imagePaths: [], // 清空无效路径
                createdAt: record.createdAt,
                updatedAt: DateTime.now(),
                location: record.location,
              );
              updateRecord(updatedRecord);
              print('记录 ${record.id} 已清空无效的图片路径');
            }
          } else {
            print('记录 ${record.id} 没有有效的图片路径，清空图片引用');
            // 清空无效的图片路径
            final updatedRecord = EventRecord(
              id: record.id,
              eventId: record.eventId,
              type: record.type,
              textContent: record.textContent,
              imagePaths: [], // 清空无效路径
              createdAt: record.createdAt,
              updatedAt: DateTime.now(),
              location: record.location,
            );
            updateRecord(updatedRecord);
          }
        } catch (e) {
          print('迁移记录图片失败: ${record.id}, 错误: $e');
        }
      }
    }
  }

  /// 清理无效的图片引用
  Future<void> cleanupInvalidImageReferences(
    List<EventRecord> records,
    Function(EventRecord) updateRecord,
  ) async {
    final imageStorageService = ImageStorageService();

    for (final record in records) {
      if (record.imagePaths.isNotEmpty) {
        try {
          // 清理无效的图片引用
          final validPaths = await imageStorageService.cleanupInvalidImages(
            record.imagePaths,
          );

          if (validPaths.length != record.imagePaths.length) {
            // 更新记录
            final updatedRecord = EventRecord(
              id: record.id,
              eventId: record.eventId,
              type: record.type,
              textContent: record.textContent,
              imagePaths: validPaths,
              createdAt: record.createdAt,
              updatedAt: DateTime.now(),
              location: record.location,
            );

            updateRecord(updatedRecord);
          }
        } catch (e) {
          print('清理记录图片引用失败: ${record.id}, 错误: $e');
        }
      }
    }
  }

  /// 检查是否需要迁移 - 现在总是返回true，强制重新迁移所有图片
  bool needsMigration(List<EventRecord> records) {
    // 强制重新迁移所有图片，确保路径正确
    return records.any((record) => record.imagePaths.isNotEmpty);
  }

  /// 获取存储统计信息
  Future<Map<String, dynamic>> getStorageStats() async {
    final imageStorageService = ImageStorageService();

    final imageCount = await imageStorageService.getImageCount();
    final storageSize = await imageStorageService.getStorageSize();

    return {
      'imageCount': imageCount,
      'storageSize': storageSize,
      'storageSizeMB': (storageSize / (1024 * 1024)).toStringAsFixed(2),
    };
  }

  /// 更新图片路径到当前沙盒位置
  Future<void> updateImagePathsToCurrentSandbox(
    List<EventRecord> records,
    Function(EventRecord) updateRecord,
  ) async {
    print('开始更新图片路径到当前沙盒位置...');

    final imageStorageService = ImageStorageService();
    final currentImagesDir = await imageStorageService.getImagesDirectory();

    for (final record in records) {
      if (record.imagePaths.isNotEmpty) {
        try {
          print('检查记录 ${record.id} 的图片路径: ${record.imagePaths}');

          List<String> updatedPaths = [];
          bool needsUpdate = false;

          for (final oldPath in record.imagePaths) {
            // 检查是否是旧沙盒路径
            if (oldPath.contains('Documents/images/') &&
                !oldPath.contains(currentImagesDir.path)) {
              // 提取文件名
              final fileName = oldPath.split('/').last;
              final newPath = '${currentImagesDir.path}/$fileName';

              // 检查新路径文件是否存在
              final newFile = File(newPath);
              if (await newFile.exists()) {
                updatedPaths.add(newPath);
                print('找到文件在新位置: $newPath');
              } else {
                print('文件在新位置不存在: $newPath');
                // 尝试在旧位置查找并复制
                final oldFile = File(oldPath);
                if (await oldFile.exists()) {
                  print('文件在旧位置存在，开始复制: $oldPath -> $newPath');
                  try {
                    await oldFile.copy(newPath);
                    updatedPaths.add(newPath);
                    print('文件复制成功: $newPath');
                  } catch (e) {
                    print('文件复制失败: $e');
                  }
                } else {
                  print('文件在旧位置也不存在: $oldPath');
                }
              }
              needsUpdate = true;
            } else {
              // 路径已经是当前沙盒或格式不正确，保持不变
              updatedPaths.add(oldPath);
            }
          }

          if (needsUpdate) {
            final updatedRecord = EventRecord(
              id: record.id,
              eventId: record.eventId,
              type: record.type,
              textContent: record.textContent,
              imagePaths: updatedPaths,
              createdAt: record.createdAt,
              updatedAt: DateTime.now(),
              location: record.location,
            );

            updateRecord(updatedRecord);
            print('记录 ${record.id} 已更新图片路径: $updatedPaths');
          } else {
            print('记录 ${record.id} 图片路径无需更新');
          }
        } catch (e) {
          print('更新记录 ${record.id} 时出错: $e');
        }
      }
    }

    print('图片路径更新完成');
  }
}
