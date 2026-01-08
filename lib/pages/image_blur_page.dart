import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

class ImageBlurPage extends StatefulWidget {
  const ImageBlurPage({super.key});

  @override
  State<ImageBlurPage> createState() => _ImageBlurPageState();
}

class _ImageBlurPageState extends State<ImageBlurPage> {
  File? _selectedImage;
  List<Rect> _blurRects = [];
  double _blurRadius = 10.0;
  bool _isProcessing = false;
  bool _isGlobalBlur = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _blurRects.clear();
      });
    }
  }

  Future<void> _applyBlurAndSave() async {
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

      if (_isGlobalBlur) {
        // 全局模糊
        processedImage = img.gaussianBlur(processedImage, radius: _blurRadius.round());
      } else {
        // 局部模糊
        for (final rect in _blurRects) {
          final x = rect.left.round();
          final y = rect.top.round();
          final width = rect.width.round();
          final height = rect.height.round();

          // 裁剪区域
          final cropped = img.copyCrop(
            processedImage,
            x: x.clamp(0, processedImage.width),
            y: y.clamp(0, processedImage.height),
            width: width.clamp(1, processedImage.width - x),
            height: height.clamp(1, processedImage.height - y),
          );

          // 应用模糊
          final blurred = img.gaussianBlur(cropped, radius: _blurRadius.round());

          // 合并回去
          img.compositeImage(
            processedImage,
            blurred,
            dstX: x,
            dstY: y,
          );
        }
      }

      final processedBytes = img.encodePng(processedImage);

      if (await Permission.photos.isDenied) {
        await Permission.photos.request();
      }

      if (await Permission.photos.isGranted) {
        await ImageGallerySaver.saveImage(
          processedBytes,
          quality: 100,
          name: 'blurred_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('模糊处理完成并已保存'),
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
        title: const Text('图片模糊'),
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _blurRects.clear();
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
              onPressed: _isProcessing ? null : _applyBlurAndSave,
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
            Icons.blur_on,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            '选择一张图片开始模糊处理',
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
    return Stack(
      children: [
        Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 3.0,
            child: Stack(
              children: [
                Image.file(
                  _selectedImage!,
                  fit: BoxFit.contain,
                ),
                CustomPaint(
                  painter: _BlurPainter(
                    blurRects: _blurRects,
                  ),
                  child: GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _blurRects.add(
                          Rect.fromPoints(
                            details.localPosition,
                            details.localPosition,
                          ),
                        );
                      });
                    },
                    onPanUpdate: (details) {
                      if (_blurRects.isNotEmpty) {
                        setState(() {
                          final lastRect = _blurRects.last;
                          _blurRects[_blurRects.length - 1] =
                              Rect.fromPoints(
                            lastRect.topLeft,
                            details.localPosition,
                          );
                        });
                      }
                    },
                    onPanEnd: (details) {},
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('模糊强度: ${_blurRadius.toInt()}'),
                      ),
                      Expanded(
                        child: Slider(
                          value: _blurRadius,
                          min: 1,
                          max: 50,
                          divisions: 49,
                          label: '${_blurRadius.toInt()}',
                          onChanged: (value) {
                            setState(() {
                              _blurRadius = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isGlobalBlur = true;
                          });
                        },
                        icon: Icon(_isGlobalBlur ? Icons.check_circle : Icons.circle_outlined),
                        label: const Text('全局模糊'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isGlobalBlur = false;
                          });
                        },
                        icon: Icon(!_isGlobalBlur ? Icons.check_circle : Icons.circle_outlined),
                        label: const Text('局部模糊'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            if (_blurRects.isNotEmpty) {
                              _blurRects.removeLast();
                            }
                          });
                        },
                        icon: const Icon(Icons.undo),
                        label: const Text('撤销'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _blurRects.clear();
                          });
                        },
                        icon: const Icon(Icons.clear_all),
                        label: const Text('清除'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BlurPainter extends CustomPainter {
  _BlurPainter({required this.blurRects});

  final List<Rect> blurRects;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final rect in blurRects) {
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(_BlurPainter oldDelegate) {
    return oldDelegate.blurRects.length != blurRects.length;
  }
}
