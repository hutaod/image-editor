import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image/image.dart' as img;
import '../models/id_photo_template.dart';
import '../services/image_service.dart';
import 'id_photo_template_page.dart';
import 'id_photo_background_page.dart';

/// 裁剪页面
class IdPhotoCropPage extends HookConsumerWidget {
  final File imageFile;
  final IdPhotoTemplate template;

  const IdPhotoCropPage({
    super.key,
    required this.imageFile,
    required this.template,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageBytes = useState<Uint8List?>(null);
    final selectedTemplate = useState<IdPhotoTemplate>(template);
    final cropRect = useState<Rect?>(null);
    final imageSize = useState<Size?>(null);
    final cropWidgetKey = GlobalKey<_CropWidgetState>();

    Future<void> loadImage() async {
      final bytes = await imageFile.readAsBytes();
      // 修正 EXIF 方向
      final fixedBytes = await ImageService.fixOrientation(bytes);
      imageBytes.value = fixedBytes;

      // 解码图片获取尺寸
      final decoded = img.decodeImage(fixedBytes);
      if (decoded != null) {
        imageSize.value = Size(decoded.width.toDouble(), decoded.height.toDouble());
      }
    }

    useEffect(() {
      loadImage();
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('裁剪图片'),
      ),
      body: imageBytes.value == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _CropWidget(
                    key: cropWidgetKey,
                    imageBytes: imageBytes.value!,
                    template: selectedTemplate.value,
                    imageSize: imageSize.value,
                    onCropChanged: (rect) {
                      cropRect.value = rect;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedTemplate.value.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${selectedTemplate.value.widthMm} x ${selectedTemplate.value.heightMm} mm',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final newTemplate = await Navigator.of(context).push<IdPhotoTemplate>(
                                    MaterialPageRoute(
                                      builder: (context) => const IdPhotoTemplatePage(selectMode: true),
                                    ),
                                  );
                                  if (newTemplate != null) {
                                    selectedTemplate.value = newTemplate;
                                  }
                                },
                                child: const Text('更换'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (cropRect.value == null || imageSize.value == null) return;

                            // 从 _CropWidget 获取当前的 scale、offset 和 targetImageSize
                            final cropState = cropWidgetKey.currentState;
                            if (cropState == null) return;
                            
                            final currentScale = cropState.getScale();
                            final currentOffset = cropState.getOffset();
                            final targetImageSize = cropState.getTargetImageSize();
                            
                            // 需要将屏幕坐标转换为图片坐标
                            // 获取 _CropWidget 内部的图片显示尺寸计算逻辑
                            final imageAspect = imageSize.value!.width / imageSize.value!.height;
                            final screenSize = MediaQuery.of(context).size;
                            
                            // 计算图片在屏幕上的实际显示尺寸（与 _CropWidget 中的计算保持一致）
                            double scaledDisplayWidth, scaledDisplayHeight;
                            
                            // 如果 targetImageSize 不为空，说明图片是通过 SizedBox + FittedBox 显示的
                            if (targetImageSize != null) {
                              // SizedBox 的尺寸是 targetImageSize * scale（这是容器的尺寸）
                              final containerWidth = targetImageSize.width * currentScale;
                              final containerHeight = targetImageSize.height * currentScale;
                              
                              // FittedBox 会将图片按比例缩放以适应容器（BoxFit.contain）
                              // 计算 FittedBox 内部的缩放比例
                              final fitScaleX = containerWidth / imageSize.value!.width;
                              final fitScaleY = containerHeight / imageSize.value!.height;
                              // BoxFit.contain 使用较小的缩放比例
                              final fitScale = fitScaleX < fitScaleY ? fitScaleX : fitScaleY;
                              
                              // 图片在容器内的实际显示尺寸
                              scaledDisplayWidth = imageSize.value!.width * fitScale;
                              scaledDisplayHeight = imageSize.value!.height * fitScale;
                            } else {
                              // 否则，图片是通过 Transform.scale + Image.memory 显示的
                              // 需要计算图片在屏幕上的显示尺寸
                              final availableWidth = screenSize.width;
                              final availableHeight = screenSize.height;
                              
                              double imageDisplayWidth, imageDisplayHeight;
                              if (imageAspect > availableWidth / availableHeight) {
                                // 图片更宽，以宽度为准
                                imageDisplayWidth = availableWidth;
                                imageDisplayHeight = availableWidth / imageAspect;
                              } else {
                                // 图片更高，以高度为准
                                imageDisplayHeight = availableHeight;
                                imageDisplayWidth = availableHeight * imageAspect;
                              }
                              
                              // 考虑缩放（Transform.scale 的影响）
                              scaledDisplayWidth = imageDisplayWidth * currentScale;
                              scaledDisplayHeight = imageDisplayHeight * currentScale;
                            }
                            
                            // Transform.translate 的偏移是相对于图片显示区域的
                            // 图片的实际显示区域中心在屏幕中心，然后加上 offset
                            // 所以图片的实际左上角位置是：
                            // 屏幕中心 - 缩放后的图片尺寸/2 + offset
                            final actualImageCenterX = screenSize.width / 2 + currentOffset.dx;
                            final actualImageCenterY = screenSize.height / 2 + currentOffset.dy;
                            final actualImageLeft = actualImageCenterX - scaledDisplayWidth / 2;
                            final actualImageTop = actualImageCenterY - scaledDisplayHeight / 2;
                            
                            // 将裁剪框的屏幕坐标转换为图片坐标
                            // 裁剪框是相对于屏幕的，需要减去图片的实际显示位置
                            final cropScreenX = cropRect.value!.left - actualImageLeft;
                            final cropScreenY = cropRect.value!.top - actualImageTop;
                            final cropScreenWidth = cropRect.value!.width;
                            final cropScreenHeight = cropRect.value!.height;
                            
                            // 转换为图片像素坐标（保持宽高比，不拉伸）
                            // 由于都使用 BoxFit.contain，图片会按比例缩放，所以宽度和高度的缩放比例应该相同
                            final scaleRatioX = imageSize.value!.width / scaledDisplayWidth;
                            final scaleRatioY = imageSize.value!.height / scaledDisplayHeight;
                            
                            // 理论上 scaleRatioX 和 scaleRatioY 应该相同（因为 BoxFit.contain 保持宽高比）
                            // 但为了安全，使用平均值
                            final scaleRatio = (scaleRatioX + scaleRatioY) / 2;
                            
                            // 将屏幕坐标转换为图片坐标
                            final cropImageX = (cropScreenX * scaleRatio).round().clamp(0, imageSize.value!.width.toInt());
                            final cropImageY = (cropScreenY * scaleRatio).round().clamp(0, imageSize.value!.height.toInt());
                            final cropImageWidth = (cropScreenWidth * scaleRatio).round().clamp(1, imageSize.value!.width.toInt() - cropImageX);
                            final cropImageHeight = (cropScreenHeight * scaleRatio).round().clamp(1, imageSize.value!.height.toInt() - cropImageY);
                            
                            // 确保裁剪区域保持正确的宽高比（基于模板）
                            final templateAspect = selectedTemplate.value.widthPx / selectedTemplate.value.heightPx;
                            final cropAspect = cropImageWidth / cropImageHeight;
                            
                            // 如果宽高比不匹配，调整裁剪区域（以较小的尺寸为准，避免拉伸）
                            int finalCropX = cropImageX;
                            int finalCropY = cropImageY;
                            int finalCropWidth = cropImageWidth;
                            int finalCropHeight = cropImageHeight;
                            
                            if ((cropAspect - templateAspect).abs() > 0.01) {
                              // 宽高比不匹配，需要调整
                              if (cropAspect > templateAspect) {
                                // 裁剪区域太宽，以高度为准
                                finalCropWidth = (cropImageHeight * templateAspect).round();
                                // 保持中心位置
                                final cropCenterX = cropImageX + cropImageWidth ~/ 2;
                                finalCropX = (cropCenterX - finalCropWidth ~/ 2).clamp(0, imageSize.value!.width.toInt() - finalCropWidth);
                                finalCropWidth = (imageSize.value!.width.toInt() - finalCropX).clamp(1, finalCropWidth);
                              } else {
                                // 裁剪区域太高，以宽度为准
                                finalCropHeight = (cropImageWidth / templateAspect).round();
                                // 保持中心位置
                                final cropCenterY = cropImageY + cropImageHeight ~/ 2;
                                finalCropY = (cropCenterY - finalCropHeight ~/ 2).clamp(0, imageSize.value!.height.toInt() - finalCropHeight);
                                finalCropHeight = (imageSize.value!.height.toInt() - finalCropY).clamp(1, finalCropHeight);
                              }
                            }

                            // 执行裁剪（使用调整后的尺寸，确保不拉伸）
                            final cropped = await ImageService.cropImage(
                              imageBytes.value!,
                              finalCropX,
                              finalCropY,
                              finalCropWidth,
                              finalCropHeight,
                            );

                            // 调整到模板尺寸（保持宽高比，不拉伸）
                            final resized = await ImageService.resizeImage(
                              cropped,
                              selectedTemplate.value.widthPx,
                              selectedTemplate.value.heightPx,
                              maintainAspect: true, // 保持宽高比，不拉伸
                            );

                            // 导航到背景替换页面
                            if (context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => IdPhotoBackgroundPage(
                                    imageBytes: resized,
                                    template: selectedTemplate.value,
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            '下一步：背景替换',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// 裁剪组件
class _CropWidget extends StatefulWidget {
  final Uint8List imageBytes;
  final IdPhotoTemplate? template;
  final Size? imageSize;
  final ValueChanged<Rect> onCropChanged;

  const _CropWidget({
    super.key,
    required this.imageBytes,
    required this.template,
    this.imageSize,
    required this.onCropChanged,
  });
  
  @override
  State<_CropWidget> createState() => _CropWidgetState();
}

class _CropWidgetState extends State<_CropWidget> {
  double scale = 1.0;
  Offset offset = Offset.zero;
  Rect? cropRect;
  double initialScale = 1.0;
  Offset initialOffset = Offset.zero;
  Size? localImageSize;
  bool isInitialized = false;
  Size? targetImageSize; // 目标图片显示尺寸（用于精确匹配裁剪框）
  bool useCoverFit = false; // 是否使用 BoxFit.cover（当比例不同时）

  double getScale() => scale;
  Offset getOffset() => offset;
  Size? getTargetImageSize() => targetImageSize;

  @override
  void initState() {
    super.initState();
    localImageSize = widget.imageSize;
    if (localImageSize == null) {
      final decoded = img.decodeImage(widget.imageBytes);
      if (decoded != null) {
        localImageSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = constraints.biggest;
        
        // 计算裁剪区域和初始缩放（基于模板比例和图片比例）
        if (widget.template != null && localImageSize != null && !isInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            
            final templateAspect = widget.template!.widthPx / widget.template!.heightPx;
            final imageAspect = localImageSize!.width / localImageSize!.height;
            
            // 计算裁剪框大小（占屏幕80%）
            double cropWidth = screenSize.width * 0.8;
            double cropHeight = cropWidth / templateAspect;
            
            if (cropHeight > screenSize.height * 0.8) {
              cropHeight = screenSize.height * 0.8;
              cropWidth = cropHeight * templateAspect;
            }
            
            final rect = Rect.fromCenter(
              center: Offset(screenSize.width / 2, screenSize.height / 2),
              width: cropWidth,
              height: cropHeight,
            );
            
            setState(() {
              cropRect = rect;
            });
            
            // 计算图片在屏幕上的显示尺寸（使用 BoxFit.contain）
            // Image.memory 使用 BoxFit.contain 时，图片会按比例缩放以适应可用空间
            // 可用空间是整个屏幕（因为图片在 Center widget 中）
            // 注意：需要考虑设备像素比（devicePixelRatio）的影响
            double imageDisplayWidth, imageDisplayHeight;
            final availableWidth = screenSize.width;
            final availableHeight = screenSize.height;
            
            // 计算图片在屏幕上的实际显示尺寸（BoxFit.contain）
            if (imageAspect > availableWidth / availableHeight) {
              // 图片更宽，以宽度为准
              imageDisplayWidth = availableWidth;
              imageDisplayHeight = availableWidth / imageAspect;
            } else {
              // 图片更高，以高度为准
              imageDisplayHeight = availableHeight;
              imageDisplayWidth = availableHeight * imageAspect;
            }
            
            // 基于裁剪框尺寸和图片显示尺寸计算缩放
            // 证件照裁剪的特殊需求：如果比例相同，图片应该完全匹配裁剪框大小
            double newScale;
            
            // 判断图片比例和模板比例是否相同（允许0.01的误差）
            final aspectDiff = (imageAspect - templateAspect).abs();
            
            if (aspectDiff < 0.01) {
              // 比例相同：直接设置目标尺寸为裁剪框尺寸，确保完全匹配
              // 不使用缩放，而是直接使用精确的尺寸控制
              final scaleByWidth = cropWidth / imageDisplayWidth;
              final scaleByHeight = cropHeight / imageDisplayHeight;
              
              // 计算初始缩放值（用于后续的手势缩放）
              newScale = (scaleByWidth + scaleByHeight) / 2;
              
              // 确保至少为1.0，避免图片比裁剪框小
              if (newScale < 1.0) {
                newScale = 1.0;
              }
              
              // 设置目标尺寸为裁剪框尺寸，确保完全匹配
              setState(() {
                targetImageSize = Size(cropWidth, cropHeight);
                useCoverFit = false; // 比例相同时使用 BoxFit.contain
              });
            } else {
              // 比例不同：需要确保缩放后的图片能够完全覆盖裁剪框
              // 设置目标尺寸为裁剪框尺寸，使用 BoxFit.cover 确保完全覆盖
              setState(() {
                targetImageSize = Size(cropWidth, cropHeight);
                useCoverFit = true; // 标记使用 BoxFit.cover
              });
              
              // 计算缩放值：使图片能够完全覆盖裁剪框
              // 由于使用 SizedBox + FittedBox(BoxFit.cover)，图片会自动缩放以覆盖容器
              // 这里只需要设置一个合适的初始缩放值，用于手势缩放
              final scaleX = cropWidth / imageDisplayWidth;
              final scaleY = cropHeight / imageDisplayHeight;
              
              // 使用较大的缩放值以确保完全覆盖
              newScale = scaleX > scaleY ? scaleX : scaleY;
              
              // 确保缩放值至少为1.0
              if (newScale < 1.0) {
                newScale = 1.0;
              }
            }
            
            setState(() {
              scale = newScale;
              initialScale = newScale;
              isInitialized = true;
            });
            
            widget.onCropChanged(rect);
          });
        }
        
        return Stack(
          children: [
            // 图片显示区域
            Center(
              child: Transform.translate(
                offset: offset,
                child: targetImageSize != null && widget.template != null
                    ? SizedBox(
                        width: targetImageSize!.width * scale,
                        height: targetImageSize!.height * scale,
                        child: FittedBox(
                          fit: useCoverFit ? BoxFit.cover : BoxFit.contain,
                          child: Image.memory(
                            widget.imageBytes,
                          ),
                        ),
                      )
                    : Transform.scale(
                        scale: scale,
                        alignment: Alignment.center,
                        child: Image.memory(
                          widget.imageBytes,
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
            ),
            
            // 裁剪框和遮罩
            CustomPaint(
              size: screenSize,
              painter: _CropOverlayPainter(
                template: widget.template,
                canvasSize: screenSize,
              ),
            ),
            
            // 手势检测
            GestureDetector(
              onScaleStart: (details) {
                setState(() {
                  initialScale = scale;
                  initialOffset = offset;
                });
              },
              onScaleUpdate: (details) {
                // 处理缩放（降低敏感度）
                final scaleDelta = details.scale - 1.0;
                final newScale = (initialScale * (1 + scaleDelta * 0.3)).clamp(0.5, 3.0);
                
                // 处理移动
                final newOffset = initialOffset + details.focalPointDelta;
                
                setState(() {
                  scale = newScale;
                  
                  // 限制移动范围
                  if (localImageSize != null) {
                    final imageAspect = localImageSize!.width / localImageSize!.height;
                    final screenSize = MediaQuery.of(context).size;
                    double imageDisplayWidth, imageDisplayHeight;
                    
                    if (imageAspect > screenSize.width / screenSize.height) {
                      imageDisplayWidth = screenSize.width;
                      imageDisplayHeight = screenSize.width / imageAspect;
                    } else {
                      imageDisplayHeight = screenSize.height;
                      imageDisplayWidth = screenSize.height * imageAspect;
                    }
                    
                    final scaledWidth = imageDisplayWidth * newScale;
                    final scaledHeight = imageDisplayHeight * newScale;
                    
                    final templateAspect = widget.template?.widthPx ?? 1.0 / (widget.template?.heightPx ?? 1.0);
                    double cropWidth = screenSize.width * 0.8;
                    double cropHeight = cropWidth / templateAspect;
                    if (cropHeight > screenSize.height * 0.8) {
                      cropHeight = screenSize.height * 0.8;
                      cropWidth = cropHeight * templateAspect;
                    }
                    
                    final maxOffsetX = (scaledWidth - cropWidth) / 2;
                    final maxOffsetY = (scaledHeight - cropHeight) / 2;
                    
                    offset = Offset(
                      newOffset.dx.clamp(-maxOffsetX, maxOffsetX),
                      newOffset.dy.clamp(-maxOffsetY, maxOffsetY),
                    );
                  } else {
                    offset = newOffset;
                  }
                });
              },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 裁剪遮罩画布
class _CropOverlayPainter extends CustomPainter {
  final IdPhotoTemplate? template;
  final Size canvasSize;

  _CropOverlayPainter({
    required this.template,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (template == null) return;

    // 计算裁剪框（基于模板比例，居中显示）
    final templateAspect = template!.widthPx / template!.heightPx;

    double cropWidth = canvasSize.width * 0.8;
    double cropHeight = cropWidth / templateAspect;

    if (cropHeight > canvasSize.height * 0.8) {
      cropHeight = canvasSize.height * 0.8;
      cropWidth = cropHeight * templateAspect;
    }

    final cropRect = Rect.fromCenter(
      center: Offset(canvasSize.width / 2, canvasSize.height / 2),
      width: cropWidth,
      height: cropHeight,
    );

    // 绘制裁剪框
    final borderPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(cropRect, borderPaint);

    // 绘制辅助线（九宫格）
    final guidePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 垂直线
    canvas.drawLine(
      Offset(cropRect.left + cropRect.width / 3, cropRect.top),
      Offset(cropRect.left + cropRect.width / 3, cropRect.bottom),
      guidePaint,
    );
    canvas.drawLine(
      Offset(cropRect.left + cropRect.width * 2 / 3, cropRect.top),
      Offset(cropRect.left + cropRect.width * 2 / 3, cropRect.bottom),
      guidePaint,
    );

    // 水平线
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + cropRect.height / 3),
      Offset(cropRect.right, cropRect.top + cropRect.height / 3),
      guidePaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + cropRect.height * 2 / 3),
      Offset(cropRect.right, cropRect.top + cropRect.height * 2 / 3),
      guidePaint,
    );

    // 绘制遮罩（裁剪框外的区域变暗）
    final maskPaint = Paint()
      ..color = Colors.black.withOpacity(0.6);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, maskPaint);
  }

  @override
  bool shouldRepaint(_CropOverlayPainter oldDelegate) {
    return oldDelegate.template != template ||
        oldDelegate.canvasSize != canvasSize;
  }
}
