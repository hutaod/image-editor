import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/id_photo_template.dart';
import '../models/id_photo_record.dart';
import '../services/image_service.dart';
import '../services/pdf_service.dart';
import '../services/print_layout_service.dart';
import '../services/database_service.dart';
import '../providers/id_photo_provider.dart';

/// 下载对话框（参考第九张图片）
class IdPhotoDownloadDialog extends HookConsumerWidget {
  final Uint8List imageBytes;
  final IdPhotoTemplate template;
  final int backgroundColor;

  const IdPhotoDownloadDialog({
    super.key,
    required this.imageBytes,
    required this.template,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedService = useState<int?>(null);
    final isDownloading = useState(false);

    Future<void> _download() async {
      if (selectedService.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请选择下载方式')),
        );
        return;
      }

      isDownloading.value = true;
      try {
        // 生成单张电子照
        final singlePhoto = imageBytes;

        // 生成排版照（10张排版）
        final layoutPhotos = <Uint8List>[];
        for (int i = 0; i < 10; i++) {
          layoutPhotos.add(singlePhoto);
        }
        final layoutImage = await PrintLayoutService.generate4x6Layout(
          images: layoutPhotos,
          template: template,
        );

        // 保存到相册
        if (selectedService.value == 0) {
          // 观看广告下载（免费）
          await ImageGallerySaver.saveImage(
            singlePhoto,
            quality: 100,
            name: 'id_photo_${DateTime.now().millisecondsSinceEpoch}',
          );
          await ImageGallerySaver.saveImage(
            layoutImage,
            quality: 100,
            name: 'id_photo_layout_${DateTime.now().millisecondsSinceEpoch}',
          );
        } else {
          // 付费下载
          await ImageGallerySaver.saveImage(
            singlePhoto,
            quality: 100,
            name: 'id_photo_${DateTime.now().millisecondsSinceEpoch}',
          );
          await ImageGallerySaver.saveImage(
            layoutImage,
            quality: 100,
            name: 'id_photo_layout_${DateTime.now().millisecondsSinceEpoch}',
          );
        }

        // 保存到历史记录
        await _saveToHistory(ref, singlePhoto, layoutImage);

        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('下载成功！')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('下载失败: $e')),
          );
        }
      } finally {
        isDownloading.value = false;
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和描述
              Row(
                children: [
                  // 缩略图
                  Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '包含「单张电子照」和「排版照」',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 价格
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '¥ 2.99',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[400],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 已选底色
              const Text(
                '已选底色',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Color(backgroundColor),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('已选择背景色'),
                ],
              ),
              const SizedBox(height: 16),
              // 可选服务
              const Text(
                '可选服务',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.2,
                children: [
                  _buildServiceOption(
                    context,
                    title: '观看广告下载',
                    subtitle: '30s~60s',
                    isSelected: selectedService.value == 0,
                    onTap: () => selectedService.value = 0,
                  ),
                  _buildServiceOption(
                    context,
                    title: '保存选中底色',
                    subtitle: '¥ 1.99',
                    isSelected: selectedService.value == 1,
                    onTap: () => selectedService.value = 1,
                  ),
                  _buildServiceOption(
                    context,
                    title: '保存7种底色',
                    subtitle: '¥ 2.99',
                    isRecommended: true,
                    isSelected: selectedService.value == 2,
                    onTap: () => selectedService.value = 2,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 支付按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isDownloading.value ? null : _download,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: isDownloading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('支付'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    bool isRecommended = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? (isRecommended ? Colors.pink : Colors.blue)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? (isRecommended ? Colors.pink[50] : Colors.blue[50])
              : Colors.white,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isRecommended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '推荐',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isRecommended) const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToHistory(
    WidgetRef ref,
    Uint8List singlePhoto,
    Uint8List layoutPhoto,
  ) async {
    try {
      // 保存图片到应用目录
      final appDir = await getApplicationDocumentsDirectory();
      final filename = '${const Uuid().v4()}.jpg';
      final imagePath = path.join(appDir.path, filename);
      await File(imagePath).writeAsBytes(singlePhoto);

      // 创建缩略图
      final thumbnailBytes = await ImageService.compressImage(
        singlePhoto,
        maxWidth: 200,
        maxHeight: 200,
      );
      final thumbnailPath = path.join(appDir.path, 'thumb_$filename');
      await File(thumbnailPath).writeAsBytes(thumbnailBytes);

      // 创建记录
      final record = IdPhotoRecord(
        id: const Uuid().v4(),
        processedImagePath: imagePath,
        templateId: template.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        thumbnailPath: thumbnailPath,
      );

      // 保存到数据库
      await DatabaseService.saveRecord(record);
      ref.read(idPhotoRecordsProvider.notifier).loadRecords();
    } catch (e) {
      // 忽略保存错误
    }
  }
}
