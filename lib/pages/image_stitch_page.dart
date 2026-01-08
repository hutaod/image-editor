import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

enum StitchLayout { horizontal, vertical, grid }

class ImageStitchPage extends StatefulWidget {
  const ImageStitchPage({super.key});

  @override
  State<ImageStitchPage> createState() => _ImageStitchPageState();
}

class _ImageStitchPageState extends State<ImageStitchPage> {
  List<File> _selectedImages = [];
  StitchLayout _layout = StitchLayout.vertical;
  int _spacing = 10;
  Color _backgroundColor = Colors.white;
  bool _isProcessing = false;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.map((e) => File(e.path)).toList();
      });
    }
  }

  Future<void> _stitchAndSave() async {
    if (_selectedImages.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择两张图片')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // 加载所有图片
      final images = <img.Image>[];
      for (final file in _selectedImages) {
        final bytes = await file.readAsBytes();
        final image = img.decodeImage(bytes);
        if (image != null) {
          images.add(image);
        }
      }

      if (images.isEmpty) {
        throw Exception('无法加载图片');
      }

      // 拼接图片
      final stitchedImage = _stitchImages(images);

      // 保存图片
      final processedBytes = img.encodePng(stitchedImage);

      // 请求存储权限
      if (await Permission.photos.isDenied) {
        await Permission.photos.request();
      }

      if (await Permission.photos.isGranted) {
        await ImageGallerySaver.saveImage(
          processedBytes,
          quality: 100,
          name: 'stitched_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('图片已保存到相册'),
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
            content: Text('处理失败: $e'),
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

  img.Image _stitchImages(List<img.Image> images) {
    switch (_layout) {
      case StitchLayout.horizontal:
        return _stitchHorizontal(images);
      case StitchLayout.vertical:
        return _stitchVertical(images);
      case StitchLayout.grid:
        return _stitchGrid(images);
    }
  }

  img.Image _stitchHorizontal(List<img.Image> images) {
    // 统一高度（使用最小高度）
    final minHeight = images.map((e) => e.height).reduce((a, b) => a < b ? a : b);
    final resizedImages = images.map((image) {
      if (image.height != minHeight) {
        final ratio = minHeight / image.height;
        final newWidth = (image.width * ratio).round();
        return img.copyResize(image, width: newWidth, height: minHeight);
      }
      return image;
    }).toList();

    // 计算总宽度
    final totalWidth = resizedImages.fold<int>(
      0,
      (sum, image) => sum + image.width,
    ) + (_spacing * (resizedImages.length - 1));

    // 创建画布
    final canvas = img.Image(
      width: totalWidth,
      height: minHeight,
    );

    // 填充背景色
    final bgColor = img.ColorRgb8(
      _backgroundColor.red,
      _backgroundColor.green,
      _backgroundColor.blue,
    );
    img.fill(canvas, color: bgColor);

    // 绘制图片
    int x = 0;
    for (final image in resizedImages) {
      img.compositeImage(canvas, image, dstX: x, dstY: 0);
      x += image.width + _spacing;
    }

    return canvas;
  }

  img.Image _stitchVertical(List<img.Image> images) {
    // 统一宽度（使用最小宽度）
    final minWidth = images.map((e) => e.width).reduce((a, b) => a < b ? a : b);
    final resizedImages = images.map((image) {
      if (image.width != minWidth) {
        final ratio = minWidth / image.width;
        final newHeight = (image.height * ratio).round();
        return img.copyResize(image, width: minWidth, height: newHeight);
      }
      return image;
    }).toList();

    // 计算总高度
    final totalHeight = resizedImages.fold<int>(
      0,
      (sum, image) => sum + image.height,
    ) + (_spacing * (resizedImages.length - 1));

    // 创建画布
    final canvas = img.Image(
      width: minWidth,
      height: totalHeight,
    );

    // 填充背景色
    final bgColor = img.ColorRgb8(
      _backgroundColor.red,
      _backgroundColor.green,
      _backgroundColor.blue,
    );
    img.fill(canvas, color: bgColor);

    // 绘制图片
    int y = 0;
    for (final image in resizedImages) {
      img.compositeImage(canvas, image, dstX: 0, dstY: y);
      y += image.height + _spacing;
    }

    return canvas;
  }

  img.Image _stitchGrid(List<img.Image> images) {
    // 计算网格布局（2列）
    final columns = 2;
    final rows = (images.length / columns).ceil();

    // 统一尺寸（使用最小宽度和高度）
    final minWidth = images.map((e) => e.width).reduce((a, b) => a < b ? a : b);
    final minHeight = images.map((e) => e.height).reduce((a, b) => a < b ? a : b);
    final cellSize = minWidth < minHeight ? minWidth : minHeight;

    final resizedImages = images.map((image) {
      return img.copyResize(image, width: cellSize, height: cellSize);
    }).toList();

    // 计算画布尺寸
    final canvasWidth = (cellSize * columns) + (_spacing * (columns - 1));
    final canvasHeight = (cellSize * rows) + (_spacing * (rows - 1));

    // 创建画布
    final canvas = img.Image(
      width: canvasWidth,
      height: canvasHeight,
    );

    // 填充背景色
    final bgColor = img.ColorRgb8(
      _backgroundColor.red,
      _backgroundColor.green,
      _backgroundColor.blue,
    );
    img.fill(canvas, color: bgColor);

    // 绘制图片
    for (int i = 0; i < resizedImages.length; i++) {
      final row = i ~/ columns;
      final col = i % columns;
      final x = col * (cellSize + _spacing);
      final y = row * (cellSize + _spacing);
      img.compositeImage(canvas, resizedImages[i], dstX: x, dstY: y);
    }

    return canvas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图片拼接'),
        actions: [
          if (_selectedImages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _selectedImages.clear();
                });
              },
            ),
        ],
      ),
      body: _selectedImages.isEmpty
          ? _buildEmptyState()
          : _buildEditorView(),
      floatingActionButton: _selectedImages.length >= 2
          ? FloatingActionButton.extended(
              onPressed: _isProcessing ? null : _stitchAndSave,
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
            Icons.photo_library_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            '选择多张图片开始拼接',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '至少选择两张图片进行拼接',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _pickImages,
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
        // 图片预览区域
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImages[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImages.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        // 设置面板
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '布局方式',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<StitchLayout>(
                  segments: const [
                    ButtonSegment<StitchLayout>(
                      value: StitchLayout.horizontal,
                      label: Text('横向'),
                      icon: Icon(Icons.swap_horiz),
                    ),
                    ButtonSegment<StitchLayout>(
                      value: StitchLayout.vertical,
                      label: Text('纵向'),
                      icon: Icon(Icons.swap_vert),
                    ),
                    ButtonSegment<StitchLayout>(
                      value: StitchLayout.grid,
                      label: Text('网格'),
                      icon: Icon(Icons.grid_view),
                    ),
                  ],
                  selected: {_layout},
                  onSelectionChanged: (Set<StitchLayout> newSelection) {
                    setState(() {
                      _layout = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '间距: $_spacing',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Expanded(
                      child: Slider(
                        value: _spacing.toDouble(),
                        min: 0,
                        max: 50,
                        divisions: 50,
                        label: '$_spacing',
                        onChanged: (value) {
                          setState(() {
                            _spacing = value.toInt();
                          });
                        },
                      ),
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

