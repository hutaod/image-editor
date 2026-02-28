import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/id_photo_template.dart';
import '../services/image_service.dart';
import 'id_photo_download_dialog.dart';

/// 拍摄完成后的预览页面
class IdPhotoPreviewPage extends HookConsumerWidget {
  final String imagePath;
  final IdPhotoTemplate template;

  const IdPhotoPreviewPage({
    super.key,
    required this.imagePath,
    required this.template,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedColor = useState<int>(0xFF0066CC); // 默认蓝色
    final processedImage = useState<Uint8List?>(null);
    final isProcessing = useState(false);
    final activeTab = useState(0); // 0: 电子照片, 1: 排版电子照

    // 预设颜色
    final presetColors = [
      0xFFFFFFFF, // 白色
      0xFF0066CC, // 蓝色
      0xFFDC143C, // 红色
      0xFF000000, // 黑色
      0xFFE0E0E0, // 灰色
      0xFF87CEEB, // 天蓝色
      0xFF000080, // 深蓝色
    ];

    Future<void> loadAndProcessImage() async {
      isProcessing.value = true;
      try {
        final imageBytes = await File(imagePath).readAsBytes();
        // 修正 EXIF 方向
        final fixedBytes = await ImageService.fixOrientation(imageBytes);
        // 获取图片尺寸
        final imageSize = await ImageService.getImageSize(fixedBytes);
        // 裁剪和调整尺寸
        final decoded = await ImageService.cropImage(
          fixedBytes,
          0,
          0,
          imageSize.width.toInt(),
          imageSize.height.toInt(),
        );
        // 调整到模板尺寸
        final resized = await ImageService.resizeImage(
          decoded,
          template.widthPx,
          template.heightPx,
          maintainAspect: false,
        );
        // 先使用简单的颜色阈值替换（更快），如果用户需要再使用人脸检测
        // 避免拍照后长时间卡顿
        final processed = await ImageService.replaceBackground(
          resized,
          selectedColor.value,
          0.3,
        );
        processedImage.value = processed;
      } catch (e) {
        print('图片处理失败: $e');
        // 如果处理失败，至少显示原始图片
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('图片处理失败: $e')),
          );
        }
      } finally {
        isProcessing.value = false;
      }
    }

    // 加载并处理图片
    useEffect(() {
      loadAndProcessImage();
      return null;
    }, []);

    Future<void> _changeBackgroundColor(int color) async {
      selectedColor.value = color;
      isProcessing.value = true;
      try {
        final imageBytes = await File(imagePath).readAsBytes();
        final fixedBytes = await ImageService.fixOrientation(imageBytes);
        final imageSize = await ImageService.getImageSize(fixedBytes);
        final decoded = await ImageService.cropImage(
          fixedBytes,
          0,
          0,
          imageSize.width.toInt(),
          imageSize.height.toInt(),
        );
        final resized = await ImageService.resizeImage(
          decoded,
          template.widthPx,
          template.heightPx,
          maintainAspect: false,
        );
        // 使用简单的颜色阈值替换（更快）
        final processed = await ImageService.replaceBackground(
          resized,
          color,
          0.3,
        );
        processedImage.value = processed;
      } finally {
        isProcessing.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('选择底色'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 标签页
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTab(
                    context,
                    '电子照片',
                    0,
                    activeTab.value == 0,
                    () => activeTab.value = 0,
                  ),
                ),
                Expanded(
                  child: _buildTab(
                    context,
                    '(赠)排版电子照',
                    1,
                    activeTab.value == 1,
                    () => activeTab.value = 1,
                  ),
                ),
              ],
            ),
          ),

          // 图片预览区域
          Expanded(
            child: Center(
              child: Stack(
                children: [
                  if (processedImage.value != null)
                    Image.memory(
                      processedImage.value!,
                      fit: BoxFit.contain,
                    )
                  else
                    const CircularProgressIndicator(),

                  // 尺寸标注
                  if (processedImage.value != null)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${template.widthPx}px',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (processedImage.value != null)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${template.heightPx}px',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (processedImage.value != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${template.widthMm}mm',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (processedImage.value != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${template.heightMm}mm',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 水印（预览）
                  if (processedImage.value != null)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '下载后无水印',
                              style: TextStyle(fontSize: 10),
                            ),
                            const Text(
                              'ORIGINAL',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('⭐⭐⭐⭐', style: TextStyle(fontSize: 8)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 底部控制区域
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
                // 选择底色
                const Row(
                  children: [
                    Icon(Icons.layers, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '选择底色',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...presetColors.map((color) {
                        final isSelected = selectedColor.value == color;
                        return GestureDetector(
                          onTap: () => _changeBackgroundColor(color),
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
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      }),
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
                                    _changeBackgroundColor(color.value);
                                  },
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 操作按钮
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('重新拍摄'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: processedImage.value == null
                            ? null
                            : () {
                                showDialog(
                                  context: context,
                                  builder: (context) => IdPhotoDownloadDialog(
                                    imageBytes: processedImage.value!,
                                    template: template,
                                    backgroundColor: selectedColor.value,
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('下载证件照'),
                      ),
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

  Widget _buildTab(
    BuildContext context,
    String label,
    int index,
    bool isActive,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.blue : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
