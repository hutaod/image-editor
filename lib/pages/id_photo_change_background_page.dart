import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/image_service.dart';
import 'id_photo_download_dialog.dart';
import '../models/id_photo_template.dart';
import '../services/template_service.dart';

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
    final selectedTemplate = useState<IdPhotoTemplate?>(null);

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
      if (processedImage.value == null || selectedTemplate.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先选择图片和尺寸模板')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => IdPhotoDownloadDialog(
          imageBytes: processedImage.value!,
          template: selectedTemplate.value!,
          backgroundColor: selectedColor.value,
        ),
      );
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
                        // 选择尺寸模板
                        const Text(
                          '选择尺寸',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: TemplateService.getAllTemplates()
                                .take(6)
                                .map((template) {
                              final isSelected =
                                  selectedTemplate.value?.id == template.id;
                              return GestureDetector(
                                onTap: () {
                                  selectedTemplate.value = template;
                                },
                                child: Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: isSelected
                                        ? Colors.blue[50]
                                        : Colors.white,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        template.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${template.widthMm.toInt()}×${template.heightMm.toInt()}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 16),

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
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: isProcessing.value ||
                                        processedImage.value == null ||
                                        selectedTemplate.value == null
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
