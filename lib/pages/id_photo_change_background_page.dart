import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/image_service.dart';

/// 修改底色页面（用于已有照片更换底色）
class IdPhotoChangeBackgroundPage extends HookConsumerWidget {
  const IdPhotoChangeBackgroundPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageBytes = useState<Uint8List?>(null);
    final processedImage = useState<Uint8List?>(null);
    final selectedColor = useState<int>(0xFFFFFFFF); // 白色
    final tolerance = useState<double>(0.3);
    final isProcessing = useState<bool>(false);

    // 预设颜色
    final presetColors = [
      0xFFFFFFFF, // 白色
      0xFF0066CC, // 蓝色
      0xFFDC143C, // 红色
      0xFF000000, // 黑色
    ];

    Future<void> _pickImage() async {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        imageBytes.value = bytes;
        processedImage.value = bytes;
      }
    }

    Future<void> _applyBackgroundReplacement() async {
      if (imageBytes.value == null) return;
      
      isProcessing.value = true;
      try {
        final result = await ImageService.replaceBackground(
          imageBytes.value!,
          selectedColor.value,
          tolerance.value,
        );
        processedImage.value = result;
      } finally {
        isProcessing.value = false;
      }
    }

    Future<void> _saveImage() async {
      if (processedImage.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先选择图片')),
        );
        return;
      }

      isProcessing.value = true;
      try {
        // 请求相册权限
        if (await Permission.photos.isDenied) {
          await Permission.photos.request();
        }

        if (await Permission.photos.isGranted) {
          await ImageGallerySaver.saveImage(
            processedImage.value!,
            quality: 100,
            name: 'background_${DateTime.now().millisecondsSinceEpoch}',
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('保存成功'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('需要相册权限才能保存图片'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存失败: $e')),
          );
        }
      } finally {
        isProcessing.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('修改底色'),
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
                        // 预设颜色
                        const Text(
                          '预设颜色',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: presetColors.map((color) {
                            final isSelected = selectedColor.value == color;
                            return GestureDetector(
                              onTap: () {
                                selectedColor.value = color;
                                _applyBackgroundReplacement();
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Color(color),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.blue : Colors.grey,
                                    width: isSelected ? 3 : 1,
                                  ),
                                ),
                              ),
                            );
                          }).toList()
                            ..add(
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('选择颜色'),
                                      content: SingleChildScrollView(
                                        child: ColorPicker(
                                          pickerColor: Color(selectedColor.value),
                                          onColorChanged: (color) {
                                            selectedColor.value = color.value;
                                          },
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _applyBackgroundReplacement();
                                          },
                                          child: const Text('确定'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  child: const Icon(Icons.add, size: 20),
                                ),
                              ),
                            ),
                        ),

                        const SizedBox(height: 16),

                        // 容差调节
                        const Text(
                          '容差',
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
                                value: tolerance.value,
                                min: 0.0,
                                max: 1.0,
                                divisions: 100,
                                label: '${(tolerance.value * 100).toInt()}%',
                                onChanged: (value) {
                                  tolerance.value = value;
                                  _applyBackgroundReplacement();
                                },
                              ),
                            ),
                            Text(
                              '${(tolerance.value * 100).toInt()}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // 操作按钮
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.refresh),
                                label: const Text('重新选择'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isProcessing.value ||
                                        processedImage.value == null
                                    ? null
                                    : _saveImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
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
                                    : const Text('保存'),
                              ),
                            ),
                          ],
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
