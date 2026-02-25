import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import '../services/opencv_service.dart';

class RemoveWatermarkPage extends StatefulWidget {
  const RemoveWatermarkPage({super.key});

  @override
  State<RemoveWatermarkPage> createState() => _RemoveWatermarkPageState();
}

class _RemoveWatermarkPageState extends State<RemoveWatermarkPage> {
  File? _selectedImage;
  List<List<Offset>> _watermarkPaths = []; // 存储的是显示坐标的路径点列表
  List<Offset>? _currentPath; // 当前正在绘制的路径
  final ValueNotifier<List<List<Offset>>> _watermarkPathsNotifier =
      ValueNotifier([]); // 用于优化重绘
  bool _isProcessing = false;
  img.Image? _uiImage; // 缓存图片对象，用于坐标转换
  // ignore: unused_field
  img.Image? _processedImage; // 处理后的图片，用于实时预览（保留用于未来扩展）
  // ignore: unused_field
  Uint8List? _processedImageBytes; // 缓存处理后的图片字节，避免重复编码（保留用于未来扩展）
  final ValueNotifier<Uint8List?> _processedImageNotifier =
      ValueNotifier<Uint8List?>(null); // 用于优化图片更新
  bool _isDragging = false; // 是否正在拖动
  Timer? _processDebounceTimer; // 3秒延迟定时器
  int _processedWatermarkCount = 0; // 已处理的水印数量，用于只显示未处理的路径
  static const double _eraserStrokeWidth = 20.0; // 橡皮擦笔触宽度

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final imageBytes = await File(image.path).readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      setState(() {
        _selectedImage = File(image.path);
        _uiImage = decodedImage;
        _watermarkPaths.clear();
        _currentPath = null;
        _watermarkPathsNotifier.value = [];
        _processedImage = null;
        _processedImageBytes = null;
        _processedImageNotifier.value = null;
        _processedWatermarkCount = 0; // 重置已处理数量
      });
      _processDebounceTimer?.cancel();
    }
  }

  Future<void> _saveImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先选择图片')));
      return;
    }

    if (_watermarkPaths.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先标记水印区域（用手指擦除）')));
      return;
    }

    if (_uiImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('图片加载失败，请重新选择')));
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

      // 计算图片显示尺寸和缩放比例（与 _buildEditorView 中的计算保持一致）
      final screenSize = MediaQuery.of(context).size;
      final imageAspect = originalImage.width / originalImage.height;
      final availableHeight = screenSize.height - 200; // 减去底部工具栏高度
      final availableWidth = screenSize.width;

      double displayWidth, displayHeight;
      if (imageAspect > availableWidth / availableHeight) {
        displayWidth = availableWidth;
        displayHeight = availableWidth / imageAspect;
      } else {
        displayHeight = availableHeight;
        displayWidth = displayHeight * imageAspect;
      }

      final scaleX = originalImage.width / displayWidth;
      final scaleY = originalImage.height / displayHeight;
      final offsetX = (availableWidth - displayWidth) / 2;
      final offsetY = (availableHeight - displayHeight) / 2;

      // 处理每个水印路径（将显示坐标转换为图片坐标）
      // 注意：保存功能暂时使用OpenCV处理，这里保留接口但实际不会调用
      // 因为_saveImage现在应该使用已处理的图片
      if (_processedImageBytes != null) {
        // 如果已经有处理后的图片，直接使用
        final processedBytes = _processedImageBytes!;
        // 保存处理后的图片
        if (await Permission.photos.isDenied) {
          await Permission.photos.request();
        }

        if (await Permission.photos.isGranted) {
          await ImageGallerySaver.saveImage(
            processedBytes,
            quality: 100,
            name: 'watermark_removed_${DateTime.now().millisecondsSinceEpoch}',
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
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('处理失败: $e'), backgroundColor: Colors.red),
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

  // 实时处理水印，用于预览（3秒延迟后自动处理）
  Future<void> _processWatermarks({bool immediate = false}) async {
    // 取消之前的定时器
    _processDebounceTimer?.cancel();

    if (_selectedImage == null || _watermarkPaths.isEmpty || _uiImage == null) {
      if (mounted) {
        _processedImageBytes = null;
        _processedImageNotifier.value = null;
        _processedImage = null;
        setState(() {
          _isProcessing = false;
        });
      }
      return;
    }

    // 如果不是立即处理，延迟3秒
    if (!immediate) {
      _processDebounceTimer = Timer(const Duration(seconds: 3), () {
        _processWatermarks(immediate: true);
      });
      return;
    }

    // 显示处理中状态（不立即更新 UI，避免闪烁）
    if (mounted) {
      setState(() {
        _isProcessing = true;
      });
    }

    try {
      // 计算图片显示尺寸和缩放比例
      final screenSize = MediaQuery.of(context).size;
      final imageAspect = _uiImage!.width / _uiImage!.height;
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

      final scaleX = _uiImage!.width / displayWidth;
      final scaleY = _uiImage!.height / displayHeight;

      // 将路径转换为图片坐标的矩形列表（计算每个路径的边界框）
      final imageRects = <Map<String, double>>[];
      // 只处理未处理的路径
      final unprocessedPaths = _watermarkPaths.length > _processedWatermarkCount
          ? _watermarkPaths.sublist(_processedWatermarkCount)
          : <List<Offset>>[];

      for (final path in unprocessedPaths) {
        if (path.isEmpty) continue;

        // 计算路径的边界框
        double minX = path[0].dx;
        double maxX = path[0].dx;
        double minY = path[0].dy;
        double maxY = path[0].dy;

        for (final point in path) {
          minX = math.min(minX, point.dx);
          maxX = math.max(maxX, point.dx);
          minY = math.min(minY, point.dy);
          maxY = math.max(maxY, point.dy);
        }

        // 转换为图片坐标，使用适中的 padding 确保覆盖笔触边缘
        // padding 太小可能导致边缘修复不完整，太大可能导致过度修复
        final padding = 4.0; // 使用 4 像素（显示坐标），确保完全覆盖水印区域
        final imageRect = Rect.fromLTWH(
          ((minX - padding) * scaleX).clamp(0.0, _uiImage!.width.toDouble()),
          ((minY - padding) * scaleY).clamp(0.0, _uiImage!.height.toDouble()),
          ((maxX - minX + padding * 2) * scaleX).clamp(
            1.0,
            _uiImage!.width.toDouble(),
          ),
          ((maxY - minY + padding * 2) * scaleY).clamp(
            1.0,
            _uiImage!.height.toDouble(),
          ),
        );

        if (imageRect.width >= 1 &&
            imageRect.height >= 1 &&
            imageRect.left < _uiImage!.width &&
            imageRect.top < _uiImage!.height) {
          imageRects.add({
            'x': imageRect.left,
            'y': imageRect.top,
            'width': imageRect.width,
            'height': imageRect.height,
          });
        }
      }

      if (imageRects.isEmpty) {
        if (mounted) {
          _processedImageBytes = null;
          _processedImageNotifier.value = null;
          _processedImage = null;
          setState(() {
            _isProcessing = false;
          });
        }
        return;
      }

      // 必须使用 OpenCV Inpaint（不支持回退）
      if (Platform.isAndroid || Platform.isIOS) {
        final isAvailable = await OpenCVService.isAvailable();
        if (!isAvailable) {
          throw Exception('OpenCV 不可用，请确保已正确集成 OpenCV');
        }

        // 确定要使用的图片路径：如果有已处理的图片，使用临时文件保存后处理
        String imagePathToProcess;
        if (_processedImageBytes != null) {
          // 如果有已处理的图片，先保存为临时文件，基于它继续处理
          final tempDir = Directory.systemTemp;
          final tempFile = File(
            '${tempDir.path}/watermark_temp_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          await tempFile.writeAsBytes(_processedImageBytes!);
          imagePathToProcess = tempFile.path;
        } else {
          // 第一次处理，使用原始图片
          if (_selectedImage == null) {
            throw Exception('图片文件不存在');
          }
          imagePathToProcess = _selectedImage!.path;
        }

        // 使用 OpenCV Inpaint（在后台线程执行）
        // 注意：compute 不能直接调用 async 函数，所以直接在这里调用
        final resultBytes = await OpenCVService.removeWatermarks(
          imagePathToProcess,
          imageRects,
        );

        // 清理临时文件
        if (_processedImageBytes != null &&
            imagePathToProcess != _selectedImage!.path) {
          try {
            final tempFile = File(imagePathToProcess);
            if (await tempFile.exists()) {
              await tempFile.delete();
            }
          } catch (e) {
            // 忽略临时文件删除错误
          }
        }

        if (resultBytes == null) {
          throw Exception('OpenCV 处理失败，返回结果为空');
        }

        // 在后台线程解码图片（避免阻塞 UI）
        final processedImage = await compute(_decodeImageBytes, resultBytes);
        if (processedImage == null) {
          throw Exception('无法解码处理后的图片');
        }

        if (mounted) {
          // 使用 ValueNotifier 更新，避免整个 widget 树重建
          _processedImage = processedImage;
          _processedImageBytes = resultBytes;
          // 先更新 ValueNotifier，再更新 state，避免闪烁
          _processedImageNotifier.value = resultBytes;
          setState(() {
            _isProcessing = false;
            // 更新已处理的水印数量（所有当前的水印都已处理）
            _processedWatermarkCount = _watermarkPaths.length;
          });
        }
      } else {
        throw UnsupportedError('OpenCV 仅支持 Android 和 iOS 平台');
      }
    } catch (e) {
      // 处理失败时显示原始图片
      if (mounted) {
        _processedImageBytes = null;
        _processedImageNotifier.value = null;
        _processedImage = null;
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('处理失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // 后台解码图片（用于 compute）
  static img.Image? _decodeImageBytes(Uint8List bytes) {
    return img.decodeImage(bytes);
  }

  // 静态版本的去除水印方法（用于后台处理，使用改进的patch-based算法）
  static void _removeWatermarkRegionStatic(img.Image image, Rect rect) {
    final x = rect.left.round().clamp(0, image.width - 1);
    final y = rect.top.round().clamp(0, image.height - 1);
    final width = rect.width.round().clamp(1, image.width - x);
    final height = rect.height.round().clamp(1, image.height - y);

    if (width <= 0 || height <= 0 || x >= image.width || y >= image.height) {
      return;
    }

    final endX = (x + width).clamp(0, image.width);
    final endY = (y + height).clamp(0, image.height);
    final actualWidth = endX - x;
    final actualHeight = endY - y;

    if (actualWidth <= 0 || actualHeight <= 0) {
      return;
    }

    // 使用改进的算法：结合多种方法
    // 1. 先使用大范围加权平均进行初步填充
    const largeRadius = 25; // 增大采样半径，确保有足够的周围像素
    for (int py = y; py < endY && py < image.height; py++) {
      for (int px = x; px < endX && px < image.width; px++) {
        final avgColor = _getWeightedAverageColorExcludingRegionStatic(
          image,
          px,
          py,
          largeRadius,
          x,
          y,
          actualWidth,
          actualHeight,
        );
        image.setPixel(px, py, avgColor);
      }
    }

    // 2. 使用中等半径进行精细修复
    const mediumRadius = 15;
    for (int py = y; py < endY && py < image.height; py++) {
      for (int px = x; px < endX && px < image.width; px++) {
        final refinedColor = _getWeightedAverageColorExcludingRegionStatic(
          image,
          px,
          py,
          mediumRadius,
          x,
          y,
          actualWidth,
          actualHeight,
        );
        image.setPixel(px, py, refinedColor);
      }
    }

    // 3. 使用小半径进行边缘平滑
    const smallRadius = 8;
    for (int py = y; py < endY && py < image.height; py++) {
      for (int px = x; px < endX && px < image.width; px++) {
        final smoothedColor = _getWeightedAverageColorExcludingRegionStatic(
          image,
          px,
          py,
          smallRadius,
          x,
          y,
          actualWidth,
          actualHeight,
        );
        image.setPixel(px, py, smoothedColor);
      }
    }
  }

  // 静态版本的加权平均方法（改进版，扩大采样范围，确保有足够的采样点）
  static img.Color _getWeightedAverageColorExcludingRegionStatic(
    img.Image image,
    int x,
    int y,
    int radius,
    int excludeX,
    int excludeY,
    int excludeWidth,
    int excludeHeight,
  ) {
    double r = 0, g = 0, b = 0, totalWeight = 0;
    int sampleCount = 0;

    // 第一遍：在指定半径内采样
    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        final nx = x + dx;
        final ny = y + dy;

        if (nx < 0 || nx >= image.width || ny < 0 || ny >= image.height) {
          continue;
        }

        // 完全跳过水印区域内的像素
        final isInExcludeRegion =
            nx >= excludeX &&
            nx < excludeX + excludeWidth &&
            ny >= excludeY &&
            ny < excludeY + excludeHeight;

        if (isInExcludeRegion) {
          continue;
        }

        final distance = math.sqrt(dx * dx + dy * dy);
        if (distance > radius) continue;

        // 使用高斯权重，距离越近权重越大
        final weight = math.exp(
          -(distance * distance) / (2 * (radius / 3) * (radius / 3)),
        );

        final pixel = image.getPixel(nx, ny);
        r += pixel.r * weight;
        g += pixel.g * weight;
        b += pixel.b * weight;
        totalWeight += weight;
        sampleCount++;
      }
    }

    // 如果采样点太少，扩大采样范围（最多扩大到2倍半径）
    if (sampleCount < 20 && radius < 50) {
      final extendedRadius = (radius * 1.5).round();
      for (int dy = -extendedRadius; dy <= extendedRadius; dy++) {
        for (int dx = -extendedRadius; dx <= extendedRadius; dx++) {
          final distance = math.sqrt(dx * dx + dy * dy);
          if (distance <= radius || distance > extendedRadius) continue;

          final nx = x + dx;
          final ny = y + dy;

          if (nx < 0 || nx >= image.width || ny < 0 || ny >= image.height) {
            continue;
          }

          final isInExcludeRegion =
              nx >= excludeX &&
              nx < excludeX + excludeWidth &&
              ny >= excludeY &&
              ny < excludeY + excludeHeight;

          if (isInExcludeRegion) {
            continue;
          }

          // 距离越远权重越小
          final weight =
              math.exp(
                -(distance * distance) / (2 * (radius / 3) * (radius / 3)),
              ) *
              0.3;

          final pixel = image.getPixel(nx, ny);
          r += pixel.r * weight;
          g += pixel.g * weight;
          b += pixel.b * weight;
          totalWeight += weight;
        }
      }
    }

    if (totalWeight == 0) {
      // 如果仍然没有采样点，尝试使用更远的像素
      for (int dy = -radius * 2; dy <= radius * 2; dy++) {
        for (int dx = -radius * 2; dx <= radius * 2; dx++) {
          final nx = x + dx;
          final ny = y + dy;

          if (nx < 0 || nx >= image.width || ny < 0 || ny >= image.height) {
            continue;
          }

          final isInExcludeRegion =
              nx >= excludeX &&
              nx < excludeX + excludeWidth &&
              ny >= excludeY &&
              ny < excludeY + excludeHeight;

          if (isInExcludeRegion) {
            continue;
          }

          final distance = math.sqrt(dx * dx + dy * dy);
          final weight = 1.0 / (1.0 + distance);

          final pixel = image.getPixel(nx, ny);
          r += pixel.r * weight;
          g += pixel.g * weight;
          b += pixel.b * weight;
          totalWeight += weight;

          if (totalWeight > 10) break; // 有足够的采样点就停止
        }
        if (totalWeight > 10) break;
      }
    }

    if (totalWeight == 0) {
      // 最后的备选方案：使用原始像素
      return image.getPixel(x, y);
    }

    return img.ColorRgb8(
      (r / totalWeight).round().clamp(0, 255),
      (g / totalWeight).round().clamp(0, 255),
      (b / totalWeight).round().clamp(0, 255),
    );
  }

  void _removeWatermarkRegion(img.Image image, Rect rect) {
    final x = rect.left.round().clamp(0, image.width - 1);
    final y = rect.top.round().clamp(0, image.height - 1);
    final width = rect.width.round().clamp(1, image.width - x);
    final height = rect.height.round().clamp(1, image.height - y);

    // 确保区域有效
    if (width <= 0 || height <= 0 || x >= image.width || y >= image.height) {
      return;
    }

    // 确保不会越界
    final endX = (x + width).clamp(0, image.width);
    final endY = (y + height).clamp(0, image.height);
    final actualWidth = endX - x;
    final actualHeight = endY - y;

    if (actualWidth <= 0 || actualHeight <= 0) {
      return;
    }

    // 使用改进的修复算法：多遍处理 + 排除水印区域采样
    // 第一遍：使用更大的采样半径进行初步填充，排除水印区域内的像素
    for (int py = y; py < endY && py < image.height; py++) {
      for (int px = x; px < endX && px < image.width; px++) {
        final avgColor = _getWeightedAverageColorExcludingRegion(
          image,
          px,
          py,
          15, // 增大采样半径
          x,
          y,
          actualWidth,
          actualHeight,
        );
        image.setPixel(px, py, avgColor);
      }
    }

    // 第二遍：使用较小的半径进行精细修复
    for (int py = y; py < endY && py < image.height; py++) {
      for (int px = x; px < endX && px < image.width; px++) {
        final refinedColor = _getWeightedAverageColorExcludingRegion(
          image,
          px,
          py,
          8,
          x,
          y,
          actualWidth,
          actualHeight,
        );
        image.setPixel(px, py, refinedColor);
      }
    }

    // 第三遍：轻微模糊边缘，使过渡更自然
    _smoothEdges(image, x, y, actualWidth, actualHeight);
  }

  // 使用加权平均，距离越近权重越大，排除指定区域内的像素
  img.Color _getWeightedAverageColorExcludingRegion(
    img.Image image,
    int x,
    int y,
    int radius,
    int excludeX,
    int excludeY,
    int excludeWidth,
    int excludeHeight,
  ) {
    double r = 0, g = 0, b = 0, totalWeight = 0;

    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        final nx = x + dx;
        final ny = y + dy;

        // 跳过超出边界的像素
        if (nx < 0 || nx >= image.width || ny < 0 || ny >= image.height) {
          continue;
        }

        // 跳过水印区域内的像素（但允许采样边界附近的像素）
        final isInExcludeRegion =
            nx >= excludeX &&
            nx < excludeX + excludeWidth &&
            ny >= excludeY &&
            ny < excludeY + excludeHeight;

        // 如果在水印区域内，跳过（除非是边界像素，边界像素可能已经被处理过）
        if (isInExcludeRegion) {
          // 检查是否是边界像素（距离水印区域边缘很近）
          final distToLeft = nx - excludeX;
          final distToRight = excludeX + excludeWidth - nx - 1;
          final distToTop = ny - excludeY;
          final distToBottom = excludeY + excludeHeight - ny - 1;
          final minDistToEdge = [
            distToLeft,
            distToRight,
            distToTop,
            distToBottom,
          ].reduce((a, b) => a < b ? a : b);

          // 只允许采样距离边缘很近的像素（可能已经被处理过）
          if (minDistToEdge > 2) {
            continue;
          }
        }

        // 计算权重（距离越近权重越大，使用高斯权重）
        final distance = math.sqrt(dx * dx + dy * dy);
        if (distance > radius) continue;

        // 高斯权重：距离越近权重越大
        final weight = math.exp(
          -(distance * distance) / (2 * (radius / 3) * (radius / 3)),
        );

        final pixel = image.getPixel(nx, ny);
        r += pixel.r * weight;
        g += pixel.g * weight;
        b += pixel.b * weight;
        totalWeight += weight;
      }
    }

    if (totalWeight == 0) {
      // 如果没有任何采样点，使用原始像素
      return image.getPixel(x, y);
    }

    return img.ColorRgb8(
      (r / totalWeight).round().clamp(0, 255),
      (g / totalWeight).round().clamp(0, 255),
      (b / totalWeight).round().clamp(0, 255),
    );
  }

  // 平滑边缘，使过渡更自然
  void _smoothEdges(img.Image image, int x, int y, int width, int height) {
    final edgeRadius = 3;
    for (int py = y; py < y + height && py < image.height; py++) {
      for (int px = x; px < x + width && px < image.width; px++) {
        // 检查是否在边缘区域
        final distToEdge = [
          px - x,
          x + width - px - 1,
          py - y,
          y + height - py - 1,
        ].reduce((a, b) => a < b ? a : b);

        if (distToEdge < edgeRadius) {
          // 在边缘区域，使用更小的采样半径，排除水印区域
          final smoothedColor = _getWeightedAverageColorExcludingRegion(
            image,
            px,
            py,
            edgeRadius,
            x,
            y,
            width,
            height,
          );
          image.setPixel(px, py, smoothedColor);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('去水印'),
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
              tooltip: '保存',
            ),
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _processDebounceTimer?.cancel();
                setState(() {
                  _selectedImage = null;
                  _watermarkPaths.clear();
                  _currentPath = null;
                  _watermarkPathsNotifier.value = [];
                  _processedImage = null;
                  _processedImageBytes = null;
                  _processedImageNotifier.value = null;
                });
              },
              tooltip: '清除',
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
            Icons.image_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text('选择一张图片开始', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮从相册选择图片',
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
    return Stack(
      children: [
        // 图片显示和标记区域
        Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 3.0,
            panEnabled: false, // 禁用平移，避免与手势冲突
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (_uiImage == null) return const SizedBox();

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
                  onPanStart: (details) {
                    // 将 localPosition 转换为相对于图片的坐标
                    final rawX = details.localPosition.dx - offsetX;
                    final rawY = details.localPosition.dy - offsetY;
                    final imageLocalPosition = Offset(
                      rawX.clamp(0.0, displayWidth),
                      rawY.clamp(0.0, displayHeight),
                    );
                    setState(() {
                      _isDragging = true;
                      // 取消之前的3秒定时器
                      _processDebounceTimer?.cancel();
                      // 开始新的路径
                      _currentPath = [imageLocalPosition];
                    });
                  },
                  onPanUpdate: (details) {
                    if (_currentPath != null) {
                      // 将 localPosition 转换为相对于图片的坐标
                      final rawX = details.localPosition.dx - offsetX;
                      final rawY = details.localPosition.dy - offsetY;
                      final imageLocalPosition = Offset(
                        rawX.clamp(0.0, displayWidth),
                        rawY.clamp(0.0, displayHeight),
                      );
                      // 添加点到当前路径
                      setState(() {
                        _currentPath!.add(imageLocalPosition);
                        _watermarkPathsNotifier.value = [
                          ..._watermarkPaths,
                          _currentPath!,
                        ];
                      });
                    }
                  },
                  onPanEnd: (details) {
                    setState(() {
                      _isDragging = false;
                      // 保存当前路径
                      if (_currentPath != null && _currentPath!.length > 1) {
                        _watermarkPaths.add(_currentPath!);
                        _currentPath = null;
                        _watermarkPathsNotifier.value = List.from(
                          _watermarkPaths,
                        );
                      } else {
                        _currentPath = null;
                      }
                    });
                    // 完成绘制后，启动3秒延迟定时器
                    if (mounted && _watermarkPaths.isNotEmpty) {
                      _processWatermarks();
                    }
                  },
                  child: Stack(
                    children: [
                      // 显示处理后的图片（如果有）或原始图片（使用 RepaintBoundary 和 ValueListenableBuilder 优化）
                      Positioned(
                        left: offsetX,
                        top: offsetY,
                        width: displayWidth,
                        height: displayHeight,
                        child: RepaintBoundary(
                          child: ValueListenableBuilder<Uint8List?>(
                            valueListenable: _processedImageNotifier,
                            builder: (context, processedBytes, child) {
                              // 使用缓存的字节，避免重复编码
                              if (processedBytes != null) {
                                return Image.memory(
                                  processedBytes,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true, // 避免切换时的闪烁
                                );
                              } else {
                                return Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true, // 避免切换时的闪烁
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      // 绘制水印标记（只显示未处理的路径）
                      Positioned(
                        left: offsetX,
                        top: offsetY,
                        width: displayWidth,
                        height: displayHeight,
                        child: IgnorePointer(
                          child: ValueListenableBuilder<List<List<Offset>>>(
                            valueListenable: _watermarkPathsNotifier,
                            builder: (context, paths, child) {
                              // 只显示未处理的路径（索引 >= _processedWatermarkCount）
                              final unprocessedPaths =
                                  paths.length > _processedWatermarkCount
                                  ? paths.sublist(_processedWatermarkCount)
                                  : <List<Offset>>[];
                              // 包含当前正在绘制的路径
                              final allPaths = _currentPath != null
                                  ? [...unprocessedPaths, _currentPath!]
                                  : unprocessedPaths;
                              return CustomPaint(
                                size: Size(displayWidth, displayHeight),
                                painter: _WatermarkPathPainter(
                                  watermarkPaths: allPaths,
                                  strokeWidth: _eraserStrokeWidth,
                                ),
                              );
                            },
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
        // 底部操作栏
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
                        if (_watermarkPaths.isNotEmpty) {
                          _watermarkPaths.removeLast();
                          // 如果撤销的是已处理的水印，减少已处理数量
                          if (_processedWatermarkCount > 0 &&
                              _watermarkPaths.length <
                                  _processedWatermarkCount) {
                            _processedWatermarkCount = _watermarkPaths.length;
                            // 清除处理结果，因为撤销了已处理的水印
                            _processedImageBytes = null;
                            _processedImageNotifier.value = null;
                            _processedImage = null;
                          }
                        }
                        _currentPath = null;
                        _watermarkPathsNotifier.value = List.from(
                          _watermarkPaths,
                        );
                      });
                      // 取消定时器
                      _processDebounceTimer?.cancel();
                      // 如果有未处理的水印，重新处理
                      if (_watermarkPaths.length > _processedWatermarkCount) {
                        _processWatermarks();
                      }
                    },
                    icon: const Icon(Icons.undo),
                    label: const Text('撤销'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // 先清除处理结果，避免闪烁
                      _processedImageBytes = null;
                      _processedImageNotifier.value = null;
                      _processedImage = null;

                      setState(() {
                        // 清除所有标记
                        _watermarkPaths.clear();
                        _currentPath = null;
                        _watermarkPathsNotifier.value = [];
                        _isProcessing = false;
                        _processedWatermarkCount = 0; // 重置已处理数量
                      });

                      // 取消待处理的定时器
                      _processDebounceTimer?.cancel();

                      // 显示提示
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('已清除所有标记'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('清除全部'),
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

class _WatermarkPathPainter extends CustomPainter {
  _WatermarkPathPainter({
    required this.watermarkPaths,
    required this.strokeWidth,
  });

  final List<List<Offset>> watermarkPaths;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // 如果没有路径，不绘制任何内容
    if (watermarkPaths.isEmpty) {
      return;
    }

    // 绘制水印路径（半透明红色，类似橡皮擦标记）
    final pathPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final path in watermarkPaths) {
      if (path.length < 2) continue;

      final paintPath = Path();
      paintPath.moveTo(
        path[0].dx.clamp(0.0, size.width),
        path[0].dy.clamp(0.0, size.height),
      );

      for (int i = 1; i < path.length; i++) {
        paintPath.lineTo(
          path[i].dx.clamp(0.0, size.width),
          path[i].dy.clamp(0.0, size.height),
        );
      }

      canvas.drawPath(paintPath, pathPaint);
    }
  }

  @override
  bool shouldRepaint(_WatermarkPathPainter oldDelegate) {
    return oldDelegate.watermarkPaths != watermarkPaths ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
