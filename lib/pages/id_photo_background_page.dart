import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/id_photo_template.dart';
import '../services/image_service.dart';
import 'id_photo_adjust_page.dart';

/// 背景替换页面
class IdPhotoBackgroundPage extends HookConsumerWidget {
  final Uint8List imageBytes;
  final IdPhotoTemplate template;

  const IdPhotoBackgroundPage({
    super.key,
    required this.imageBytes,
    required this.template,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final processedImage = useState<Uint8List?>(imageBytes);
    final selectedColor = useState<int?>(null); // 默认不选择背景色
    final tolerance = useState<double>(0.25); // 提高默认容差，确保能替换完整背景
    final isProcessing = useState<bool>(false);

    // 预设颜色
    final presetColors = [
      0xFFFFFFFF, // 白色
      0xFF0066CC, // 蓝色
      0xFFDC143C, // 红色
      0xFF000000, // 黑色
    ];

    Future<void> _applyBackgroundReplacement() async {
      if (selectedColor.value == null) {
        // 如果没有选择背景色，显示原图
        processedImage.value = imageBytes;
        return;
      }

      isProcessing.value = true;
      try {
        final result = await ImageService.replaceBackground(
          imageBytes,
          selectedColor.value!,
          tolerance.value,
        );
        processedImage.value = result;
      } finally {
        isProcessing.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('背景替换'),
        actions: [
          TextButton(
            onPressed: isProcessing.value
                ? null
                : () async {
                    await _applyBackgroundReplacement();
                  },
            child: const Text('应用'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 图片预览
          Expanded(
            child: processedImage.value != null
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      // 获取模板比例
                      final templateAspect =
                          template.widthPx / template.heightPx;

                      // 计算背景替换页面的可用空间
                      final availableWidth = constraints.maxWidth;
                      final availableHeight = constraints.maxHeight;

                      // 直接根据模板宽高比和可用空间计算显示尺寸
                      // 裁剪后的图片已经是模板尺寸，不需要参考裁剪页面的裁剪框大小
                      // 限制在可用空间的80%内
                      double displayWidth, displayHeight;

                      // 先计算宽度80%的情况
                      final maxWidth = availableWidth * 0.8;
                      final maxHeight = availableHeight * 0.8;

                      // 如果宽度80%，计算对应的高度
                      final heightAtMaxWidth = maxWidth / templateAspect;

                      // 判断高度是否超过80%
                      if (heightAtMaxWidth <= maxHeight) {
                        // 高度不超过80%，以宽度80%为准
                        displayWidth = maxWidth;
                        displayHeight = heightAtMaxWidth;
                      } else {
                        // 高度超过80%，以高度80%为准，宽度自适应
                        displayHeight = maxHeight;
                        displayWidth = maxHeight * templateAspect;
                      }

                      return Container(
                        width: double.infinity,
                        color: Colors.white,
                        child: Center(
                          child: SizedBox(
                            width: displayWidth,
                            height: displayHeight,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Image.memory(
                                processedImage.value!,
                                // 使用 frameBuilder 确保图片正确加载
                                frameBuilder:
                                    (
                                      context,
                                      child,
                                      frame,
                                      wasSynchronouslyLoaded,
                                    ) {
                                      if (wasSynchronouslyLoaded) return child;
                                      return frame == null
                                          ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                          : child;
                                    },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : const Center(child: CircularProgressIndicator()),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 预设颜色
                const Text(
                  '预设颜色',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // "不设置背景"选项
                    GestureDetector(
                      onTap: () {
                        selectedColor.value = null;
                        _applyBackgroundReplacement();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor.value == null
                                ? Colors.blue
                                : Colors.grey,
                            width: selectedColor.value == null ? 3 : 1,
                          ),
                        ),
                        child: selectedColor.value == null
                            ? CustomPaint(
                                painter: _SlashPainter(),
                                size: const Size(40, 40),
                              )
                            : CustomPaint(
                                painter: _SlashPainter(),
                                size: const Size(40, 40),
                              ),
                      ),
                    ),
                    // 预设颜色
                    ...presetColors.map((color) {
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
                    }),
                    // 自定义颜色
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('选择颜色'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: selectedColor.value != null
                                    ? Color(selectedColor.value!)
                                    : Colors.white,
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
                  ],
                ),

                const SizedBox(height: 16),

                // 容差调节
                const Text(
                  '容差',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

                // 下一步按钮
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: processedImage.value == null
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => IdPhotoAdjustPage(
                                  imageBytes: processedImage.value!,
                                  template: template,
                                ),
                              ),
                            );
                          },
                    child: const Text(
                      '下一步：图像调节',
                      style: TextStyle(fontSize: 16),
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
}

/// 斜杠绘制器（用于"不设置背景"选项）
class _SlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[700]!
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 绘制从左上到右下的斜杠
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
