import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

class ImageMosaicPage extends StatefulWidget {
  const ImageMosaicPage({super.key});

  @override
  State<ImageMosaicPage> createState() => _ImageMosaicPageState();
}

class _ImageMosaicPageState extends State<ImageMosaicPage> {
  File? _selectedImage;
  List<Rect> _mosaicRects = [];
  int _mosaicSize = 10;
  bool _isProcessing = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _mosaicRects.clear();
      });
    }
  }

  Future<void> _applyMosaicAndSave() async {
    if (_selectedImage == null || _mosaicRects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择图片并标记马赛克区域')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      img.Image? processedImage = img.decodeImage(imageBytes);

      if (processedImage == null) {
        throw Exception('无法解码图片');
      }

      // 处理每个马赛克区域
      for (final rect in _mosaicRects) {
        final x = rect.left.round();
        final y = rect.top.round();
        final width = rect.width.round();
        final height = rect.height.round();

        // 应用马赛克效果
        _applyMosaic(
          processedImage,
          x.clamp(0, processedImage.width),
          y.clamp(0, processedImage.height),
          width.clamp(1, processedImage.width - x),
          height.clamp(1, processedImage.height - y),
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
          name: 'mosaic_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('马赛克处理完成并已保存'),
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

  void _applyMosaic(img.Image image, int x, int y, int width, int height) {
    // 马赛克算法：将区域分成小块，每块使用平均值填充
    for (int py = y; py < y + height && py < image.height; py += _mosaicSize) {
      for (int px = x; px < x + width && px < image.width; px += _mosaicSize) {
        // 计算当前块的平均颜色
        int r = 0, g = 0, b = 0, count = 0;

        for (int dy = 0; dy < _mosaicSize && py + dy < image.height && py + dy < y + height; dy++) {
          for (int dx = 0; dx < _mosaicSize && px + dx < image.width && px + dx < x + width; dx++) {
            final pixel = image.getPixel(px + dx, py + dy);
            r += pixel.r.round();
            g += pixel.g.round();
            b += pixel.b.round();
            count++;
          }
        }

        if (count > 0) {
          final avgColor = img.ColorRgb8(
            (r / count).round(),
            (g / count).round(),
            (b / count).round(),
          );

          // 用平均颜色填充整个块
          for (int dy = 0; dy < _mosaicSize && py + dy < image.height && py + dy < y + height; dy++) {
            for (int dx = 0; dx < _mosaicSize && px + dx < image.width && px + dx < x + width; dx++) {
              image.setPixel(px + dx, py + dy, avgColor);
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('马赛克'),
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _mosaicRects.clear();
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
              onPressed: _isProcessing ? null : _applyMosaicAndSave,
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
            Icons.grid_4x4,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            '选择一张图片开始马赛克处理',
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
                  painter: _MosaicPainter(
                    mosaicRects: _mosaicRects,
                  ),
                  child: GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _mosaicRects.add(
                          Rect.fromPoints(
                            details.localPosition,
                            details.localPosition,
                          ),
                        );
                      });
                    },
                    onPanUpdate: (details) {
                      if (_mosaicRects.isNotEmpty) {
                        setState(() {
                          final lastRect = _mosaicRects.last;
                          _mosaicRects[_mosaicRects.length - 1] =
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
                        child: Text('马赛克大小: $_mosaicSize'),
                      ),
                      Expanded(
                        child: Slider(
                          value: _mosaicSize.toDouble(),
                          min: 5,
                          max: 30,
                          divisions: 25,
                          label: '$_mosaicSize',
                          onChanged: (value) {
                            setState(() {
                              _mosaicSize = value.round();
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
                            if (_mosaicRects.isNotEmpty) {
                              _mosaicRects.removeLast();
                            }
                          });
                        },
                        icon: const Icon(Icons.undo),
                        label: const Text('撤销'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _mosaicRects.clear();
                          });
                        },
                        icon: const Icon(Icons.clear_all),
                        label: const Text('清除全部'),
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

class _MosaicPainter extends CustomPainter {
  _MosaicPainter({required this.mosaicRects});

  final List<Rect> mosaicRects;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final rect in mosaicRects) {
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(_MosaicPainter oldDelegate) {
    return oldDelegate.mosaicRects.length != mosaicRects.length;
  }
}
