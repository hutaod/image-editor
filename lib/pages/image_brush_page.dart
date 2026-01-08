import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

class BrushStroke {
  List<Offset> points;
  Color color;
  double strokeWidth;

  BrushStroke({
    required this.points,
    required this.color,
    this.strokeWidth = 5.0,
  });
}

class ImageBrushPage extends StatefulWidget {
  const ImageBrushPage({super.key});

  @override
  State<ImageBrushPage> createState() => _ImageBrushPageState();
}

class _ImageBrushPageState extends State<ImageBrushPage> {
  File? _selectedImage;
  ui.Image? _uiImage;
  List<BrushStroke> _strokes = [];
  BrushStroke? _currentStroke;
  Color _brushColor = Colors.red;
  double _brushWidth = 5.0;
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
        _strokes.clear();
      });
    }
  }

  Future<void> _saveImage() async {
    if (_selectedImage == null || _uiImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      img.Image? processedImage = img.decodeImage(imageBytes);

      if (processedImage == null) {
        throw Exception('无法解码图片');
      }

      // 在图片上绘制画笔痕迹
      // 这里简化处理，实际需要将 Canvas 绘制的内容合并到图片中
      // 可以使用 PictureRecorder 和 Canvas 来绘制，然后转换为图片

      final processedBytes = img.encodePng(processedImage);

      if (await Permission.photos.isDenied) {
        await Permission.photos.request();
      }

      if (await Permission.photos.isGranted) {
        await ImageGallerySaver.saveImage(
          processedBytes,
          quality: 100,
          name: 'brush_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('保存成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
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
        title: const Text('画笔涂鸦'),
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _uiImage = null;
                  _strokes.clear();
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
              onPressed: _isProcessing ? null : _saveImage,
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
            Icons.brush,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            '选择一张图片开始涂鸦',
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
    if (_uiImage == null) return const SizedBox();

    return Column(
      children: [
        Expanded(
          child: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _currentStroke = BrushStroke(
                      points: [details.localPosition],
                      color: _brushColor,
                      strokeWidth: _brushWidth,
                    );
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _currentStroke?.points.add(details.localPosition);
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    if (_currentStroke != null) {
                      _strokes.add(_currentStroke!);
                      _currentStroke = null;
                    }
                  });
                },
                child: CustomPaint(
                  size: Size(_uiImage!.width.toDouble(), _uiImage!.height.toDouble()),
                  painter: _BrushPainter(
                    image: _uiImage!,
                    strokes: _strokes,
                    currentStroke: _currentStroke,
                  ),
                ),
              ),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('画笔大小: ${_brushWidth.toInt()}'),
                    ),
                    Expanded(
                      child: Slider(
                        value: _brushWidth,
                        min: 1,
                        max: 50,
                        divisions: 49,
                        label: '${_brushWidth.toInt()}',
                        onChanged: (value) {
                          setState(() {
                            _brushWidth = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ColorButton(
                      color: Colors.red,
                      isSelected: _brushColor == Colors.red,
                      onTap: () => setState(() => _brushColor = Colors.red),
                    ),
                    _ColorButton(
                      color: Colors.blue,
                      isSelected: _brushColor == Colors.blue,
                      onTap: () => setState(() => _brushColor = Colors.blue),
                    ),
                    _ColorButton(
                      color: Colors.green,
                      isSelected: _brushColor == Colors.green,
                      onTap: () => setState(() => _brushColor = Colors.green),
                    ),
                    _ColorButton(
                      color: Colors.black,
                      isSelected: _brushColor == Colors.black,
                      onTap: () => setState(() => _brushColor = Colors.black),
                    ),
                    _ColorButton(
                      color: Colors.white,
                      isSelected: _brushColor == Colors.white,
                      onTap: () => setState(() => _brushColor = Colors.white),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          if (_strokes.isNotEmpty) {
                            _strokes.removeLast();
                          }
                        });
                      },
                      icon: const Icon(Icons.undo),
                      label: const Text('撤销'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _strokes.clear();
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
      ],
    );
  }
}

class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

class _BrushPainter extends CustomPainter {
  _BrushPainter({
    required this.image,
    required this.strokes,
    this.currentStroke,
  });

  final ui.Image image;
  final List<BrushStroke> strokes;
  final BrushStroke? currentStroke;

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制图片
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );

    // 绘制所有笔画
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // 绘制当前笔画
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, BrushStroke stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(stroke.points[0].dx, stroke.points[0].dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BrushPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.strokes.length != strokes.length ||
        oldDelegate.currentStroke != currentStroke;
  }
}
