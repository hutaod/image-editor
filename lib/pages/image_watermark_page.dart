import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class WatermarkElement {
  String text;
  Offset position;
  double fontSize;
  Color color;
  double rotation;
  double opacity;
  bool isSelected;

  WatermarkElement({
    required this.text,
    required this.position,
    this.fontSize = 48, // 默认48sp，参考图片中的大字号
    this.color = Colors.white,
    this.rotation = 0,
    this.opacity = 0.8,
    this.isSelected = false,
  });
}

class ImageWatermarkPage extends StatefulWidget {
  const ImageWatermarkPage({super.key});

  @override
  State<ImageWatermarkPage> createState() => _ImageWatermarkPageState();
}

enum DragMode { none, move, scale, rotate }

enum ControlPoint { none, delete, edit, scaleRotate, copy }

class _ImageWatermarkPageState extends State<ImageWatermarkPage> {
  File? _selectedImage;
  ui.Image? _uiImage;
  List<WatermarkElement> _watermarks = [];
  WatermarkElement? _selectedWatermark;
  bool _isProcessing = false;
  Offset? _dragStart;
  DragMode _dragMode = DragMode.none;
  ControlPoint _activeControlPoint = ControlPoint.none;
  double _initialFontSize = 0;
  double _initialRotation = 0;
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;
  bool _isLongPressing = false;

  // 撤销/重做系统
  List<List<WatermarkElement>> _history = [];
  int _historyIndex = -1;
  static const int _maxHistorySize = 50;

  final TextEditingController _textController = TextEditingController();
  double _fontSize = 48; // 默认48sp，参考图片中的大字号
  Color _textColor = Colors.white;
  double _opacity = 0.8;

  // 预设水印模板
  final List<String> _presetTemplates = [
    '禁止盗用',
    'REPEINT FORBIDDEN',
    '禁止转载',
    'Copyright',
    'Sample Only',
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

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
        _watermarks.clear();
        _selectedWatermark = null;
        _history.clear();
        _historyIndex = -1;
      });
      // 保存初始空状态
      _saveState();
    }
  }

  void _saveState() {
    // 保存当前状态到历史记录
    final currentState = _watermarks
        .map(
          (w) => WatermarkElement(
            text: w.text,
            position: w.position,
            fontSize: w.fontSize,
            color: w.color,
            rotation: w.rotation,
            opacity: w.opacity,
          ),
        )
        .toList();

    // 移除当前位置之后的历史记录（如果有重做操作）
    if (_historyIndex < _history.length - 1) {
      _history = _history.sublist(0, _historyIndex + 1);
    }

    // 添加新状态
    _history.add(currentState);
    _historyIndex++;

    // 限制历史记录大小
    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  void _undo() {
    if (_historyIndex > 0) {
      setState(() {
        _historyIndex--;
        _watermarks = _history[_historyIndex]
            .map(
              (w) => WatermarkElement(
                text: w.text,
                position: w.position,
                fontSize: w.fontSize,
                color: w.color,
                rotation: w.rotation,
                opacity: w.opacity,
              ),
            )
            .toList();
        _selectedWatermark = null;
      });
    }
  }

  void _redo() {
    if (_historyIndex < _history.length - 1) {
      setState(() {
        _historyIndex++;
        _watermarks = _history[_historyIndex]
            .map(
              (w) => WatermarkElement(
                text: w.text,
                position: w.position,
                fontSize: w.fontSize,
                color: w.color,
                rotation: w.rotation,
                opacity: w.opacity,
              ),
            )
            .toList();
        _selectedWatermark = null;
      });
    }
  }

  void _addWatermark(String? text) {
    if (_uiImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先选择图片')));
      return;
    }

    final watermarkText =
        text ?? (_textController.text.isEmpty ? '禁止盗用' : _textController.text);

    // 使用逻辑像素，直接存储逻辑像素值
    final newWatermark = WatermarkElement(
      text: watermarkText,
      position: Offset(_uiImage!.width / 2, _uiImage!.height / 2),
      fontSize: _fontSize, // 存储为逻辑像素
      color: _textColor,
      opacity: _opacity,
    );

    setState(() {
      _watermarks.add(newWatermark);
      _selectedWatermark = newWatermark;
      if (text == null) {
        _textController.clear();
      }
    });

    _saveState();
  }

  void _updateSelectedWatermark() {
    if (_selectedWatermark != null) {
      setState(() {
        _selectedWatermark!.text = _textController.text;
        _selectedWatermark!.fontSize = _fontSize;
        _selectedWatermark!.color = _textColor;
        _selectedWatermark!.opacity = _opacity;
      });
    }
  }

  Future<void> _saveImage() async {
    if (_selectedImage == null || _uiImage == null || _watermarks.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先添加水印')));
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // 使用 PictureRecorder 和 Canvas 来绘制图片和水印
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(
        _uiImage!.width.toDouble(),
        _uiImage!.height.toDouble(),
      );

      // 绘制原始图片
      canvas.drawImageRect(
        _uiImage!,
        Rect.fromLTWH(
          0,
          0,
          _uiImage!.width.toDouble(),
          _uiImage!.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint(),
      );

      // 绘制所有水印
      for (final watermark in _watermarks) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: watermark.text,
            style: TextStyle(
              color: watermark.color.withValues(alpha: watermark.opacity),
              fontSize: watermark.fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        canvas.save();
        canvas.translate(watermark.position.dx, watermark.position.dy);
        canvas.rotate(watermark.rotation);
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
        canvas.restore();
      }

      // 转换为图片
      final picture = recorder.endRecording();
      final image = await picture.toImage(_uiImage!.width, _uiImage!.height);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final processedBytes = byteData!.buffer.asUint8List();

      if (await Permission.photos.isDenied) {
        await Permission.photos.request();
      }

      if (await Permission.photos.isGranted) {
        await ImageGallerySaver.saveImage(
          processedBytes,
          quality: 100,
          name: 'watermark_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('保存成功'),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
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
        title: const Text('添加水印'),
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.download),
              onPressed: _isProcessing ? null : _saveImage,
            ),
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _uiImage = null;
                  _watermarks.clear();
                  _selectedWatermark = null;
                });
              },
            ),
        ],
      ),
      body: _selectedImage == null ? _buildEmptyState() : _buildEditorView(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.water_drop,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text('选择一张图片开始添加水印', style: Theme.of(context).textTheme.titleLarge),
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
    if (_uiImage == null || _selectedImage == null) return const SizedBox();

    return Column(
      children: [
        Expanded(
          child: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              panEnabled: false, // 禁用平移，避免与手势冲突
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 计算图片的显示尺寸（保持宽高比）
                  final imageAspect = _uiImage!.width / _uiImage!.height;
                  double displayWidth, displayHeight;

                  if (imageAspect >
                      constraints.maxWidth / constraints.maxHeight) {
                    displayWidth = constraints.maxWidth;
                    displayHeight = constraints.maxWidth / imageAspect;
                  } else {
                    displayHeight = constraints.maxHeight;
                    displayWidth = constraints.maxHeight * imageAspect;
                  }

                  // 计算偏移（居中显示）
                  final offsetX = (constraints.maxWidth - displayWidth) / 2;
                  final offsetY = (constraints.maxHeight - displayHeight) / 2;

                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapDown: (TapDownDetails details) {
                      // 将 localPosition 转换为相对于图片的坐标
                      final imageLocalPosition = Offset(
                        details.localPosition.dx - offsetX,
                        details.localPosition.dy - offsetY,
                      );
                      _handleTapDownInLayout(
                        imageLocalPosition,
                        displayWidth,
                        displayHeight,
                      );
                    },
                    onLongPressStart: (LongPressStartDetails details) {
                      final imageLocalPosition = Offset(
                        details.localPosition.dx - offsetX,
                        details.localPosition.dy - offsetY,
                      );
                      _handleLongPressStartInLayout(
                        imageLocalPosition,
                        displayWidth,
                        displayHeight,
                      );
                    },
                    onLongPressMoveUpdate:
                        (LongPressMoveUpdateDetails details) {
                          final imageLocalPosition = Offset(
                            details.localPosition.dx - offsetX,
                            details.localPosition.dy - offsetY,
                          );
                          _handleLongPressMoveInLayout(
                            imageLocalPosition,
                            displayWidth,
                            displayHeight,
                          );
                        },
                    onLongPressEnd: (LongPressEndDetails details) {
                      _handleLongPressEnd();
                    },
                    onScaleStart: (ScaleStartDetails details) {
                      final imageLocalPosition = Offset(
                        details.localFocalPoint.dx - offsetX,
                        details.localFocalPoint.dy - offsetY,
                      );
                      _handleScaleStartInLayout(
                        imageLocalPosition,
                        displayWidth,
                        displayHeight,
                      );
                    },
                    onScaleUpdate: (ScaleUpdateDetails details) {
                      final imageLocalPosition = Offset(
                        details.localFocalPoint.dx - offsetX,
                        details.localFocalPoint.dy - offsetY,
                      );
                      _handleScaleUpdateInLayout(
                        imageLocalPosition,
                        displayWidth,
                        displayHeight,
                        details.scale,
                        details.rotation,
                      );
                    },
                    onScaleEnd: (ScaleEndDetails details) {
                      _handleScaleEnd(details);
                    },
                    child: Stack(
                      children: [
                        // 显示图片
                        Positioned(
                          left: offsetX,
                          top: offsetY,
                          width: displayWidth,
                          height: displayHeight,
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.contain,
                          ),
                        ),
                        // 绘制水印
                        Positioned(
                          left: offsetX,
                          top: offsetY,
                          width: displayWidth,
                          height: displayHeight,
                          child: CustomPaint(
                            size: Size(displayWidth, displayHeight),
                            painter: _WatermarkPainter(
                              image: _uiImage!,
                              watermarks: _watermarks,
                              selectedWatermark: _selectedWatermark,
                              displaySize: Size(displayWidth, displayHeight),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // 底部工具栏 - 参考图片中的标签页设计
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
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
            child: DefaultTabController(
              length: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: '素材'),
                      Tab(text: '文案'),
                      Tab(text: '样式'),
                    ],
                  ),
                  SizedBox(
                    height: 200,
                    child: TabBarView(
                      children: [
                        _buildMaterialTab(),
                        _buildTextTab(),
                        _buildStyleTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('基础水印', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetTemplates.map((template) {
              return InkWell(
                onTap: () {
                  _addWatermark(template);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(template),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              hintText: '输入水印文字',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _updateSelectedWatermark(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    _addWatermark(null);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('添加水印'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: _historyIndex > 0 ? _undo : null,
                tooltip: '撤销',
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                onPressed: _historyIndex < _history.length - 1 ? _redo : null,
                tooltip: '重做',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStyleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text('字体大小: ${_fontSize.toInt()}sp')),
              Expanded(
                child: Slider(
                  value: _fontSize.clamp(10.0, 200.0),
                  min: 10,
                  max: 200, // 与代码中其他地方保持一致，支持最大 200
                  divisions: 95, // 增加细分，更精确控制
                  label: '${_fontSize.toInt()}sp',
                  onChanged: (value) {
                    setState(() {
                      _fontSize = value;
                      if (_selectedWatermark != null) {
                        _selectedWatermark!.fontSize = value;
                        _saveState();
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: Text('透明度: ${(_opacity * 100).toInt()}%')),
              Expanded(
                child: Slider(
                  value: _opacity,
                  min: 0.1,
                  max: 1.0,
                  onChanged: (value) {
                    setState(() {
                      _opacity = value;
                      if (_selectedWatermark != null) {
                        _selectedWatermark!.opacity = value;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _ColorButton(
                color: Colors.white,
                isSelected: _textColor == Colors.white,
                onTap: () {
                  setState(() {
                    _textColor = Colors.white;
                    if (_selectedWatermark != null) {
                      _selectedWatermark!.color = Colors.white;
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
                    if (_selectedWatermark != null) {
                      _selectedWatermark!.color = Colors.black;
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
                    if (_selectedWatermark != null) {
                      _selectedWatermark!.color = Colors.red;
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
                    if (_selectedWatermark != null) {
                      _selectedWatermark!.color = Colors.blue;
                    }
                  });
                },
              ),
              _ColorButton(
                color: Colors.green,
                isSelected: _textColor == Colors.green,
                onTap: () {
                  setState(() {
                    _textColor = Colors.green;
                    if (_selectedWatermark != null) {
                      _selectedWatermark!.color = Colors.green;
                    }
                  });
                },
              ),
              _ColorButton(
                color: Colors.yellow,
                isSelected: _textColor == Colors.yellow,
                onTap: () {
                  setState(() {
                    _textColor = Colors.yellow;
                    if (_selectedWatermark != null) {
                      _selectedWatermark!.color = Colors.yellow;
                    }
                  });
                },
              ),
              if (_selectedWatermark != null)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _watermarks.remove(_selectedWatermark);
                      _selectedWatermark = null;
                    });
                    _saveState();
                  },
                  tooltip: '删除水印',
                ),
            ],
          ),
          if (_selectedWatermark != null) ...[
            const SizedBox(height: 8),
            Text(
              '提示：拖拽移动 | 右下角缩放 | 顶部旋转 | 双击编辑',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Offset _getImagePosition(Offset screenPosition) {
    if (_uiImage == null) return Offset.zero;

    final imageAspect = _uiImage!.width / _uiImage!.height;
    final screenSize = MediaQuery.of(context).size;
    final availableHeight = screenSize.height - 200;
    final availableWidth = screenSize.width;

    double displayWidth, displayHeight;
    if (imageAspect > availableWidth / availableHeight) {
      displayWidth = availableWidth;
      displayHeight = availableWidth / imageAspect;
    } else {
      displayHeight = availableHeight;
      displayWidth = displayHeight * imageAspect;
    }

    final offsetX = (availableWidth - displayWidth) / 2;
    final offsetY = (availableHeight - displayHeight) / 2;

    final imageX =
        ((screenPosition.dx - offsetX) / displayWidth * _uiImage!.width).clamp(
          0.0,
          _uiImage!.width.toDouble(),
        );
    final imageY =
        ((screenPosition.dy - offsetY) / displayHeight * _uiImage!.height)
            .clamp(0.0, _uiImage!.height.toDouble());

    return Offset(imageX, imageY);
  }

  Rect _getWatermarkRect(
    WatermarkElement watermark,
    double scaleX,
    double scaleY,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: watermark.text,
        style: TextStyle(fontSize: watermark.fontSize * scaleX),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final displayX = watermark.position.dx * scaleX;
    final displayY = watermark.position.dy * scaleY;

    return Rect.fromCenter(
      center: Offset(displayX, displayY),
      width: textPainter.width + 40,
      height: textPainter.height + 40,
    );
  }

  void _handleTapDownInLayout(
    Offset imageLocalPosition,
    double displayWidth,
    double displayHeight,
  ) {
    if (_uiImage == null) return;

    // imageLocalPosition 是相对于图片显示区域的坐标
    // 转换为图片坐标
    final scaleX = displayWidth / _uiImage!.width;
    final scaleY = displayHeight / _uiImage!.height;

    // 转换为屏幕坐标（用于控制点检测）
    final screenSize = MediaQuery.of(context).size;
    final availableHeight = screenSize.height - 200;
    final availableWidth = screenSize.width;
    final offsetX = (availableWidth - displayWidth) / 2;
    final offsetY = (availableHeight - displayHeight) / 2;
    final screenPosition = Offset(
      imageLocalPosition.dx + offsetX,
      imageLocalPosition.dy + offsetY,
    );

    // 检查是否点击了控制点
    final controlPoint = _getControlPointAt(screenPosition);
    if (controlPoint != ControlPoint.none && _selectedWatermark != null) {
      if (controlPoint == ControlPoint.scaleRotate) {
        // 右下角控制点，使用 scale 手势处理
        _activeControlPoint = ControlPoint.scaleRotate;
        final imagePosition = Offset(
          imageLocalPosition.dx / scaleX,
          imageLocalPosition.dy / scaleY,
        );
        setState(() {
          _initialFontSize = _selectedWatermark!.fontSize;
          _initialRotation = _selectedWatermark!.rotation;
          _dragStart = imagePosition;
        });
      } else {
        // 其他控制点，直接处理
        _handleControlPointTap(controlPoint);
      }
      return;
    }

    // 检查是否点击了水印（使用图片坐标）
    final watermark = _getWatermarkAtInLayout(
      imageLocalPosition,
      displayWidth,
      displayHeight,
    );
    if (watermark != null) {
      final isSameWatermark = _selectedWatermark == watermark;
      final now = DateTime.now();
      final isQuickTap =
          _lastTapTime != null &&
          now.difference(_lastTapTime!) < const Duration(milliseconds: 300);
      final isSamePosition =
          _lastTapPosition != null &&
          (imageLocalPosition - _lastTapPosition!).distance < 20;

      if (isSameWatermark && isQuickTap && isSamePosition) {
        // 第二次快速点击，编辑文字
        _editWatermarkText();
        _lastTapTime = null;
        _lastTapPosition = null;
      } else {
        // 第一次点击，选中水印
        setState(() {
          _selectedWatermark = watermark;
          _textController.text = watermark.text;
          _fontSize = watermark.fontSize;
          _textColor = watermark.color;
          _opacity = watermark.opacity;
          _lastTapTime = now;
          _lastTapPosition = imageLocalPosition;
        });
      }
    } else {
      // 点击了空白区域，取消选中
      setState(() {
        _selectedWatermark = null;
        _lastTapTime = null;
        _lastTapPosition = null;
      });
    }
  }

  void _handleLongPressStartInLayout(
    Offset imageLocalPosition,
    double displayWidth,
    double displayHeight,
  ) {
    if (_selectedWatermark == null) return;

    // 转换为屏幕坐标用于控制点检测
    final screenSize = MediaQuery.of(context).size;
    final availableHeight = screenSize.height - 200;
    final availableWidth = screenSize.width;
    final offsetX = (availableWidth - displayWidth) / 2;
    final offsetY = (availableHeight - displayHeight) / 2;
    final screenPosition = Offset(
      imageLocalPosition.dx + offsetX,
      imageLocalPosition.dy + offsetY,
    );

    // 检查是否在控制点区域，如果是则不处理长按
    final controlPoint = _getControlPointAt(screenPosition);
    if (controlPoint != ControlPoint.none) {
      return;
    }

    final scaleX = displayWidth / _uiImage!.width;
    final scaleY = displayHeight / _uiImage!.height;
    final imagePosition = Offset(
      imageLocalPosition.dx / scaleX,
      imageLocalPosition.dy / scaleY,
    );
    setState(() {
      _dragMode = DragMode.move;
      _dragStart = imagePosition;
      _isLongPressing = true;
    });
  }

  void _handleLongPressMoveInLayout(
    Offset imageLocalPosition,
    double displayWidth,
    double displayHeight,
  ) {
    if (_selectedWatermark == null ||
        _dragStart == null ||
        _dragMode != DragMode.move) {
      return;
    }

    final scaleX = displayWidth / _uiImage!.width;
    final scaleY = displayHeight / _uiImage!.height;
    final imagePosition = Offset(
      imageLocalPosition.dx / scaleX,
      imageLocalPosition.dy / scaleY,
    );
    setState(() {
      _selectedWatermark!.position += imagePosition - _dragStart!;
      _dragStart = imagePosition;
    });
  }

  void _handleLongPressEnd() {
    if (_dragMode == DragMode.move) {
      _saveState();
    }
    setState(() {
      _dragMode = DragMode.none;
      _dragStart = null;
      _isLongPressing = false;
    });
  }

  WatermarkElement? _getWatermarkAtInLayout(
    Offset imageLocalPosition,
    double displayWidth,
    double displayHeight,
  ) {
    if (_uiImage == null) return null;

    final scaleX = displayWidth / _uiImage!.width;
    final scaleY = displayHeight / _uiImage!.height;

    // 检查是否点击了水印（从后往前检查）
    for (final watermark in _watermarks.reversed) {
      // 水印在图片坐标系中的位置转换为显示坐标
      final displayX = watermark.position.dx * scaleX;
      final displayY = watermark.position.dy * scaleY;

      final textPainter = TextPainter(
        text: TextSpan(
          text: watermark.text,
          style: TextStyle(fontSize: watermark.fontSize * scaleX),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final minSize = 100.0;
      final clickWidth = (textPainter.width + 80).clamp(
        minSize,
        double.infinity,
      );
      final clickHeight = (textPainter.height + 80).clamp(
        minSize,
        double.infinity,
      );

      final clickRect = Rect.fromCenter(
        center: Offset(displayX, displayY),
        width: clickWidth,
        height: clickHeight,
      );

      if (clickRect.contains(imageLocalPosition)) {
        return watermark;
      }
    }

    return null;
  }

  void _editWatermarkText() {
    if (_selectedWatermark == null) return;

    _textController.text = _selectedWatermark!.text;
    _textController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _selectedWatermark!.text.length,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑水印文字'),
        content: TextField(
          controller: _textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入水印文字',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            if (value.isNotEmpty && _selectedWatermark != null) {
              setState(() {
                _selectedWatermark!.text = value;
              });
              _saveState();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (_textController.text.isNotEmpty &&
                  _selectedWatermark != null) {
                setState(() {
                  _selectedWatermark!.text = _textController.text;
                });
                _saveState();
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  ControlPoint _getControlPointAt(Offset screenPosition) {
    if (_selectedWatermark == null || _uiImage == null)
      return ControlPoint.none;

    final imageAspect = _uiImage!.width / _uiImage!.height;
    final screenSize = MediaQuery.of(context).size;
    final availableHeight = screenSize.height - 200;
    final availableWidth = screenSize.width;

    double displayWidth, displayHeight;
    if (imageAspect > availableWidth / availableHeight) {
      displayWidth = availableWidth;
      displayHeight = availableWidth / imageAspect;
    } else {
      displayHeight = availableHeight;
      displayWidth = displayHeight * imageAspect;
    }

    final scaleX = displayWidth / _uiImage!.width;
    final scaleY = displayHeight / _uiImage!.height;
    final offsetX = (availableWidth - displayWidth) / 2;
    final offsetY = (availableHeight - displayHeight) / 2;

    final displayX = offsetX + _selectedWatermark!.position.dx * scaleX;
    final displayY = offsetY + _selectedWatermark!.position.dy * scaleY;

    // 将屏幕坐标转换到水印的局部坐标系（考虑旋转）
    final localPosition = screenPosition - Offset(displayX, displayY);
    final rotatedPosition = Offset(
      localPosition.dx * math.cos(-_selectedWatermark!.rotation) -
          localPosition.dy * math.sin(-_selectedWatermark!.rotation),
      localPosition.dx * math.sin(-_selectedWatermark!.rotation) +
          localPosition.dy * math.cos(-_selectedWatermark!.rotation),
    );

    final rect = _getWatermarkRect(_selectedWatermark!, scaleX, scaleY);

    // 控制点位置（在局部坐标系中）：左上、右上、右下、左下
    final topLeft = Offset(-rect.width / 2, -rect.height / 2);
    final topRight = Offset(rect.width / 2, -rect.height / 2);
    final bottomRight = Offset(rect.width / 2, rect.height / 2);
    final bottomLeft = Offset(-rect.width / 2, rect.height / 2);

    const controlPointSize = 30.0;

    if ((rotatedPosition - topLeft).distance < controlPointSize) {
      return ControlPoint.delete;
    } else if ((rotatedPosition - topRight).distance < controlPointSize) {
      return ControlPoint.edit;
    } else if ((rotatedPosition - bottomRight).distance < controlPointSize) {
      return ControlPoint.scaleRotate;
    } else if ((rotatedPosition - bottomLeft).distance < controlPointSize) {
      return ControlPoint.copy;
    }

    return ControlPoint.none;
  }

  void _handleControlPointTap(ControlPoint controlPoint) {
    switch (controlPoint) {
      case ControlPoint.delete:
        setState(() {
          _watermarks.remove(_selectedWatermark);
          _selectedWatermark = null;
        });
        _saveState();
        break;
      case ControlPoint.edit:
        _editWatermarkText();
        break;
      case ControlPoint.copy:
        if (_selectedWatermark != null) {
          final newWatermark = WatermarkElement(
            text: _selectedWatermark!.text,
            position: Offset(
              _selectedWatermark!.position.dx + 50,
              _selectedWatermark!.position.dy + 50,
            ),
            fontSize: _selectedWatermark!.fontSize,
            color: _selectedWatermark!.color,
            rotation: _selectedWatermark!.rotation,
            opacity: _selectedWatermark!.opacity,
          );
          setState(() {
            _watermarks.add(newWatermark);
            _selectedWatermark = newWatermark;
          });
          _saveState();
        }
        break;
      case ControlPoint.scaleRotate:
      case ControlPoint.none:
        break;
    }
  }

  void _handleScaleStartInLayout(
    Offset imageLocalPosition,
    double displayWidth,
    double displayHeight,
  ) {
    if (_uiImage == null) return;
    if (_selectedWatermark == null) return;

    final scaleX = displayWidth / _uiImage!.width;
    final scaleY = displayHeight / _uiImage!.height;

    // 转换为屏幕坐标（用于控制点检测）
    final screenSize = MediaQuery.of(context).size;
    final availableHeight = screenSize.height - 200;
    final availableWidth = screenSize.width;
    final offsetX = (availableWidth - displayWidth) / 2;
    final offsetY = (availableHeight - displayHeight) / 2;
    final screenPosition = Offset(
      imageLocalPosition.dx + offsetX,
      imageLocalPosition.dy + offsetY,
    );

    // 转换为图片坐标
    final imagePosition = Offset(
      imageLocalPosition.dx / scaleX,
      imageLocalPosition.dy / scaleY,
    );

    // 检查是否点击了控制点
    final controlPoint = _getControlPointAt(screenPosition);
    if (controlPoint == ControlPoint.scaleRotate) {
      // 点击了右下角控制点，根据拖动方向决定是缩放还是旋转
      setState(() {
        _activeControlPoint = ControlPoint.scaleRotate;
        _dragMode = DragMode.none; // 初始状态，根据拖动方向决定
        _initialFontSize = _selectedWatermark!.fontSize;
        _initialRotation = _selectedWatermark!.rotation;
        _dragStart = imagePosition;
      });
    }
  }

  void _handleScaleUpdateInLayout(
    Offset imageLocalPosition,
    double displayWidth,
    double displayHeight,
    double scale,
    double rotation,
  ) {
    if (_selectedWatermark == null || _dragStart == null || _uiImage == null)
      return;

    final scaleX = displayWidth / _uiImage!.width;
    final scaleY = displayHeight / _uiImage!.height;

    // 转换为图片坐标
    final imagePosition = Offset(
      imageLocalPosition.dx / scaleX,
      imageLocalPosition.dy / scaleY,
    );

    if (_activeControlPoint == ControlPoint.scaleRotate) {
      // 右下角控制点：根据拖动方向决定缩放或旋转
      final center = _selectedWatermark!.position;
      final startVector = _dragStart! - center;
      final currentVector = imagePosition - center;

      if (startVector.distance > 0 && currentVector.distance > 0) {
        // 计算角度变化
        final angleChange = (currentVector.direction - startVector.direction)
            .abs();

        // 如果角度变化较大，优先旋转；否则缩放
        if (angleChange > 0.1 || rotation.abs() > 0.1) {
          // 旋转模式
          setState(() {
            _dragMode = DragMode.rotate;
            _selectedWatermark!.rotation =
                _initialRotation +
                (currentVector.direction - startVector.direction);
          });
        } else {
          // 缩放模式
          final currentDistance = currentVector.distance;
          final startDistance = startVector.distance;
          if (startDistance > 0) {
            final scaleFactor = currentDistance / startDistance;
            setState(() {
              _dragMode = DragMode.scale;
              _selectedWatermark!.fontSize = (_initialFontSize * scaleFactor)
                  .clamp(10.0, 200.0);
              _fontSize = _selectedWatermark!.fontSize;
            });
          }
        }
      }
      return;
    }

    switch (_dragMode) {
      case DragMode.move:
        // 使用 scale 手势的平移部分来移动
        final delta = imagePosition - _dragStart!;
        setState(() {
          _selectedWatermark!.position += delta;
          _dragStart = imagePosition;
        });
        break;
      case DragMode.scale:
        // 使用距离计算来缩放
        final center = _selectedWatermark!.position;
        final currentDistance = (imagePosition - center).distance;
        final startDistance = (_dragStart! - center).distance;
        if (startDistance > 0) {
          final scaleFactor = currentDistance / startDistance;
          setState(() {
            _selectedWatermark!.fontSize = (_initialFontSize * scaleFactor)
                .clamp(10.0, 200.0);
            _fontSize = _selectedWatermark!.fontSize;
          });
        }
        break;
      case DragMode.rotate:
        // 计算旋转角度
        final center = _selectedWatermark!.position;
        final startVector = _dragStart! - center;
        final currentVector = imagePosition - center;
        if (startVector.distance > 0 && currentVector.distance > 0) {
          final startAngle = startVector.direction;
          final currentAngle = currentVector.direction;
          setState(() {
            _selectedWatermark!.rotation =
                _initialRotation + (currentAngle - startAngle);
          });
        }
        break;
      case DragMode.none:
        break;
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    // 拖拽结束时保存状态
    if (_dragMode != DragMode.none) {
      _saveState();
    }
    setState(() {
      _dragMode = DragMode.none;
      _activeControlPoint = ControlPoint.none;
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

class _WatermarkPainter extends CustomPainter {
  _WatermarkPainter({
    required this.image,
    required this.watermarks,
    this.selectedWatermark,
    required this.displaySize,
  });

  final ui.Image image;
  final List<WatermarkElement> watermarks;
  final WatermarkElement? selectedWatermark;
  final Size displaySize;

  @override
  void paint(Canvas canvas, Size size) {
    // 不在这里绘制图片，图片由Image.file显示
    // 只绘制水印

    // 计算缩放比例
    final scaleX = size.width / image.width;
    final scaleY = size.height / image.height;

    // 绘制水印
    for (final watermark in watermarks) {
      // watermark.fontSize 存储的是逻辑像素，直接使用
      final displayFontSize = watermark.fontSize * scaleX;

      final textPainter = TextPainter(
        text: TextSpan(
          text: watermark.text,
          style: TextStyle(
            color: watermark.color.withValues(alpha: watermark.opacity),
            fontSize: displayFontSize, // 使用逻辑像素
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // 计算水印在显示尺寸中的位置
      final displayX = watermark.position.dx * scaleX;
      final displayY = watermark.position.dy * scaleY;

      canvas.save();
      canvas.translate(displayX, displayY);
      canvas.rotate(watermark.rotation);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();

      // 绘制选中框和控制点
      if (watermark == selectedWatermark) {
        final rect = Rect.fromCenter(
          center: Offset(displayX, displayY),
          width: textPainter.width + 40,
          height: textPainter.height + 40,
        );

        // 绘制边框（考虑旋转）
        canvas.save();
        canvas.translate(displayX, displayY);
        canvas.rotate(watermark.rotation);

        final borderRect = Rect.fromCenter(
          center: Offset.zero,
          width: rect.width,
          height: rect.height,
        );
        canvas.drawRect(
          borderRect,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );

        // 控制点大小
        const controlPointRadius = 16.0;
        final controlPointPaint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;
        final controlPointBorder = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        // 左上角：删除（X图标）
        final topLeft = Offset(-rect.width / 2, -rect.height / 2);
        canvas.drawCircle(topLeft, controlPointRadius, controlPointPaint);
        canvas.drawCircle(topLeft, controlPointRadius, controlPointBorder);
        // 绘制X图标
        canvas.drawLine(
          Offset(topLeft.dx - 6, topLeft.dy - 6),
          Offset(topLeft.dx + 6, topLeft.dy + 6),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2,
        );
        canvas.drawLine(
          Offset(topLeft.dx + 6, topLeft.dy - 6),
          Offset(topLeft.dx - 6, topLeft.dy + 6),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2,
        );

        // 右上角：编辑（笔图标）
        final topRight = Offset(rect.width / 2, -rect.height / 2);
        canvas.drawCircle(topRight, controlPointRadius, controlPointPaint);
        canvas.drawCircle(topRight, controlPointRadius, controlPointBorder);
        // 绘制笔图标（简化版）
        final penPath = Path()
          ..moveTo(topRight.dx - 4, topRight.dy - 8)
          ..lineTo(topRight.dx - 2, topRight.dy - 6)
          ..lineTo(topRight.dx + 4, topRight.dy)
          ..lineTo(topRight.dx + 2, topRight.dy + 2)
          ..close();
        canvas.drawPath(
          penPath,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        );

        // 右下角：缩放/旋转（方形箭头）
        final bottomRight = Offset(rect.width / 2, rect.height / 2);
        canvas.drawCircle(bottomRight, controlPointRadius, controlPointPaint);
        canvas.drawCircle(bottomRight, controlPointRadius, controlPointBorder);
        // 绘制缩放/旋转图标（方形带箭头）
        canvas.drawRect(
          Rect.fromCenter(center: bottomRight, width: 8, height: 8),
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        // 绘制箭头
        canvas.drawLine(
          Offset(bottomRight.dx + 4, bottomRight.dy),
          Offset(bottomRight.dx + 8, bottomRight.dy),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 1.5,
        );
        canvas.drawLine(
          Offset(bottomRight.dx, bottomRight.dy + 4),
          Offset(bottomRight.dx, bottomRight.dy + 8),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 1.5,
        );

        // 左下角：复制（两个重叠的方形）
        final bottomLeft = Offset(-rect.width / 2, rect.height / 2);
        canvas.drawCircle(bottomLeft, controlPointRadius, controlPointPaint);
        canvas.drawCircle(bottomLeft, controlPointRadius, controlPointBorder);
        // 绘制复制图标（两个重叠的方形）
        canvas.drawRect(
          Rect.fromLTWH(bottomLeft.dx - 6, bottomLeft.dy - 6, 6, 6),
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        canvas.drawRect(
          Rect.fromLTWH(bottomLeft.dx - 2, bottomLeft.dy - 2, 6, 6),
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_WatermarkPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.watermarks.length != watermarks.length ||
        oldDelegate.selectedWatermark != selectedWatermark;
  }
}
