import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import '../models/id_photo_record.dart';
import '../models/edit_params.dart';
import '../services/template_service.dart';
import '../providers/id_photo_provider.dart';
import 'id_photo_download_dialog.dart';

/// 历史记录详情页面
class IdPhotoHistoryDetailPage extends HookConsumerWidget {
  final IdPhotoRecord record;

  const IdPhotoHistoryDetailPage({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageBytes = useState<Uint8List?>(null);
    final isLoading = useState<bool>(true);

    final template = TemplateService.getTemplateById(record.templateId);
    final daysRemaining = 7 - DateTime.now().difference(record.createdAt).inDays;

    // 加载图片
    Future<void> _loadImage() async {
      try {
        if (record.processedImagePath != null) {
          final file = File(record.processedImagePath!);
          if (await file.exists()) {
            imageBytes.value = await file.readAsBytes();
          }
        }
      } catch (e) {
        // 忽略错误
      } finally {
        isLoading.value = false;
      }
    }

    // 加载图片
    useEffect(() {
      _loadImage();
      return null;
    }, []);

    Future<void> _saveToGallery() async {
      if (imageBytes.value == null) return;

      try {
        await ImageGallerySaver.saveImage(
          imageBytes.value!,
          quality: 100,
          name: 'id_photo_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存成功！')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存失败: $e')),
          );
        }
      }
    }

    Future<void> _shareImage() async {
      if (imageBytes.value == null) return;

      try {
        final tempDir = await Directory.systemTemp;
        final file = File(
          '${tempDir.path}/id_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await file.writeAsBytes(imageBytes.value!);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: '证件照',
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('分享失败: $e')),
          );
        }
      }
    }

    Future<void> _deleteRecord() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这条记录吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await ref.read(idPhotoRecordsProvider.notifier).deleteRecord(record.id);
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除成功')),
          );
        }
      }
    }

    Future<void> _reEdit() async {
      if (imageBytes.value == null || template == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法重新编辑')),
        );
        return;
      }

      // 解析背景颜色
      int backgroundColor = 0xFFFFFFFF; // 默认白色
      if (record.editParams != null) {
        try {
          final editParams = EditParams.fromMap(record.editParams!);
          if (editParams.background != null) {
            // 从hex字符串转换为int
            final colorStr = editParams.background!.color;
            if (colorStr.startsWith('#')) {
              backgroundColor = int.parse(colorStr.substring(1), radix: 16);
            } else {
              backgroundColor = int.parse(colorStr, radix: 16);
            }
          }
        } catch (e) {
          // 忽略解析错误，使用默认值
        }
      }

      // 导航到下载对话框，允许用户重新处理
      showDialog(
        context: context,
        builder: (context) => IdPhotoDownloadDialog(
          imageBytes: imageBytes.value!,
          template: template,
          backgroundColor: backgroundColor,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteRecord,
            tooltip: '删除',
          ),
        ],
      ),
      body: isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : imageBytes.value == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '图片已丢失',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // 图片预览
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: Colors.black,
                        child: Center(
                          child: Image.memory(
                            imageBytes.value!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // 信息卡片
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 基本信息
                          if (template != null) ...[
                            _buildInfoRow('尺寸名称', template.name),
                            _buildInfoRow(
                              '尺寸',
                              '${template.widthMm.toStringAsFixed(1)}×${template.heightMm.toStringAsFixed(1)}mm',
                            ),
                            _buildInfoRow(
                              '分辨率',
                              '${template.widthPx}×${template.heightPx}px',
                            ),
                            _buildInfoRow('DPI', '${template.dpi}'),
                          ],
                          _buildInfoRow(
                            '创建时间',
                            _formatDateTime(record.createdAt),
                          ),
                          if (daysRemaining > 0)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '剩余 $daysRemaining 天自动删除',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[900],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 16),

                          // 操作按钮
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _saveToGallery,
                                  icon: const Icon(Icons.download),
                                  label: const Text('保存'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _shareImage,
                                  icon: const Icon(Icons.share),
                                  label: const Text('分享'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _reEdit,
                              icon: const Icon(Icons.edit),
                              label: const Text('重新编辑'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
