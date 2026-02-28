import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/id_photo_template.dart';
import '../models/id_photo_record.dart';
import '../services/image_service.dart';
import '../services/pdf_service.dart';
import '../services/database_service.dart';
import '../providers/id_photo_provider.dart';

/// 导出页面
class IdPhotoExportPage extends HookConsumerWidget {
  final Uint8List imageBytes;
  final IdPhotoTemplate template;

  const IdPhotoExportPage({
    super.key,
    required this.imageBytes,
    required this.template,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaving = useState<bool>(false);

    Future<void> _saveToGallery() async {
      isSaving.value = true;
      try {
        final result = await ImageGallerySaver.saveImage(
          imageBytes,
          quality: 100,
          name: 'id_photo_${DateTime.now().millisecondsSinceEpoch}',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['isSuccess'] == true ? '已保存到相册' : '保存失败')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存失败: $e')),
          );
        }
      } finally {
        isSaving.value = false;
      }
    }

    Future<void> _exportAsPdf() async {
      isSaving.value = true;
      try {
        final pdfPath = await PdfService.generateSinglePhoto(
          image: imageBytes,
          template: template,
        );
        if (context.mounted) {
          await Share.shareXFiles([XFile(pdfPath)]);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('导出失败: $e')),
          );
        }
      } finally {
        isSaving.value = false;
      }
    }

    Future<void> _saveRecord() async {
      isSaving.value = true;
      try {
        // 保存图片到应用目录
        final appDir = await getApplicationDocumentsDirectory();
        final filename = '${const Uuid().v4()}.jpg';
        final imagePath = path.join(appDir.path, filename);
        await File(imagePath).writeAsBytes(imageBytes);

        // 创建缩略图
        final thumbnailBytes = await ImageService.compressImage(
          imageBytes,
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

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已保存到历史记录')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存失败: $e')),
          );
        }
      } finally {
        isSaving.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('导出'),
      ),
      body: Column(
        children: [
          // 预览
          Expanded(
            child: Center(
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 导出选项
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 模板信息
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                template.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${template.widthMm} × ${template.heightMm} mm',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 导出按钮
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isSaving.value ? null : _saveToGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('保存到相册'),
                    ),
                    ElevatedButton.icon(
                      onPressed: isSaving.value ? null : _exportAsPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('导出 PDF'),
                    ),
                    ElevatedButton.icon(
                      onPressed: isSaving.value
                          ? null
                          : () async {
                              final tempFile = await ImageService.saveToTemp(
                                imageBytes,
                                'id_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
                              );
                              await Share.shareXFiles([XFile(tempFile)]);
                            },
                      icon: const Icon(Icons.share),
                      label: const Text('分享'),
                    ),
                    ElevatedButton.icon(
                      onPressed: isSaving.value ? null : _saveRecord,
                      icon: const Icon(Icons.save),
                      label: const Text('保存记录'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
