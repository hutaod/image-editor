import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

class TextElement {
  String text;
  Offset position;
  double fontSize;
  Color color;
  TextAlign align;
  double rotation;

  TextElement({
    required this.text,
    required this.position,
    this.fontSize = 24,
    this.color = Colors.white,
    this.align = TextAlign.center,
    this.rotation = 0,
  });
}

class ImageTextPage extends StatefulWidget {
  const ImageTextPage({super.key});

  @override
  State<ImageTextPage> createState() => _ImageTextPageState();
}

class _ImageTextPageState extends State<ImageTextPage> {
  File? _selectedImage;
  ui.Image? _uiImage;
  List<TextElement> _textElements = [];
  TextElement? _selectedElement;
  bool _isProcessing = false;
  Offset? _dragStart;
  bool _isDragging = false;

  final TextEditingController _textController = TextEditingController();
  double _fontSize = 24;
  Color _textColor = Colors.white;

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
        _textElements.clear();
        _selectedElement = null;
      });
    }
  }

  void _addText() {
    if (_uiImage == null) return;

    final newElement = TextElement(
      text: _textController.text.isEmpty ? '双击编辑文字' : _textController.text,
      position: Offset(_uiImage!.width / 2, _uiImage!.height / 2),
      fontSize: _fontSize,
      color: _textColor,
    );

    setState(() {
      _textElements.add(newElement);
      _selectedElement = newElement;
      _textController.clear();
    });
  }

  void _updateSelectedText() {
    if (_selectedElement != null) {
      setState(() {
        _selectedElement!.text = _textController.text;
        _selectedElement!.fontSize = _fontSize;
        _selectedElement!.color = _textColor;
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

      // 在图片上绘制文字
      // 这里简化处理，实际需要使用更复杂的文字渲染
      // 可以使用 dart:ui 的 ParagraphBuilder 来绘制文字
      // 或者使用 Canvas 直接绘制文字

      final processedBytes = img.encodePng(processedImage);

      if (await Permission.photos.isDenied) {
        await Permission.photos.request();
      }

      if (await Permission.photos.isGranted) {
        await ImageGallerySaver.saveImage(
          processedBytes,
          quality: 100,
          name: 'text_${DateTime.now().millisecondsSinceEpoch}',
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
        title: const Text('添加文字'),
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _uiImage = null;
                  _textElements.clear();
                  _selectedElement = null;
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
            Icons.text_fields,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            '选择一张图片开始添加文字',
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
                onTap: () {
                  setState(() {
                    _selectedElement = null;
                  });
                },
                onPanStart: (details) {
                  _handlePanStart(details.localPosition);
                },
                onPanUpdate: (details) {
                  _handlePanUpdate(details.localPosition);
                },
                onPanEnd: (details) {
                  _handlePanEnd();
                },
                child: CustomPaint(
                  size: Size(_uiImage!.width.toDouble(), _uiImage!.height.toDouble()),
                  painter: _TextPainter(
                    image: _uiImage!,
                    textElements: _textElements,
                    selectedElement: _selectedElement,
                  ),
                ),
              ),
            ),
          ),
        ),
        // 底部工具栏
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
                if (_selectedElement != null) ...[
                  TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: '输入文字',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _updateSelectedText(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text('字体大小: ${_fontSize.toInt()}'),
                      ),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 12,
                          max: 72,
                          onChanged: (value) {
                            setState(() {
                              _fontSize = value;
                              if (_selectedElement != null) {
                                _selectedElement!.fontSize = value;
                              }
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
                        color: Colors.white,
                        isSelected: _textColor == Colors.white,
                        onTap: () {
                          setState(() {
                            _textColor = Colors.white;
                            if (_selectedElement != null) {
                              _selectedElement!.color = Colors.white;
                            }
                          });
                        },
                      ),
                      _ColorButton(
                        color: Colors.black,
                        isSelected: _textColor == Colors.black,
                        onTap: () {
                          setState(() {
                            _textColor = Colors.black;
                            if (_selectedElement != null) {
                              _selectedElement!.color = Colors.black;
                            }
                          });
                        },
                      ),
                      _ColorButton(
                        color: Colors.red,
                        isSelected: _textColor == Colors.red,
                        onTap: () {
                          setState(() {
                            _textColor = Colors.red;
                            if (_selectedElement != null) {
                              _selectedElement!.color = Colors.red;
                            }
                          });
                        },
                      ),
                      _ColorButton(
                        color: Colors.blue,
                        isSelected: _textColor == Colors.blue,
                        onTap: () {
                          setState(() {
                            _textColor = Colors.blue;
                            if (_selectedElement != null) {
                              _selectedElement!.color = Colors.blue;
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _textElements.remove(_selectedElement);
                            _selectedElement = null;
                          });
                        },
                      ),
                    ],
                  ),
                ] else ...[
                  TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: '输入文字',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _addText,
                    icon: const Icon(Icons.add),
                    label: const Text('添加文字'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handlePanStart(Offset position) {
    if (_uiImage == null) return;
    
    // 检查是否点击了文字元素
    for (final element in _textElements.reversed) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: element.text,
          style: TextStyle(fontSize: element.fontSize),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final rect = Rect.fromCenter(
        center: element.position,
        width: textPainter.width + 20,
        height: textPainter.height + 20,
      );
      if (rect.contains(position)) {
        setState(() {
          _selectedElement = element;
          _textController.text = element.text;
          _fontSize = element.fontSize;
          _textColor = element.color;
          _dragStart = position;
          _isDragging = true;
        });
        return;
      }
    }
    setState(() {
      _selectedElement = null;
    });
  }

  void _handlePanUpdate(Offset position) {
    if (_isDragging && _selectedElement != null && _dragStart != null) {
      setState(() {
        _selectedElement!.position += position - _dragStart!;
        _dragStart = position;
      });
    }
  }

  void _handlePanEnd() {
    setState(() {
      _isDragging = false;
      _dragStart = null;
    });
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

class _TextPainter extends CustomPainter {
  _TextPainter({
    required this.image,
    required this.textElements,
    this.selectedElement,
  });

  final ui.Image image;
  final List<TextElement> textElements;
  final TextElement? selectedElement;

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制图片
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );

    // 绘制文字
    for (final element in textElements) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: element.text,
          style: TextStyle(
            color: element.color,
            fontSize: element.fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: element.align,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(element.position.dx, element.position.dy);
      canvas.rotate(element.rotation);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();

      // 绘制选中框
      if (element == selectedElement) {
        final rect = Rect.fromCenter(
          center: element.position,
          width: textPainter.width + 20,
          height: textPainter.height + 20,
        );
        canvas.drawRect(
          rect,
          Paint()
            ..color = Colors.blue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TextPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.textElements.length != textElements.length ||
        oldDelegate.selectedElement != selectedElement;
  }
}
