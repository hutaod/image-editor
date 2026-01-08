import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

class ImageCompressPage extends StatefulWidget {
  const ImageCompressPage({super.key});

  @override
  State<ImageCompressPage> createState() => _ImageCompressPageState();
}

class _ImageCompressPageState extends State<ImageCompressPage> {
  File? _selectedImage;
  int _quality = 85;
  double _scale = 1.0;
  bool _isProcessing = false;
  int? _originalSize;
  int? _compressedSize;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final file = File(image.path);
      final size = await file.length();
      setState(() {
        _selectedImage = file;
        _originalSize = size;
        _compressedSize = null;
      });
    }
  }

  Future<void> _compressAndSave() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择图片')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // 读取原始图片
      final imageBytes = await _selectedImage!.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        throw Exception('无法解码图片');
      }

      // 计算新尺寸
      final newWidth = (originalImage.width * _scale).round();
      final newHeight = (originalImage.height * _scale).round();

      // 调整尺寸
      img.Image resizedImage = originalImage;
      if (_scale < 1.0) {
        resizedImage = img.copyResize(
          originalImage,
          width: newWidth,
          height: newHeight,
        );
      }

      // 压缩质量
      final compressedBytes = img.encodeJpg(
        resizedImage,
        quality: _quality,
      );

      _compressedSize = compressedBytes.length;

      // 请求存储权限
      if (await Permission.photos.isDenied) {
        await Permission.photos.request();
      }

      if (await Permission.photos.isGranted) {
        await ImageGallerySaver.saveImage(
          compressedBytes,
          quality: 100,
          name: 'compressed_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '压缩完成！原始: ${_formatSize(_originalSize!)}, 压缩后: ${_formatSize(_compressedSize!)}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('需要相册权限才能保存图片'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('压缩失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图片压缩'),
      ),
      body: _selectedImage == null
          ? _buildEmptyState()
          : _buildEditorView(),
      floatingActionButton: _selectedImage != null
          ? FloatingActionButton.extended(
              onPressed: _isProcessing ? null : _compressAndSave,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isProcessing ? '压缩中...' : '保存'),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.compress,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            '选择一张图片开始压缩',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '可以调整图片质量和尺寸',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_library),
            label: const Text('选择图片'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorView() {
    return Column(
      children: [
        // 图片预览
        Expanded(
          child: Center(
            child: Image.file(
              _selectedImage!,
              fit: BoxFit.contain,
            ),
          ),
        ),
        // 压缩设置
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_originalSize != null) ...[
                  Text(
                    '原始大小: ${_formatSize(_originalSize!)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (_compressedSize != null)
                    Text(
                      '压缩后: ${_formatSize(_compressedSize!)} (减少 ${((1 - _compressedSize! / _originalSize!) * 100).toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  const SizedBox(height: 16),
                ],
                Text(
                  '质量: $_quality%',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Slider(
                  value: _quality.toDouble(),
                  min: 10,
                  max: 100,
                  divisions: 90,
                  label: '$_quality%',
                  onChanged: (value) {
                    setState(() {
                      _quality = value.round();
                      _compressedSize = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  '尺寸: ${(_scale * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Slider(
                  value: _scale,
                  min: 0.1,
                  max: 1.0,
                  divisions: 90,
                  label: '${(_scale * 100).toStringAsFixed(0)}%',
                  onChanged: (value) {
                    setState(() {
                      _scale = value;
                      _compressedSize = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

