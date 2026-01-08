import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:gal/gal.dart';

/// 图片存储服务
class ImageStorageService {
  static final ImageStorageService _instance = ImageStorageService._internal();
  factory ImageStorageService() => _instance;
  ImageStorageService._internal();

  /// 获取应用文档目录
  Future<Directory> get _documentsDirectory async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(directory.path, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  /// 获取图片目录（公共方法）
  Future<Directory> getImagesDirectory() async {
    return await _documentsDirectory;
  }

  /// 复制图片到永久存储
  Future<String> copyImageToPermanentStorage(String sourcePath) async {
    try {
      print('开始复制图片: $sourcePath');

      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        print('源文件不存在: $sourcePath');
        throw Exception('源文件不存在: $sourcePath');
      }

      // 生成唯一文件名
      final fileName = '${const Uuid().v4()}${path.extension(sourcePath)}';
      final imagesDir = await _documentsDirectory;
      final destinationPath = path.join(imagesDir.path, fileName);

      print('目标路径: $destinationPath');

      // 复制文件
      await sourceFile.copy(destinationPath);

      print('图片复制成功: $destinationPath');
      return destinationPath;
    } catch (e) {
      print('复制图片失败: $e');
      throw Exception('复制图片失败: $e');
    }
  }

  /// 复制图片到永久存储并保存到相册（仅用于拍照）
  Future<String> copyImageToPermanentStorageAndGallery(
    String sourcePath,
  ) async {
    try {
      print('开始复制图片到永久存储并保存到相册: $sourcePath');

      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        print('源文件不存在: $sourcePath');
        throw Exception('源文件不存在: $sourcePath');
      }

      // 生成唯一文件名
      final fileName = '${const Uuid().v4()}${path.extension(sourcePath)}';
      final imagesDir = await _documentsDirectory;
      final destinationPath = path.join(imagesDir.path, fileName);

      print('目标路径: $destinationPath');

      // 复制文件到应用目录
      await sourceFile.copy(destinationPath);

      // 同时保存到手机相册（仅用于拍照）
      try {
        await Gal.putImage(sourcePath);
        print('图片已保存到相册: $sourcePath');
      } catch (e) {
        print('保存到相册时出错: $e');
        // 不影响主要功能，继续执行
      }

      print('图片复制成功: $destinationPath');
      return destinationPath;
    } catch (e) {
      print('复制图片失败: $e');
      throw Exception('复制图片失败: $e');
    }
  }

  /// 复制多张图片到永久存储
  Future<List<String>> copyImagesToPermanentStorage(
    List<String> sourcePaths,
  ) async {
    final List<String> permanentPaths = [];

    for (final sourcePath in sourcePaths) {
      try {
        final permanentPath = await copyImageToPermanentStorage(sourcePath);
        permanentPaths.add(permanentPath);
      } catch (e) {
        // 如果某张图片复制失败，记录错误但继续处理其他图片
        print('复制图片失败: $sourcePath, 错误: $e');
      }
    }

    return permanentPaths;
  }

  /// 复制多张图片到永久存储并保存到相册
  Future<List<String>> copyImagesToPermanentStorageAndGallery(
    List<String> sourcePaths,
  ) async {
    final List<String> permanentPaths = [];

    for (final sourcePath in sourcePaths) {
      try {
        final permanentPath = await copyImageToPermanentStorageAndGallery(
          sourcePath,
        );
        permanentPaths.add(permanentPath);
      } catch (e) {
        // 如果某张图片复制失败，记录错误但继续处理其他图片
        print('复制图片失败: $sourcePath, 错误: $e');
      }
    }

    return permanentPaths;
  }

  /// 检查图片文件是否存在
  Future<bool> imageExists(String imagePath) async {
    try {
      final file = File(imagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// 删除图片文件
  Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('删除图片失败: $imagePath, 错误: $e');
      return false;
    }
  }

  /// 删除多张图片文件
  Future<void> deleteImages(List<String> imagePaths) async {
    for (final imagePath in imagePaths) {
      await deleteImage(imagePath);
    }
  }

  /// 获取存储的图片总数
  Future<int> getImageCount() async {
    try {
      final imagesDir = await _documentsDirectory;
      final files = await imagesDir.list().toList();
      return files.where((file) => file is File).length;
    } catch (e) {
      return 0;
    }
  }

  /// 获取存储空间大小（字节）
  Future<int> getStorageSize() async {
    try {
      final imagesDir = await _documentsDirectory;
      int totalSize = 0;

      await for (final entity in imagesDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// 清理无效的图片引用
  Future<List<String>> cleanupInvalidImages(List<String> imagePaths) async {
    final List<String> validPaths = [];

    for (final imagePath in imagePaths) {
      try {
        if (await imageExists(imagePath)) {
          validPaths.add(imagePath);
          print('图片路径有效: $imagePath');
        } else {
          print('图片路径无效，已跳过: $imagePath');
        }
      } catch (e) {
        print('检查图片路径时出错: $imagePath, 错误: $e');
      }
    }

    print('清理完成，有效路径数量: ${validPaths.length}/${imagePaths.length}');
    return validPaths;
  }
}
