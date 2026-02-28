import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/id_photo_template.dart';
import '../services/image_service.dart';
import 'id_photo_export_page.dart';

/// 图像调节页面
class IdPhotoAdjustPage extends HookConsumerWidget {
  final Uint8List imageBytes;
  final IdPhotoTemplate template;

  const IdPhotoAdjustPage({
    super.key,
    required this.imageBytes,
    required this.template,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final processedImage = useState<Uint8List?>(imageBytes);
    final brightness = useState<double>(0.0);
    final contrast = useState<double>(0.0);
    final saturation = useState<double>(0.0);
    final sharpness = useState<double>(0.0);
    final denoise = useState<double>(0.0);
    final isProcessing = useState<bool>(false);

    Future<void> _applyAdjustments() async {
      isProcessing.value = true;
      try {
        var result = imageBytes;

        // 应用各项调节
        if (brightness.value != 0.0) {
          result = await ImageService.adjustBrightness(result, brightness.value);
        }
        if (contrast.value != 0.0) {
          result = await ImageService.adjustContrast(result, contrast.value);
        }
        if (saturation.value != 0.0) {
          result = await ImageService.adjustSaturation(result, saturation.value);
        }
        if (sharpness.value > 0.0) {
          result = await ImageService.sharpen(result, sharpness.value);
        }
        if (denoise.value > 0.0) {
          result = await ImageService.denoise(result, denoise.value);
        }

        processedImage.value = result;
      } finally {
        isProcessing.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('图像调节'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              brightness.value = 0.0;
              contrast.value = 0.0;
              saturation.value = 0.0;
              sharpness.value = 0.0;
              denoise.value = 0.0;
              processedImage.value = imageBytes;
            },
            tooltip: '重置',
          ),
        ],
      ),
      body: Column(
        children: [
          // 图片预览
          Expanded(
            child: Center(
              child: processedImage.value != null
                  ? Image.memory(
                      processedImage.value!,
                      fit: BoxFit.contain,
                    )
                  : const CircularProgressIndicator(),
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
                  // 亮度
                  _buildSlider(
                    context,
                    label: '亮度',
                    value: brightness.value,
                    min: -1.0,
                    max: 1.0,
                    onChanged: (value) {
                      brightness.value = value;
                      _applyAdjustments();
                    },
                  ),

                  const SizedBox(height: 16),

                  // 对比度
                  _buildSlider(
                    context,
                    label: '对比度',
                    value: contrast.value,
                    min: -1.0,
                    max: 1.0,
                    onChanged: (value) {
                      contrast.value = value;
                      _applyAdjustments();
                    },
                  ),

                  const SizedBox(height: 16),

                  // 饱和度
                  _buildSlider(
                    context,
                    label: '饱和度',
                    value: saturation.value,
                    min: -1.0,
                    max: 1.0,
                    onChanged: (value) {
                      saturation.value = value;
                      _applyAdjustments();
                    },
                  ),

                  const SizedBox(height: 16),

                  // 锐化
                  _buildSlider(
                    context,
                    label: '锐化',
                    value: sharpness.value,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) {
                      sharpness.value = value;
                      _applyAdjustments();
                    },
                  ),

                  const SizedBox(height: 16),

                  // 降噪
                  _buildSlider(
                    context,
                    label: '降噪',
                    value: denoise.value,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) {
                      denoise.value = value;
                      _applyAdjustments();
                    },
                  ),

                  const SizedBox(height: 16),

                  // 完成按钮
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: processedImage.value == null
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => IdPhotoExportPage(
                                    imageBytes: processedImage.value!,
                                    template: template,
                                  ),
                                ),
                              );
                            },
                      child: const Text(
                        '完成并导出',
                        style: TextStyle(fontSize: 16),
                      ),
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

  Widget _buildSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value == 0.0
                  ? '0'
                  : value > 0
                      ? '+${(value * 100).toInt()}'
                      : '${(value * 100).toInt()}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 200,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
