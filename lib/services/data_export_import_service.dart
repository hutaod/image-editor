import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/event.dart';
import '../models/event_record.dart';
import 'notification_service.dart';
import 'encryption_service.dart';
import 'image_storage_service.dart';
import '../providers/event_provider.dart';
import '../providers/event_record_provider.dart';

/// 备份文件信息
class BackupFile {
  final String path;
  final String name;
  final int size;
  final DateTime createdAt;

  BackupFile({
    required this.path,
    required this.name,
    required this.size,
    required this.createdAt,
  });

  String get formattedSize {
    if (size < 1024) {
      return '${size}B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  String get formattedDate {
    return DateFormat('yyyy-MM-dd HH:mm').format(createdAt);
  }
}

/// 数据导入导出服务
class DataExportImportService {
  static final DataExportImportService _instance =
      DataExportImportService._internal();
  factory DataExportImportService() => _instance;
  DataExportImportService._internal();

  /// 导出所有数据（事件 + 记录）
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      // 直接从Hive数据库获取事件数据
      final eventsBox = await Hive.openBox<Event>('eventsBox');
      final events = eventsBox.values.toList();
      print('导出调试: 从数据库获取到 ${events.length} 个事件');

      final eventsJson = events.map((e) => e.toJson()).toList();
      print('导出调试: 事件JSON数据长度: ${eventsJson.length}');

      // 直接从Hive数据库获取记录数据
      final recordsBox = await Hive.openBox<EventRecord>('event_records');
      final records = recordsBox.values.toList();
      print('导出调试: 从数据库获取到 ${records.length} 个记录');

      final recordsJson = records.map((r) => r.toJson()).toList();
      print('导出调试: 记录JSON数据长度: ${recordsJson.length}');

      // 创建完整的数据结构
      final exportData = {
        'version': '1.0',
        'exportTime': DateTime.now().toIso8601String(),
        'events': eventsJson,
        'records': recordsJson,
        'metadata': {
          'eventCount': events.length,
          'recordCount': records.length,
          'appName': 'Days Reminder',
        },
      };

      print(
        '导出调试: 最终导出数据结构 - 事件: ${(exportData['events'] as List).length}, 记录: ${(exportData['records'] as List).length}',
      );
      return exportData;
    } catch (e) {
      print('导出调试: 导出失败 - $e');
      throw Exception('导出数据失败: $e');
    }
  }

  /// 导出数据到文件（默认加密）
  Future<String> exportToFile({bool encrypt = true, String? fileName}) async {
    try {
      final data = await exportAllData();
      print('导出调试: 开始序列化数据，事件数量: ${(data['events'] as List).length}');

      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      print('导出调试: JSON字符串长度: ${jsonStr.length}');

      // 获取应用文档目录
      final dir = await getApplicationDocumentsDirectory();
      print('导出调试: 文档目录: ${dir.path}');

      // 获取当前时间（用于文件名和备份时间记录）
      final now = DateTime.now();

      // 生成或使用提供的文件名
      String finalFileName;
      if (fileName != null && fileName.isNotEmpty) {
        // 使用提供的文件名，确保有正确的扩展名
        final extension = encrypt ? 'drmbak' : 'json';
        if (!fileName.endsWith('.$extension')) {
          finalFileName =
              fileName.endsWith('.json') || fileName.endsWith('.drmbak')
              ? fileName.substring(0, fileName.lastIndexOf('.')) + '.$extension'
              : '$fileName.$extension';
        } else {
          finalFileName = fileName;
        }
      } else {
        // 自动生成文件名
        final packageInfo = await PackageInfo.fromPlatform();
        final packageName = packageInfo.packageName;
        final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
        final extension = encrypt ? 'drmbak' : 'json';
        finalFileName = '${packageName}_backup_$dateStr.$extension';
      }
      print('导出调试: 文件名: $finalFileName');

      final file = File('${dir.path}/$finalFileName');

      if (encrypt) {
        // 加密数据
        final encryptedData = EncryptionService.encryptBytes(
          Uint8List.fromList(utf8.encode(jsonStr)),
        );
        await file.writeAsBytes(encryptedData);
        print('导出调试: 加密文件写入完成，文件大小: ${await file.length()} bytes');
      } else {
        // 普通JSON文件
        await file.writeAsString(jsonStr);
        print('导出调试: 文件写入完成，文件大小: ${await file.length()} bytes');
      }

      // 更新最后备份时间
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_backup_time', now.toIso8601String());

      return file.path;
    } catch (e) {
      throw Exception('导出文件失败: $e');
    }
  }

  /// 导出数据到压缩包（包含加密的JSON数据和图片）
  Future<String> exportToZipFile({String? fileName}) async {
    try {
      final data = await exportAllData();
      print('压缩包导出调试: 开始序列化数据，事件数量: ${(data['events'] as List).length}');

      // 创建压缩包
      final archive = Archive();

      // 1. 加密JSON数据并添加到压缩包
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final encryptedJsonData = EncryptionService.encryptBytes(
        Uint8List.fromList(utf8.encode(jsonStr)),
      );
      archive.addFile(
        ArchiveFile(
          'data.encrypted',
          encryptedJsonData.length,
          encryptedJsonData,
        ),
      );
      print('压缩包导出调试: 加密JSON数据已添加，大小: ${encryptedJsonData.length} bytes');

      // 2. 收集所有图片路径并加密
      final List<String> allImagePaths = [];
      for (final record in data['records'] as List) {
        final imagePaths = List<String>.from(record['imagePaths'] ?? []);
        allImagePaths.addAll(imagePaths);
      }

      print('压缩包导出调试: 找到 ${allImagePaths.length} 张图片需要处理');

      // 3. 加密图片并添加到压缩包
      final Map<String, String> imagePathMapping = {}; // 原路径 -> 新相对路径
      for (int i = 0; i < allImagePaths.length; i++) {
        final originalPath = allImagePaths[i];
        final fileName = path.basename(originalPath);
        final relativePath = 'images/$fileName';

        try {
          // 检查图片文件是否存在
          final imageFile = File(originalPath);
          if (!await imageFile.exists()) {
            print('压缩包导出调试: 图片文件不存在，跳过: $originalPath');
            continue;
          }

          // 加密图片
          print('压缩包导出调试: 开始加密图片: $originalPath');
          final encryptedImageData = await EncryptionService.encryptImageFile(
            originalPath,
          );
          print('压缩包导出调试: 图片加密完成，大小: ${encryptedImageData.length} bytes');

          archive.addFile(
            ArchiveFile(
              relativePath,
              encryptedImageData.length,
              encryptedImageData,
            ),
          );

          // 记录路径映射
          imagePathMapping[originalPath] = relativePath;
          print('压缩包导出调试: 图片已加密并添加: $relativePath');
        } catch (e) {
          print('压缩包导出调试: 加密图片失败: $originalPath, 错误: $e');
          print('压缩包导出调试: 错误堆栈: ${e.toString()}');
          // 继续处理其他图片
        }
      }

      // 4. 更新JSON数据中的图片路径为相对路径
      final updatedData = Map<String, dynamic>.from(data);
      final updatedRecords = <Map<String, dynamic>>[];

      for (final record in data['records'] as List) {
        final updatedRecord = Map<String, dynamic>.from(record);
        final imagePaths = List<String>.from(record['imagePaths'] ?? []);
        final updatedImagePaths = <String>[];

        for (final imagePath in imagePaths) {
          if (imagePathMapping.containsKey(imagePath)) {
            updatedImagePaths.add(imagePathMapping[imagePath]!);
          } else {
            // 如果图片加密失败，保留原路径但添加警告
            updatedImagePaths.add(imagePath);
            print('压缩包导出调试: 图片路径未更新: $imagePath');
          }
        }

        updatedRecord['imagePaths'] = updatedImagePaths;
        updatedRecords.add(updatedRecord);
      }

      updatedData['records'] = updatedRecords;

      // 5. 重新生成并加密更新后的JSON数据
      final updatedJsonStr = const JsonEncoder.withIndent(
        '  ',
      ).convert(updatedData);
      final updatedEncryptedJsonData = EncryptionService.encryptBytes(
        Uint8List.fromList(utf8.encode(updatedJsonStr)),
      );

      // 替换压缩包中的JSON数据
      // 由于archive.files是不可修改的列表，我们需要重新创建压缩包
      final updatedArchive = Archive();

      // 添加更新后的JSON数据
      updatedArchive.addFile(
        ArchiveFile(
          'data.encrypted',
          updatedEncryptedJsonData.length,
          updatedEncryptedJsonData,
        ),
      );

      // 添加所有图片文件
      for (final file in archive.files) {
        if (file.name.startsWith('images/')) {
          updatedArchive.addFile(file);
        }
      }

      // 添加元数据文件
      final packageInfo = await PackageInfo.fromPlatform();
      final manifest = {
        'version': '2.0',
        'type': 'zip_backup',
        'createdAt': DateTime.now().toIso8601String(),
        'imageCount': allImagePaths.length,
        'encryptedImages': true,
        'platform': Platform.operatingSystem,
        'appVersion': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'packageName': packageInfo.packageName,
      };
      final manifestData = utf8.encode(
        const JsonEncoder.withIndent('  ').convert(manifest),
      );
      updatedArchive.addFile(
        ArchiveFile('manifest.json', manifestData.length, manifestData),
      );

      // 7. 生成ZIP文件
      print('压缩包导出调试: 开始生成ZIP文件，包含 ${updatedArchive.files.length} 个文件');
      for (final file in updatedArchive.files) {
        print('压缩包导出调试: 文件: ${file.name}, 大小: ${file.size} bytes');
      }

      final zipData = ZipEncoder().encode(updatedArchive);
      if (zipData == null) {
        print('压缩包导出调试: ZIP编码器返回null');
        throw Exception('创建ZIP文件失败');
      }

      print('压缩包导出调试: ZIP文件生成成功，大小: ${zipData.length} bytes');

      // 8. 保存ZIP文件
      final dir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();

      String finalFileName;
      if (fileName != null && fileName.isNotEmpty) {
        finalFileName = fileName.endsWith('.zip') ? fileName : '$fileName.zip';
      } else {
        final packageInfo = await PackageInfo.fromPlatform();
        final packageName = packageInfo.packageName;
        final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
        finalFileName = '${packageName}_backup_$dateStr.zip';
      }

      final zipFile = File('${dir.path}/$finalFileName');
      print('压缩包导出调试: 准备保存ZIP文件到: ${zipFile.path}');

      try {
        await zipFile.writeAsBytes(zipData);
        print('压缩包导出调试: ZIP文件创建完成，文件大小: ${await zipFile.length()} bytes');
      } catch (e) {
        print('压缩包导出调试: 保存ZIP文件失败: $e');
        throw Exception('保存ZIP文件失败: $e');
      }

      // 更新最后备份时间
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_backup_time', now.toIso8601String());

      return zipFile.path;
    } catch (e) {
      print('压缩包导出调试: 导出失败 - $e');
      throw Exception('导出压缩包失败: $e');
    }
  }

  /// 从压缩包导入数据
  Future<void> importFromZipFile({
    ProviderContainer? container,
    String? filePath,
    String? fileName,
  }) async {
    try {
      File file;
      String finalFileName;

      if (filePath != null && fileName != null) {
        // 使用提供的文件路径和名称
        file = File(filePath);
        finalFileName = fileName;
      } else {
        // 选择文件
        final result = await FilePicker.platform.pickFiles(type: FileType.any);

        if (result == null || result.files.isEmpty) {
          throw Exception('未选择文件');
        }

        file = File(result.files.first.path!);
        finalFileName = result.files.first.name;
      }

      // 验证文件类型
      if (!EncryptionService.isZipBackupFile(finalFileName)) {
        throw Exception('请选择 .zip 格式的备份文件');
      }

      print('压缩包导入调试: 开始导入ZIP文件: $finalFileName');
      print('压缩包导入调试: 文件路径: ${file.path}');
      print('压缩包导入调试: 文件大小: ${await file.length()} bytes');

      // 读取ZIP文件
      final zipData = await file.readAsBytes();
      print('压缩包导入调试: ZIP数据读取完成，大小: ${zipData.length} bytes');

      final archive = ZipDecoder().decodeBytes(zipData);
      print('压缩包导入调试: ZIP文件解压完成，包含 ${archive.files.length} 个文件');

      // 列出所有文件
      for (final file in archive.files) {
        print('压缩包导入调试: 发现文件: ${file.name}, 大小: ${file.size} bytes');
      }

      // 1. 查找并解密JSON数据
      ArchiveFile? dataFile;
      print('压缩包导入调试: 开始查找数据文件...');
      for (final file in archive.files) {
        print('压缩包导入调试: 检查文件: ${file.name}');
        if (file.name == 'data.encrypted') {
          dataFile = file;
          print('压缩包导入调试: 找到数据文件: ${file.name}, 大小: ${file.size} bytes');
          break;
        }
      }

      if (dataFile == null) {
        print('压缩包导入调试: 未找到data.encrypted文件');
        throw Exception('ZIP文件中未找到数据文件');
      }

      // 解密JSON数据
      print('压缩包导入调试: 开始解密JSON数据...');
      String jsonStr;
      try {
        final decryptedJsonData = EncryptionService.decryptBytes(
          dataFile.content,
        );
        print('压缩包导入调试: JSON数据解密成功，解密后大小: ${decryptedJsonData.length} bytes');

        jsonStr = utf8.decode(decryptedJsonData);
        print('压缩包导入调试: JSON字符串转换完成，长度: ${jsonStr.length}');
      } catch (e) {
        print('压缩包导入调试: JSON解密失败: $e');
        rethrow;
      }

      // 2. 解析JSON数据
      final Map<String, dynamic> data = json.decode(jsonStr);
      print(
        '压缩包导入调试: JSON解析完成，事件数量: ${(data['events'] as List).length}, 记录数量: ${(data['records'] as List).length}',
      );

      // 3. 处理图片文件
      print('压缩包导入调试: 开始处理图片文件...');
      final imageStorageService = ImageStorageService();
      final Map<String, String> imagePathMapping = {}; // 相对路径 -> 新绝对路径
      int processedImageCount = 0;

      for (final archiveFile in archive.files) {
        if (archiveFile.name.startsWith('images/')) {
          print(
            '压缩包导入调试: 处理图片: ${archiveFile.name}, 大小: ${archiveFile.size} bytes',
          );
          try {
            // 解密图片
            print('压缩包导入调试: 开始解密图片: ${archiveFile.name}');
            final decryptedImageData = await EncryptionService.decryptImageFile(
              archiveFile.content,
            );
            print('压缩包导入调试: 图片解密成功，解密后大小: ${decryptedImageData.length} bytes');

            // 生成新的文件名
            final originalFileName = path.basename(archiveFile.name);
            final newFileName =
                '${const Uuid().v4()}${path.extension(originalFileName)}';
            print('压缩包导入调试: 新文件名: $newFileName');

            // 保存到应用图片目录
            final imagesDir = await imageStorageService.getImagesDirectory();
            final newImagePath = path.join(imagesDir.path, newFileName);
            print('压缩包导入调试: 保存图片到: $newImagePath');
            await File(newImagePath).writeAsBytes(decryptedImageData);

            // 记录路径映射
            imagePathMapping[archiveFile.name] = newImagePath;
            processedImageCount++;
            print('压缩包导入调试: 图片已解密并保存: $newImagePath');
          } catch (e) {
            print('压缩包导入调试: 解密图片失败: ${archiveFile.name}, 错误: $e');
            print('压缩包导入调试: 错误堆栈: ${e.toString()}');
          }
        }
      }

      print('压缩包导入调试: 图片处理完成，成功处理 $processedImageCount 张图片');

      // 4. 更新记录中的图片路径
      final updatedRecords = <Map<String, dynamic>>[];
      for (final record in data['records'] as List) {
        final updatedRecord = Map<String, dynamic>.from(record);
        final imagePaths = List<String>.from(record['imagePaths'] ?? []);
        final updatedImagePaths = <String>[];

        for (final imagePath in imagePaths) {
          if (imagePathMapping.containsKey(imagePath)) {
            updatedImagePaths.add(imagePathMapping[imagePath]!);
          } else {
            print('压缩包导入调试: 图片路径未找到映射: $imagePath');
          }
        }

        updatedRecord['imagePaths'] = updatedImagePaths;
        updatedRecords.add(updatedRecord);
      }

      data['records'] = updatedRecords;

      // 5. 导入数据到数据库
      final updatedJsonStr = const JsonEncoder.withIndent('  ').convert(data);
      await importFromJson(updatedJsonStr, container: container);

      print('压缩包导入调试: 数据导入完成');
    } catch (e) {
      print('压缩包导入调试: 导入失败 - $e');
      throw Exception('导入压缩包失败: $e');
    }
  }

  /// 从文件导入数据（支持加密和普通JSON）
  Future<void> importFromFile({ProviderContainer? container}) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result == null || result.files.isEmpty) {
        throw Exception('未选择文件');
      }

      final file = File(result.files.first.path!);
      final fileName = result.files.first.name;

      // 验证文件类型并选择导入方法
      if (EncryptionService.isZipBackupFile(fileName)) {
        // 使用压缩包导入方法
        await importFromZipFile(
          container: container,
          filePath: file.path,
          fileName: fileName,
        );
        return;
      }

      if (!EncryptionService.isJsonBackupFile(fileName) &&
          !EncryptionService.isEncryptedBackupFile(fileName)) {
        throw Exception('请选择 .drmbak、.json 或 .zip 格式的备份文件');
      }

      String jsonStr;

      if (EncryptionService.isEncryptedBackupFile(fileName)) {
        // 解密文件
        print('检测到加密备份文件，开始解密...');
        final encryptedData = await file.readAsBytes();
        final decryptedData = EncryptionService.decryptBytes(encryptedData);
        jsonStr = utf8.decode(decryptedData);
        print('解密完成，JSON长度: ${jsonStr.length}');
      } else {
        // 普通JSON文件
        jsonStr = await file.readAsString();
      }

      await importFromJson(jsonStr, container: container);
    } catch (e) {
      throw Exception('导入文件失败: $e');
    }
  }

  /// 从JSON字符串导入数据
  Future<void> importFromJson(
    String jsonString, {
    ProviderContainer? container,
  }) async {
    try {
      final data = json.decode(jsonString);

      // 检查数据格式
      if (data is! Map<String, dynamic>) {
        throw Exception('无效的数据格式');
      }

      // 检查版本兼容性
      final version = data['version'] as String? ?? '0.0';
      if (!_isVersionCompatible(version)) {
        throw Exception('不支持的数据版本: $version');
      }

      // 导入事件数据
      if (data['events'] is List) {
        final events = <Event>[];
        print('开始导入事件数据，原始事件数量: ${(data['events'] as List).length}');

        for (final item in data['events']) {
          try {
            final event = Event.fromJson(
              Map<String, dynamic>.from(item as Map),
            );
            events.add(event);
            print('成功解析事件: ${event.title}');
          } catch (e) {
            print('跳过无效事件数据: $e');
            continue;
          }
        }

        print('解析完成，有效事件数量: ${events.length}');

        // 清空现有事件并导入新事件
        final eventsBox = await Hive.openBox<Event>('eventsBox');
        await eventsBox.clear();
        print('清空现有事件完成');

        for (final event in events) {
          await eventsBox.put(event.id, event);
          print('保存事件到数据库: ${event.title}');
        }
        await eventsBox.flush();
        print('事件数据刷新完成，数据库中的事件数量: ${eventsBox.length}');
      } else {
        print('没有找到事件数据或数据格式不正确');
      }

      // 导入记录数据
      if (data['records'] is List) {
        final records = <EventRecord>[];
        for (final item in data['records']) {
          try {
            final record = EventRecord.fromJson(
              Map<String, dynamic>.from(item as Map),
            );
            records.add(record);
          } catch (e) {
            print('跳过无效记录数据: $e');
            continue;
          }
        }

        // 清空现有记录并导入新记录
        final recordsBox = await Hive.openBox<EventRecord>('event_records');
        await recordsBox.clear();
        for (final record in records) {
          await recordsBox.put(record.id, record);
        }
        await recordsBox.flush();
      }

      // 重新安排所有通知
      final eventsBox = await Hive.openBox<Event>('eventsBox');
      await NotificationService.instance.rescheduleAll(
        eventsBox.values.toList(),
      );

      // 强制刷新 Hive 数据
      await eventsBox.flush();
      final recordsBox = await Hive.openBox<EventRecord>('event_records');
      await recordsBox.flush();

      // 刷新Riverpod状态
      if (container != null) {
        try {
          // 刷新事件状态
          container.read(eventsProvider.notifier).refresh();
          // 刷新记录状态
          container.read(eventRecordsProvider.notifier).refresh();
          print('Riverpod状态已刷新');
        } catch (e) {
          print('刷新Riverpod状态失败: $e');
        }
      }
    } catch (e) {
      throw Exception('导入数据失败: $e');
    }
  }

  /// 检查版本兼容性
  bool _isVersionCompatible(String version) {
    // 目前支持版本 1.0
    return version == '1.0' || version.startsWith('1.');
  }

  /// 获取最后备份时间
  Future<DateTime?> getLastBackupTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeStr = prefs.getString('last_backup_time');
      if (timeStr != null) {
        return DateTime.parse(timeStr);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 获取所有备份文件
  Future<List<BackupFile>> getBackupFiles() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir
          .listSync()
          .where(
            (file) =>
                file is File &&
                (file.path.endsWith('.json') ||
                    file.path.endsWith('.drmbak') ||
                    file.path.endsWith('.zip')),
          )
          .cast<File>()
          .toList();

      final backupFiles = <BackupFile>[];
      for (final file in files) {
        try {
          final stat = await file.stat();
          final fileName = file.path.split('/').last;

          // 尝试解析文件名获取创建时间
          DateTime? createdAt;
          if (fileName.contains('_backup_')) {
            final parts = fileName.split('_backup_');
            if (parts.length == 2) {
              // 移除文件扩展名（.json、.drmbak 或 .zip）
              final dateStr = parts[1].replaceAll(
                RegExp(r'\.(json|drmbak|zip)$'),
                '',
              );
              try {
                createdAt = DateFormat('yyyyMMdd_HHmmss').parse(dateStr);
              } catch (e) {
                // 如果解析失败，使用文件修改时间
                createdAt = stat.modified;
              }
            }
          } else {
            createdAt = stat.modified;
          }

          backupFiles.add(
            BackupFile(
              path: file.path,
              name: fileName,
              size: stat.size,
              createdAt: createdAt ?? stat.modified,
            ),
          );
        } catch (e) {
          // 跳过无法处理的文件
          continue;
        }
      }

      // 按创建时间降序排列
      backupFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return backupFiles;
    } catch (e) {
      return [];
    }
  }

  /// 删除备份文件
  Future<void> deleteBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('删除备份文件失败: $e');
    }
  }

  /// 恢复备份文件
  Future<void> restoreBackupFile(
    String filePath, {
    ProviderContainer? container,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('备份文件不存在');
      }

      final fileName = filePath.split('/').last;
      print('恢复备份调试: 开始恢复文件: $fileName');

      // 根据文件类型选择恢复方法
      if (EncryptionService.isZipBackupFile(fileName)) {
        // 使用压缩包恢复方法
        print('恢复备份调试: 检测到ZIP文件，使用压缩包恢复');
        await importFromZipFile(
          container: container,
          filePath: filePath,
          fileName: fileName,
        );
        return;
      }

      // 处理.drmbak和.json文件
      String jsonStr;

      if (EncryptionService.isEncryptedBackupFile(filePath)) {
        // 解密文件
        print('恢复备份调试: 检测到加密备份文件，开始解密...');
        final encryptedData = await file.readAsBytes();
        final decryptedData = EncryptionService.decryptBytes(encryptedData);
        jsonStr = utf8.decode(decryptedData);
        print('恢复备份调试: 解密完成，JSON长度: ${jsonStr.length}');
      } else {
        // 普通JSON文件
        print('恢复备份调试: 检测到JSON文件');
        jsonStr = await file.readAsString();
      }

      await importFromJson(jsonStr, container: container);
      print('恢复备份调试: 恢复完成');
    } catch (e) {
      print('恢复备份调试: 恢复失败 - $e');
      throw Exception('恢复备份失败: $e');
    }
  }

  /// 验证导入数据的完整性
  Future<Map<String, dynamic>> validateImportData(String jsonString) async {
    try {
      final data = json.decode(jsonString);

      if (data is! Map<String, dynamic>) {
        return {
          'valid': false,
          'error': '无效的数据格式',
          'eventCount': 0,
          'recordCount': 0,
        };
      }

      final events = data['events'] as List? ?? [];
      final records = data['records'] as List? ?? [];

      int validEvents = 0;
      int validRecords = 0;

      // 验证事件数据
      for (final item in events) {
        try {
          Event.fromJson(Map<String, dynamic>.from(item as Map));
          validEvents++;
        } catch (e) {
          // 跳过无效事件
        }
      }

      // 验证记录数据
      for (final item in records) {
        try {
          EventRecord.fromJson(Map<String, dynamic>.from(item as Map));
          validRecords++;
        } catch (e) {
          // 跳过无效记录
        }
      }

      return {
        'valid': true,
        'eventCount': validEvents,
        'recordCount': validRecords,
        'totalEvents': events.length,
        'totalRecords': records.length,
        'version': data['version'] as String? ?? '未知',
        'exportTime': data['exportTime'] as String? ?? '未知',
      };
    } catch (e) {
      return {
        'valid': false,
        'error': '数据解析失败: $e',
        'eventCount': 0,
        'recordCount': 0,
      };
    }
  }
}
