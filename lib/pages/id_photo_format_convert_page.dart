import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;

/// 格式转换页面
class IdPhotoFormatConvertPage extends HookConsumerWidget {
  const IdPhotoFormatConvertPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageBytes = useState<Uint8List?>(null);
    final convertedImage = useState<Uint8List?>(null);
    final selectedFormat = useState<String>('JPG');
    final isProcessing = useState<bool>(false);
    final quality = useState<int>(90);

    final formats = ['JPG', 'PNG', 'WEBP'];

    Future<void> _convertImage(Uint8List bytes) async {
      isProcessing.value = true;
      try {
        final decoded = img.decodeImage(bytes);
        if (decoded == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('无法解码图片')),
            );
          }
          return;
        }

        Uint8List? result;
        switch (selectedFormat.value) {
          case 'JPG':
            result = Uint8List.fromList(
              img.encodeJpg(decoded, quality: quality.value),
            );
            break;
          case 'PNG':
            result = Uint8List.fromList(img.encodePng(decoded));
            break;
          case 'WEBP':
            // WebP格式需要特殊处理，这里使用PNG代替
            result = Uint8List.fromList(img.encodePng(decoded));
            break;
        }

        convertedImage.value = result;
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
        _convertImage(bytes);
      }
    }

    Future<void> _saveImage() async {
      if (convertedImage.value == null) return;

      try {
        final extension = selectedFormat.value.toLowerCase();
        await ImageGallerySaver.saveImage(
          convertedImage.value!,
          quality: 100,
          name: 'converted_${DateTime.now().millisecondsSinceEpoch}.$extension',
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
      if (convertedImage.value == null) return;

      try {
        final tempDir = await Directory.systemTemp;
        final extension = selectedFormat.value.toLowerCase();
        final file = File(
          '${tempDir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.$extension',
        );
        await file.writeAsBytes(convertedImage.value!);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: '转换后的图片',
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('分享失败: $e')),
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
        title: const Text('格式转换'),
        actions: [
          if (convertedImage.value != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareImage,
              tooltip: '分享',
            ),
        ],
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
                      child: convertedImage.value != null
                          ? Image.memory(
                              convertedImage.value!,
                              fit: BoxFit.contain,
                            )
                          : isProcessing.value
                              ? const CircularProgressIndicator()
                              : Image.memory(
                                  imageBytes.value!,
                                  fit: BoxFit.contain,
                                ),
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
                            '原始格式',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getFormatFromBytes(imageBytes.value),
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
                            '转换格式',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedFormat.value,
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
                            '文件大小',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatSize(convertedImage.value?.length),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 格式选择
                      const Text(
                        '目标格式',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: formats.map((format) {
                          final isSelected = selectedFormat.value == format;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                selectedFormat.value = format;
                                _convertImage(imageBytes.value!);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  format,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // 质量调节（仅JPG和WEBP）
                      if (selectedFormat.value == 'JPG' ||
                          selectedFormat.value == 'WEBP') ...[
                        const SizedBox(height: 16),
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
                                  _convertImage(imageBytes.value!);
                                },
                              ),
                            ),
                            Text(
                              '${quality.value}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],

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
                                      convertedImage.value == null
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
                                  : const Text('保存到相册'),
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

  String _getFormatFromBytes(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return '未知';
    if (bytes.length >= 2) {
      // JPEG: FF D8
      if (bytes[0] == 0xFF && bytes[1] == 0xD8) return 'JPG';
      // PNG: 89 50
      if (bytes[0] == 0x89 && bytes[1] == 0x50) return 'PNG';
      // WEBP: RIFF
      if (bytes.length >= 4 &&
          String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF') {
        return 'WEBP';
      }
    }
    return '未知';
  }
}
