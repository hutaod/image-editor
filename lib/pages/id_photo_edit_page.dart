import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../services/image_service.dart';
import 'package:image/image.dart' as img;

/// 图片编辑页面（修改kb和dpi）
class IdPhotoEditPage extends HookConsumerWidget {
  const IdPhotoEditPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageBytes = useState<Uint8List?>(null);
    final processedImage = useState<Uint8List?>(null);
    final quality = useState<int>(85);
    final targetDpi = useState<int>(300);
    final targetWidth = useState<int?>(null);
    final targetHeight = useState<int?>(null);
    final isProcessing = useState<bool>(false);
    final originalSize = useState<int?>(null);
    final processedSize = useState<int?>(null);
    final originalDpi = useState<int?>(null);

    Future<void> _processImage() async {
      if (imageBytes.value == null) return;

      isProcessing.value = true;
      try {
        Uint8List result = imageBytes.value!;

        // 调整尺寸
        if (targetWidth.value != null && targetHeight.value != null) {
          result = await ImageService.resizeImage(
            result,
            targetWidth.value!,
            targetHeight.value!,
          );
        }

        // 调整质量（压缩）
        result = await ImageService.compressImage(
          result,
          quality: quality.value,
        );

        processedImage.value = result;
        processedSize.value = result.length;
      } finally {
        isProcessing.value = false;
      }
    }

    Future<void> _pickImage() async {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        imageBytes.value = bytes;
        processedImage.value = bytes;
        originalSize.value = bytes.length;
        processedSize.value = bytes.length;

        // 读取原始DPI（如果存在）
        try {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            originalDpi.value = decoded.exif.imageIfd['XResolution'] != null
                ? (decoded.exif.imageIfd['XResolution'] as num).toInt()
                : 72; // 默认72 DPI
            targetDpi.value = originalDpi.value ?? 300;
            targetWidth.value = decoded.width;
            targetHeight.value = decoded.height;
          }
        } catch (e) {
          originalDpi.value = 72;
        }

        _processImage();
      }
    }

    Future<void> _saveImage() async {
      if (processedImage.value == null) return;

      try {
        await ImageGallerySaver.saveImage(
          processedImage.value!,
          quality: 100,
          name: 'edited_${DateTime.now().millisecondsSinceEpoch}',
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


    String _formatSize(int? bytes) {
      if (bytes == null) return '0 KB';
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      }
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('图片编辑'),
      ),
      body: imageBytes.value == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '请选择一张照片',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('从相册选择'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
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
                      child: processedImage.value != null
                          ? Image.memory(
                              processedImage.value!,
                              fit: BoxFit.contain,
                            )
                          : const CircularProgressIndicator(),
                    ),
                  ),
                ),

                // 信息显示
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '原始大小',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatSize(originalSize.value),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '处理后大小',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatSize(processedSize.value),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '分辨率',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            targetWidth.value != null &&
                                    targetHeight.value != null
                                ? '${targetWidth.value}×${targetHeight.value}'
                                : '-',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 控制面板
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
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 质量调节
                        const Text(
                          '图片质量',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: quality.value.toDouble(),
                                min: 10,
                                max: 100,
                                divisions: 90,
                                label: '${quality.value}%',
                                onChanged: (value) {
                                  quality.value = value.toInt();
                                  _processImage();
                                },
                              ),
                            ),
                            Text(
                              '${quality.value}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // 尺寸调节
                        const Text(
                          '图片尺寸',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: '宽度 (px)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                controller: TextEditingController(
                                  text: targetWidth.value?.toString() ?? '',
                                )..addListener(() {
                                  final value = int.tryParse(
                                    TextEditingController(
                                      text: targetWidth.value?.toString() ?? '',
                                    ).text,
                                  );
                                  if (value != null && value > 0) {
                                    targetWidth.value = value;
                                  }
                                }),
                                onChanged: (value) {
                                  final intValue = int.tryParse(value);
                                  if (intValue != null && intValue > 0) {
                                    targetWidth.value = intValue;
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: '高度 (px)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                controller: TextEditingController(
                                  text: targetHeight.value?.toString() ?? '',
                                )..addListener(() {
                                  final value = int.tryParse(
                                    TextEditingController(
                                      text: targetHeight.value?.toString() ?? '',
                                    ).text,
                                  );
                                  if (value != null && value > 0) {
                                    targetHeight.value = value;
                                  }
                                }),
                                onChanged: (value) {
                                  final intValue = int.tryParse(value);
                                  if (intValue != null && intValue > 0) {
                                    targetHeight.value = intValue;
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  _processImage();
                                },
                                child: const Text('应用尺寸'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  if (imageBytes.value != null) {
                                    final decoded =
                                        img.decodeImage(imageBytes.value!);
                                    if (decoded != null) {
                                      targetWidth.value = decoded.width;
                                      targetHeight.value = decoded.height;
                                      _processImage();
                                    }
                                  }
                                },
                                child: const Text('恢复原始'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // 操作按钮
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isProcessing.value
                                ? null
                                : _saveImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: isProcessing.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('保存到相册'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
