import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/id_photo_template.dart';
import 'image_service.dart';

/// 打印排版服务
class PrintLayoutService {
  /// 生成 4x6 英寸打印排版图片
  /// 
  /// [images] 图片数据列表
  /// [template] 尺寸模板
  /// [dpi] 打印分辨率（默认 300）
  static Future<Uint8List> generate4x6Layout({
    required List<Uint8List> images,
    required IdPhotoTemplate template,
    int dpi = 300,
  }) async {
    // 4x6 英寸 = 101.6 x 152.4 毫米
    // 转换为像素（300 DPI）
    final paperWidthPx = (6 * dpi).round(); // 6 英寸
    final paperHeightPx = (4 * dpi).round(); // 4 英寸

    // 每张证件照的像素尺寸
    final photoWidthPx = template.widthPx;
    final photoHeightPx = template.heightPx;

    // 计算可以排列多少张
    final cols = (paperWidthPx / photoWidthPx).floor();
    final rows = (paperHeightPx / photoHeightPx).floor();
    final imagesPerPage = cols * rows;

    // 创建画布
    final canvas = img.Image(width: paperWidthPx, height: paperHeightPx);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255)); // 白色背景

    int imageIndex = 0;
    int pageIndex = 0;
    final List<Uint8List> pages = [];

    while (imageIndex < images.length) {
      // 创建新页面
      final page = img.Image(width: paperWidthPx, height: paperHeightPx);
      img.fill(page, color: img.ColorRgb8(255, 255, 255));

      // 排列图片
      for (int row = 0; row < rows && imageIndex < images.length; row++) {
        for (int col = 0; col < cols && imageIndex < images.length; col++) {
          final x = col * photoWidthPx;
          final y = row * photoHeightPx;

          // 解码图片
          final photo = img.decodeImage(images[imageIndex]);
          if (photo != null) {
            // 调整图片尺寸以匹配模板
            final resized = img.copyResize(
              photo,
              width: photoWidthPx,
              height: photoHeightPx,
              interpolation: img.Interpolation.cubic,
            );

            // 绘制到画布上
            img.compositeImage(page, resized, dstX: x, dstY: y);
          }

          imageIndex++;
        }
      }

      // 添加裁剪线（可选）
      _drawCropLines(page, cols, rows, photoWidthPx, photoHeightPx);

      pages.add(Uint8List.fromList(img.encodeJpg(page, quality: 100)));
      pageIndex++;
    }

    // 如果只有一页，直接返回
    if (pages.length == 1) {
      return pages[0];
    }

    // 多页情况下，返回第一页（实际应用中可能需要返回所有页面）
    return pages[0];
  }

  /// 绘制裁剪线
  static void _drawCropLines(
    img.Image canvas,
    int cols,
    int rows,
    int photoWidth,
    int photoHeight,
  ) {
    final lineColor = img.ColorRgb8(200, 200, 200); // 浅灰色

    // 绘制垂直线
    for (int col = 1; col < cols; col++) {
      final x = col * photoWidth;
      for (int y = 0; y < canvas.height; y++) {
        if (y % 5 < 2) { // 虚线效果
          canvas.setPixel(x, y, lineColor);
        }
      }
    }

    // 绘制水平线
    for (int row = 1; row < rows; row++) {
      final y = row * photoHeight;
      for (int x = 0; x < canvas.width; x++) {
        if (x % 5 < 2) { // 虚线效果
          canvas.setPixel(x, y, lineColor);
        }
      }
    }
  }

  /// 计算打印排版需要的张数
  static int calculatePrintCount(int totalPhotos, IdPhotoTemplate template) {
    // 4x6 英寸纸张
    final paperWidthPx = 6 * 300; // 6 英寸 @ 300 DPI
    final paperHeightPx = 4 * 300; // 4 英寸 @ 300 DPI

    final cols = (paperWidthPx / template.widthPx).floor();
    final rows = (paperHeightPx / template.heightPx).floor();
    final imagesPerPage = cols * rows;

    return (totalPhotos / imagesPerPage).ceil();
  }
}
