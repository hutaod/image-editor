import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/image_service.dart';
import '../models/id_photo_template.dart';
import 'id_photo_download_dialog.dart';

/// 自定义尺寸页面
class IdPhotoCustomSizePage extends HookConsumerWidget {
  const IdPhotoCustomSizePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageBytes = useState<Uint8List?>(null);
    final processedImage = useState<Uint8List?>(null);
    final widthMm = useState<TextEditingController>(
      TextEditingController(text: '25'),
    );
    final heightMm = useState<TextEditingController>(
      TextEditingController(text: '35'),
    );
    final dpi = useState<TextEditingController>(
      TextEditingController(text: '300'),
    );
    final backgroundColor = useState<int>(0xFFFFFFFF);
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

    Future<void> _processImage() async {
      if (imageBytes.value == null) return;

      final widthMmValue = double.tryParse(widthMm.value.text);
      final heightMmValue = double.tryParse(heightMm.value.text);
      final dpiValue = int.tryParse(dpi.value.text);

      if (widthMmValue == null ||
          heightMmValue == null ||
          dpiValue == null ||
          widthMmValue <= 0 ||
          heightMmValue <= 0 ||
          dpiValue <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入有效的尺寸和DPI')),
        );
        return;
      }

      isProcessing.value = true;
      try {
        // mm转px: px = mm * dpi / 25.4
        final widthPx = (widthMmValue * dpiValue / 25.4).round();
        final heightPx = (heightMmValue * dpiValue / 25.4).round();

        // 裁剪图片到指定尺寸
        final imageSize = await ImageService.getImageSize(imageBytes.value!);
        final aspectRatio = widthPx / heightPx;
        final imageAspectRatio = imageSize.width / imageSize.height;

        Uint8List cropped;
        if (imageAspectRatio > aspectRatio) {
          // 图片更宽，以高度为准
          final cropHeight = imageSize.height.toInt();
          final cropWidth = (cropHeight * aspectRatio).round();
          final cropX = ((imageSize.width - cropWidth) / 2).round();
          cropped = await ImageService.cropImage(
            imageBytes.value!,
            cropX,
            0,
            cropWidth,
            cropHeight,
          );
        } else {
          // 图片更高，以宽度为准
          final cropWidth = imageSize.width.toInt();
          final cropHeight = (cropWidth / aspectRatio).round();
          final cropY = ((imageSize.height - cropHeight) / 2).round();
          cropped = await ImageService.cropImage(
            imageBytes.value!,
            0,
            cropY,
            cropWidth,
            cropHeight,
          );
        }

        // 调整到目标尺寸
        final resized = await ImageService.resizeImage(
          cropped,
          widthPx,
          heightPx,
        );

        // 替换背景
        final result = await ImageService.replaceBackground(
          resized,
          backgroundColor.value,
          0.3,
        );

        processedImage.value = result;
      } finally {
        isProcessing.value = false;
      }
    }

    Future<void> _saveImage() async {
      if (processedImage.value == null) return;

      final widthMmValue = double.tryParse(widthMm.value.text);
      final heightMmValue = double.tryParse(heightMm.value.text);
      final dpiValue = int.tryParse(dpi.value.text);

      if (widthMmValue == null ||
          heightMmValue == null ||
          dpiValue == null) {
        return;
      }

      // 创建临时模板
      final widthPx = (widthMmValue * dpiValue / 25.4).round();
      final heightPx = (heightMmValue * dpiValue / 25.4).round();

      final template = IdPhotoTemplate(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: '自定义尺寸',
        nameEn: 'Custom Size',
        widthMm: widthMmValue,
        heightMm: heightMmValue,
        widthPx: widthPx,
        heightPx: heightPx,
        dpi: dpiValue,
        backgroundColor: '#${backgroundColor.value.toRadixString(16).padLeft(8, '0')}',
        printCount: 10,
        country: '自定义',
        isPremium: false,
      );

      showDialog(
        context: context,
        builder: (context) => IdPhotoDownloadDialog(
          imageBytes: processedImage.value!,
          template: template,
          backgroundColor: backgroundColor.value,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('自定义尺寸'),
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
                        // 尺寸输入
                        const Text(
                          '尺寸设置',
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
                                controller: widthMm.value,
                                decoration: const InputDecoration(
                                  labelText: '宽度 (mm)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: heightMm.value,
                                decoration: const InputDecoration(
                                  labelText: '高度 (mm)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: dpi.value,
                          decoration: const InputDecoration(
                            labelText: '分辨率 (DPI)',
                            border: OutlineInputBorder(),
                            helperText: '建议: 300 DPI',
                          ),
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 16),

                        // 背景颜色
                        const Text(
                          '背景颜色',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: presetColors.map((color) {
                            final isSelected = backgroundColor.value == color;
                            return GestureDetector(
                              onTap: () {
                                backgroundColor.value = color;
                                _processImage();
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
                                          pickerColor: Color(backgroundColor.value),
                                          onColorChanged: (color) {
                                            backgroundColor.value = color.value;
                                          },
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _processImage();
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
                                onPressed: isProcessing.value
                                    ? null
                                    : () {
                                        _processImage();
                                      },
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
                                    : const Text('生成证件照'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isProcessing.value ||
                                    processedImage.value == null
                                ? null
                                : _saveImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('保存'),
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
