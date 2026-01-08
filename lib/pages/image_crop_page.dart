import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

class ImageCropPage extends StatefulWidget {
  const ImageCropPage({super.key});

  @override
  State<ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<ImageCropPage> {
  File? _selectedImage;
  ui.Image? _uiImage;
  Rect _cropRect = Rect.zero;
  bool _isDragging = false;
  Offset? _dragStart;
  bool _isProcessing = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final file = File(image.path);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      
      setState(() {
        _selectedImage = file;
        _uiImage = frame.image;
        _cropRect = Rect.fromLTWH(
          frame.image.width * 0.1,
          frame.image.height * 0.1,
          frame.image.width * 0.8,
          frame.image.height * 0.8,
        );
      });
    }
  }

  Future<void> _cropAndSave() async {
    if (_selectedImage == null || _uiImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        throw Exception('无法解码图片');
      }

      // 计算实际裁剪区域（考虑图片显示尺寸和实际尺寸的比例）
      final scaleX = originalImage.width / _uiImage!.width;
      final scaleY = originalImage.height / _uiImage!.height;

      final x = (_cropRect.left * scaleX).round();
      final y = (_cropRect.top * scaleY).round();
      final width = (_cropRect.width * scaleX).round();
      final height = (_cropRect.height * scaleY).round();

      final cropped = img.copyCrop(
        originalImage,
        x: x.clamp(0, originalImage.width),
        y: y.clamp(0, originalImage.height),
        width: width.clamp(1, originalImage.width - x),
        height: height.clamp(1, originalImage.height - y),
      );

      final processedBytes = img.encodePng(cropped);

      if (await Permission.photos.isDenied) {
        await Permission.photos.request();
      }

      if (await Permission.photos.isGranted) {
        await ImageGallerySaver.saveImage(
          processedBytes,
          quality: 100,
          name: 'cropped_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('裁剪完成并已保存'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('裁剪失败: $e')),
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

  void _updateCropRect(Offset localPosition) {
    if (_uiImage == null) return;

    final imageWidth = _uiImage!.width.toDouble();
    final imageHeight = _uiImage!.height.toDouble();
    
    // 计算图片在屏幕上的实际显示区域
    final screenSize = MediaQuery.of(context).size;
    final imageAspect = imageWidth / imageHeight;
    final screenAspect = screenSize.width / screenSize.height;
    
    double displayWidth, displayHeight;
    if (imageAspect > screenAspect) {
      displayWidth = screenSize.width;
      displayHeight = screenSize.width / imageAspect;
    } else {
      displayHeight = screenSize.height - 200; // 减去底部工具栏高度
      displayWidth = displayHeight * imageAspect;
    }

    final offsetX = (screenSize.width - displayWidth) / 2;
    final offsetY = (screenSize.height - displayHeight - 200) / 2;

    // 转换屏幕坐标到图片坐标
    final imageX = ((localPosition.dx - offsetX) / displayWidth * imageWidth).clamp(0.0, imageWidth);
    final imageY = ((localPosition.dy - offsetY) / displayHeight * imageHeight).clamp(0.0, imageHeight);

    if (_isDragging) {
      if (_dragStart != null) {
        final startX = ((_dragStart!.dx - offsetX) / displayWidth * imageWidth).clamp(0.0, imageWidth);
        final startY = ((_dragStart!.dy - offsetY) / displayHeight * imageHeight).clamp(0.0, imageHeight);
        
        setState(() {
          _cropRect = Rect.fromPoints(
            Offset(startX, startY),
            Offset(imageX, imageY),
          );
        });
      }
    } else {
      setState(() {
        _dragStart = localPosition;
        _isDragging = true;
        _cropRect = Rect.fromLTWH(
          imageX - 50,
          imageY - 50,
          100,
          100,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图片裁剪'),
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _uiImage = null;
                  _cropRect = Rect.zero;
                });
              },
            ),
        ],
      ),
      body: _selectedImage == null
          ? _buildEmptyState()
          : _buildCropView(),
      floatingActionButton: _selectedImage != null
          ? FloatingActionButton.extended(
              onPressed: _isProcessing ? null : _cropAndSave,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(_isProcessing ? '处理中...' : '完成'),
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
            Icons.crop,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            '选择一张图片开始裁剪',
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

  Widget _buildCropView() {
    if (_uiImage == null) return const SizedBox();

    return Stack(
      children: [
        Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 3.0,
            child: CustomPaint(
              size: Size(_uiImage!.width.toDouble(), _uiImage!.height.toDouble()),
              painter: _ImageCropPainter(
                image: _uiImage!,
                cropRect: _cropRect,
              ),
            ),
          ),
        ),
        GestureDetector(
          onPanStart: (details) {
            _updateCropRect(details.localPosition);
          },
          onPanUpdate: (details) {
            _updateCropRect(details.localPosition);
          },
          onPanEnd: (details) {
            setState(() {
              _isDragging = false;
              _dragStart = null;
            });
          },
          child: Container(color: Colors.transparent),
        ),
        // 底部工具栏
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _cropRect = Rect.fromLTWH(
                          _uiImage!.width * 0.1,
                          _uiImage!.height * 0.1,
                          _uiImage!.width * 0.8,
                          _uiImage!.height * 0.8,
                        );
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('重置'),
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

class _ImageCropPainter extends CustomPainter {
  _ImageCropPainter({
    required this.image,
    required this.cropRect,
  });

  final ui.Image image;
  final Rect cropRect;

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制图片
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );

    // 绘制遮罩
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cropPath = Path()
      ..addRect(Rect.fromLTWH(
        cropRect.left / image.width * size.width,
        cropRect.top / image.height * size.height,
        cropRect.width / image.width * size.width,
        cropRect.height / image.height * size.height,
      ));
    final maskPath = Path.combine(
      PathOperation.difference,
      path,
      cropPath,
    );

    canvas.drawPath(
      maskPath,
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    // 绘制裁剪框
    final cropPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(
      Rect.fromLTWH(
        cropRect.left / image.width * size.width,
        cropRect.top / image.height * size.height,
        cropRect.width / image.width * size.width,
        cropRect.height / image.height * size.height,
      ),
      cropPaint,
    );

    // 绘制角落控制点
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final corners = [
      Offset(cropRect.left / image.width * size.width, cropRect.top / image.height * size.height),
      Offset(cropRect.right / image.width * size.width, cropRect.top / image.height * size.height),
      Offset(cropRect.right / image.width * size.width, cropRect.bottom / image.height * size.height),
      Offset(cropRect.left / image.width * size.width, cropRect.bottom / image.height * size.height),
    ];

    for (final corner in corners) {
      canvas.drawCircle(corner, 8, cornerPaint);
      canvas.drawCircle(corner, 8, Paint()..color = Colors.blue..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(_ImageCropPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.cropRect != cropRect;
  }
}
