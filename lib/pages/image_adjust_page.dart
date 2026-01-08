import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

class ImageAdjustPage extends StatefulWidget {
  const ImageAdjustPage({super.key, this.isRotate = false});

  final bool isRotate;

  @override
  State<ImageAdjustPage> createState() => _ImageAdjustPageState();
}

class _ImageAdjustPageState extends State<ImageAdjustPage> {
  File? _selectedImage;
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  int _rotation = 0;
  bool _flipHorizontal = false;
  bool _flipVertical = false;
  bool _isProcessing = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _brightness = 0.0;
        _contrast = 1.0;
        _saturation = 1.0;
        _rotation = 0;
        _flipHorizontal = false;
        _flipVertical = false;
      });
    }
  }

  Future<void> _applyAndSave() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      img.Image? processedImage = img.decodeImage(imageBytes);

      if (processedImage == null) {
        throw Exception('无法解码图片');
      }

      // 旋转
      if (_rotation != 0) {
        processedImage = img.copyRotate(processedImage, angle: _rotation);
      }

      // 翻转
      if (_flipHorizontal) {
        processedImage = img.flipHorizontal(processedImage);
      }
      if (_flipVertical) {
        processedImage = img.flipVertical(processedImage);
      }

      // 调整亮度、对比度、饱和度
      if (_brightness != 0.0 || _contrast != 1.0 || _saturation != 1.0) {
        processedImage = img.adjustColor(
          processedImage,
          brightness: _brightness,
          contrast: _contrast,
          saturation: _saturation,
        );
      }

      final processedBytes = img.encodePng(processedImage);

      if (await Permission.photos.isDenied) {
        await Permission.photos.request();
      }

      if (await Permission.photos.isGranted) {
        await ImageGallerySaver.saveImage(
          processedBytes,
          quality: 100,
          name: 'adjusted_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('处理完成并已保存'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('处理失败: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRotate ? '旋转翻转' : '色彩调整'),
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                });
              },
            ),
        ],
      ),
      body: _selectedImage == null
          ? _buildEmptyState()
          : _buildEditorView(),
      floatingActionButton: _selectedImage != null
          ? FloatingActionButton.extended(
              onPressed: _isProcessing ? null : _applyAndSave,
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
              label: Text(_isProcessing ? '处理中...' : '保存'),
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
            widget.isRotate ? Icons.rotate_right : Icons.brightness_6,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            '选择一张图片开始${widget.isRotate ? '旋转' : '调整'}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_library),
            label: const Text('选择图片'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorView() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Image.file(
              _selectedImage!,
              fit: BoxFit.contain,
            ),
          ),
        ),
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isRotate) ...[
                    Text('旋转角度: ${_rotation}°', style: Theme.of(context).textTheme.titleSmall),
                    Slider(
                      value: _rotation.toDouble(),
                      min: -180,
                      max: 180,
                      divisions: 360,
                      label: '${_rotation}°',
                      onChanged: (value) {
                        setState(() {
                          _rotation = value.round();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _flipHorizontal = !_flipHorizontal;
                            });
                          },
                          icon: Icon(_flipHorizontal ? Icons.flip : Icons.flip_outlined),
                          label: const Text('水平翻转'),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _flipVertical = !_flipVertical;
                            });
                          },
                          icon: Icon(_flipVertical ? Icons.flip : Icons.flip_outlined),
                          label: const Text('垂直翻转'),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text('亮度: ${_brightness.toStringAsFixed(1)}', style: Theme.of(context).textTheme.titleSmall),
                    Slider(
                      value: _brightness,
                      min: -1.0,
                      max: 1.0,
                      divisions: 200,
                      label: _brightness.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          _brightness = value;
                        });
                      },
                    ),
                    Text('对比度: ${_contrast.toStringAsFixed(1)}', style: Theme.of(context).textTheme.titleSmall),
                    Slider(
                      value: _contrast,
                      min: 0.0,
                      max: 2.0,
                      divisions: 200,
                      label: _contrast.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          _contrast = value;
                        });
                      },
                    ),
                    Text('饱和度: ${_saturation.toStringAsFixed(1)}', style: Theme.of(context).textTheme.titleSmall),
                    Slider(
                      value: _saturation,
                      min: 0.0,
                      max: 2.0,
                      divisions: 200,
                      label: _saturation.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          _saturation = value;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

