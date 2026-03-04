import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:exif/exif.dart';
import '../models/edit_params.dart';
import 'face_detection_service.dart';

/// 图片处理服务
class ImageService {
  /// 修正 EXIF 方向
  static Future<Uint8List> fixOrientation(Uint8List imageBytes) async {
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return imageBytes;

    // 读取 EXIF 数据
    final exifData = await readExifFromBytes(imageBytes);
    final orientation = exifData['Image Orientation']?.printable;

    img.Image? fixedImage = originalImage;

    // 根据 EXIF 方向修正图片
    switch (orientation) {
      case 'Rotated 90° CCW':
        fixedImage = img.copyRotate(originalImage, angle: -90);
        break;
      case 'Rotated 90° CW':
        fixedImage = img.copyRotate(originalImage, angle: 90);
        break;
      case 'Rotated 180°':
        fixedImage = img.copyRotate(originalImage, angle: 180);
        break;
      case 'Mirrored horizontal':
        fixedImage = img.flipHorizontal(originalImage);
        break;
      case 'Mirrored vertical':
        fixedImage = img.flipVertical(originalImage);
        break;
      default:
        fixedImage = originalImage;
    }

    return Uint8List.fromList(img.encodeJpg(fixedImage, quality: 95));
  }

  /// 压缩图片
  static Future<Uint8List> compressImage(
    Uint8List imageBytes, {
    int maxWidth = 2000,
    int maxHeight = 2000,
    int quality = 85,
  }) async {
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return imageBytes;

    img.Image resized = originalImage;

    // 如果图片太大，先缩放
    if (originalImage.width > maxWidth || originalImage.height > maxHeight) {
      resized = img.copyResize(
        originalImage,
        width: originalImage.width > maxWidth ? maxWidth : null,
        height: originalImage.height > maxHeight ? maxHeight : null,
        maintainAspect: true,
      );
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
  }

  /// 裁剪图片
  static Future<Uint8List> cropImage(
    Uint8List imageBytes,
    int x,
    int y,
    int width,
    int height,
  ) async {
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return imageBytes;

    final cropped = img.copyCrop(
      originalImage,
      x: x,
      y: y,
      width: width,
      height: height,
    );

    return Uint8List.fromList(img.encodeJpg(cropped, quality: 95));
  }

  /// 调整图片尺寸
  static Future<Uint8List> resizeImage(
    Uint8List imageBytes,
    int targetWidth,
    int targetHeight, {
    bool maintainAspect = false,
  }) async {
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return imageBytes;

    img.Image resized;
    if (maintainAspect) {
      resized = img.copyResize(
        originalImage,
        width: targetWidth,
        height: targetHeight,
        maintainAspect: true,
      );
    } else {
      resized = img.copyResize(
        originalImage,
        width: targetWidth,
        height: targetHeight,
      );
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: 95));
  }

  /// 检测是否为肤色（基于RGB和HSV颜色空间）
  static bool isSkinColor(int r, int g, int b) {
    // 归一化RGB值
    final rNorm = r / 255.0;
    final gNorm = g / 255.0;
    final bNorm = b / 255.0;
    
    // RGB肤色检测规则（适用于多种肤色）
    // 规则1: R > G > B 且差值合理
    if (rNorm > gNorm && gNorm > bNorm) {
      final rgDiff = rNorm - gNorm;
      final gbDiff = gNorm - bNorm;
      if (rgDiff > 0.01 && gbDiff > 0.01 && rgDiff < 0.3 && gbDiff < 0.3) {
        return true;
      }
    }
    
    // 规则2: R和G都明显大于B（适用于较浅肤色）
    if (rNorm > 0.4 && gNorm > 0.4 && bNorm < rNorm * 0.8 && bNorm < gNorm * 0.8) {
      if ((rNorm - bNorm) > 0.05 && (gNorm - bNorm) > 0.05) {
        return true;
      }
    }
    
    // HSV肤色检测
    final hsv = rgbToHsv(r, g, b);
    final h = hsv[0];
    final s = hsv[1];
    final v = hsv[2];
    
    // 色相范围：0-50度（红色到黄色）和 330-360度（红色）
    final isHueInRange = (h >= 0 && h <= 50) || (h >= 330 && h <= 360);
    
    // 饱和度范围：0.2-0.9（避免太灰或太鲜艳）
    final isSaturationInRange = s >= 0.2 && s <= 0.9;
    
    // 明度范围：0.2-0.95（避免太暗或太亮）
    final isValueInRange = v >= 0.2 && v <= 0.95;
    
    if (isHueInRange && isSaturationInRange && isValueInRange) {
      return true;
    }
    
    return false;
  }

  /// RGB转HSV
  static List<double> rgbToHsv(int r, int g, int b) {
    r = r.clamp(0, 255);
    g = g.clamp(0, 255);
    b = b.clamp(0, 255);
    
    final rNorm = r / 255.0;
    final gNorm = g / 255.0;
    final bNorm = b / 255.0;
    
    double max = rNorm;
    if (gNorm > max) max = gNorm;
    if (bNorm > max) max = bNorm;
    
    double min = rNorm;
    if (gNorm < min) min = gNorm;
    if (bNorm < min) min = bNorm;
    
    final delta = max - min;
    
    double h = 0;
    if (delta != 0) {
      if (max == rNorm) {
        h = 60 * (((gNorm - bNorm) / delta) % 6);
      } else if (max == gNorm) {
        h = 60 * ((bNorm - rNorm) / delta + 2);
      } else {
        h = 60 * ((rNorm - gNorm) / delta + 4);
      }
    }
    if (h < 0) h += 360;
    
    final s = max == 0 ? 0.0 : delta / max;
    final v = max;
    
    return [h, s, v];
  }

  /// 替换背景颜色（改进版：使用HSV颜色空间和更智能的背景检测）
  static Future<Uint8List> replaceBackground(
    Uint8List imageBytes,
    int targetColor, // ARGB 格式
    double tolerance, {
    List<EraseRegion>? manualErase,
  }) async {
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return imageBytes;

    // 改进的背景颜色检测：从边缘区域采样，使用HSV颜色空间
    final edgeSamples = <List<int>>[];
    final edgeWidth = (originalImage.width * 0.1).round().clamp(10, 50);
    final edgeHeight = (originalImage.height * 0.1).round().clamp(10, 50);

    // 从四个边缘区域采样
    for (int y = 0; y < edgeHeight; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        final pixel = originalImage.getPixel(x, y);
        edgeSamples.add([pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]);
      }
    }
    for (int y = originalImage.height - edgeHeight; y < originalImage.height; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        final pixel = originalImage.getPixel(x, y);
        edgeSamples.add([pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]);
      }
    }
    for (int y = edgeHeight; y < originalImage.height - edgeHeight; y++) {
      for (int x = 0; x < edgeWidth; x++) {
        final pixel = originalImage.getPixel(x, y);
        edgeSamples.add([pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]);
      }
      for (int x = originalImage.width - edgeWidth; x < originalImage.width; x++) {
        final pixel = originalImage.getPixel(x, y);
        edgeSamples.add([pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]);
      }
    }

    // 计算背景颜色的HSV值（使用众数或平均值）
    double avgH = 0, avgS = 0, avgV = 0;
    for (final sample in edgeSamples) {
      final hsv = rgbToHsv(sample[0], sample[1], sample[2]);
      avgH += hsv[0];
      avgS += hsv[1];
      avgV += hsv[2];
    }
    if (edgeSamples.isNotEmpty) {
      avgH /= edgeSamples.length;
      avgS /= edgeSamples.length;
      avgV /= edgeSamples.length;
    }

    // 目标颜色
    final targetR = (targetColor >> 16) & 0xFF;
    final targetG = (targetColor >> 8) & 0xFF;
    final targetB = targetColor & 0xFF;
    final newColor = img.ColorRgb8(targetR, targetG, targetB);

    // 使用HSV颜色空间计算相似度，对纯色背景更准确
    final hTolerance = tolerance * 60.0; // 色相容差
    final svTolerance = tolerance * 0.5; // 饱和度和明度容差

    // 第一步：标记哪些像素是背景
    final isBackground = List.generate(
      originalImage.height,
      (_) => List<bool>.filled(originalImage.width, false),
    );

    // 直接遍历所有像素，标记背景像素
    for (int y = 0; y < originalImage.height; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        final pixel = originalImage.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // 检查是否在手动擦除区域内
        bool shouldErase = false;
        if (manualErase != null) {
          for (final region in manualErase) {
            final dx = x - region.x;
            final dy = y - region.y;
            final distance = (dx * dx + dy * dy);
            if (distance <= region.radius * region.radius) {
              shouldErase = true;
              break;
            }
          }
        }

        if (shouldErase) {
          isBackground[y][x] = true;
          continue;
        }

        // 保护中心区域（假设人物在中心，避免误替换皮肤）
        // 使用渐变保护，边缘区域保护较弱，中心区域保护较强
        final centerX = originalImage.width ~/ 2;
        final centerY = originalImage.height ~/ 2;
        final maxProtectRadius = (originalImage.width * 0.35).round(); // 最大保护半径35%
        final dx = x - centerX;
        final dy = y - centerY;
        final distToCenter = (dx * dx + dy * dy).toDouble();
        final maxDist = maxProtectRadius * maxProtectRadius;
        
        // 计算保护强度（0-1，距离中心越近保护越强）
        double protectStrength = 0.0;
        if (distToCenter < maxDist) {
          protectStrength = 1.0 - (distToCenter / maxDist); // 从中心到边缘，保护强度从1降到0
        }
        
        // 边缘区域（距离边缘10%以内）降低保护强度，允许替换边缘背景
        final edgeThreshold = (originalImage.width * 0.1).round();
        final isNearEdge = x < edgeThreshold || 
                          x > originalImage.width - edgeThreshold ||
                          y < edgeThreshold || 
                          y > originalImage.height - edgeThreshold;
        
        if (isNearEdge) {
          protectStrength *= 0.3; // 边缘区域保护强度降低到30%
        }
        
        // 使用HSV颜色空间计算相似度
        final pixelHsv = rgbToHsv(r, g, b);
        final h = pixelHsv[0];
        final s = pixelHsv[1];
        final v = pixelHsv[2];

        // 计算色相差异（考虑色相是循环的）
        double hDiff = (h - avgH).abs();
        if (hDiff > 180) hDiff = 360 - hDiff;
        
        final sDiff = (s - avgS).abs();
        final vDiff = (v - avgV).abs();

        // 根据保护强度动态调整容差
        // protectStrength 越高，容差越严格
        final effectiveHTolerance = hTolerance * (1.0 - protectStrength * 0.6); // 中心区域容差降低到40%
        final effectiveSVTolerance = svTolerance * (1.0 - protectStrength * 0.7); // 中心区域容差降低到30%

        // 如果HSV值都在容差范围内，则认为是背景
        if (hDiff <= effectiveHTolerance && sDiff <= effectiveSVTolerance && vDiff <= effectiveSVTolerance) {
          // 在保护区域内，还需要额外的RGB检查
          if (protectStrength > 0.5) {
            final dr = (r - edgeSamples[0][0]).toDouble();
            final dg = (g - edgeSamples[0][1]).toDouble();
            final db = (b - edgeSamples[0][2]).toDouble();
            final rgbDistance = dr * dr + dg * dg + db * db;
            final strictRgbTolerance = (tolerance * 255.0) * (tolerance * 255.0) * (0.3 + protectStrength * 0.4); // 根据保护强度调整
            
            // 只有在RGB距离也很小时才认为是背景
            if (rgbDistance <= strictRgbTolerance) {
              isBackground[y][x] = true;
            }
          } else {
            isBackground[y][x] = true;
          }
        } else {
          // 也使用RGB欧氏距离作为备用判断（容差更大）
          final dr = (r - edgeSamples[0][0]).toDouble();
          final dg = (g - edgeSamples[0][1]).toDouble();
          final db = (b - edgeSamples[0][2]).toDouble();
          final rgbDistance = dr * dr + dg * dg + db * db;
          final rgbTolerance = (tolerance * 255.0) * (tolerance * 255.0) * 2.0; // 更大的容差
          
          // 在保护区域内，RGB容差也要更严格
          final effectiveRgbTolerance = rgbTolerance * (1.0 - protectStrength * 0.7);
          
          if (rgbDistance <= effectiveRgbTolerance) {
            isBackground[y][x] = true;
          }
        }
      }
    }

    // 第二步：形态学操作 - 先腐蚀前景，再膨胀，以清理边缘残留
    final isBackgroundRefined = List.generate(
      originalImage.height,
      (_) => List<bool>.filled(originalImage.width, false),
    );
    
    // 复制背景标记
    for (int y = 0; y < originalImage.height; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        isBackgroundRefined[y][x] = isBackground[y][x];
      }
    }
    
    // 腐蚀操作：如果前景像素周围有太多背景像素，将其标记为背景（清理边缘残留）
    const erosionRadius = 2;
    for (int y = 0; y < originalImage.height; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        if (!isBackground[y][x]) {
          // 前景像素：检查周围背景像素数量
          int backgroundNeighbors = 0;
          int totalNeighbors = 0;
          for (int dy = -erosionRadius; dy <= erosionRadius; dy++) {
            for (int dx = -erosionRadius; dx <= erosionRadius; dx++) {
              final nx = x + dx;
              final ny = y + dy;
              if (nx >= 0 && nx < originalImage.width && 
                  ny >= 0 && ny < originalImage.height) {
                totalNeighbors++;
                if (isBackground[ny][nx]) {
                  backgroundNeighbors++;
                }
              }
            }
          }
          // 如果周围超过60%是背景，可能是边缘残留，标记为背景
          if (totalNeighbors > 0 && backgroundNeighbors / totalNeighbors > 0.6) {
            isBackgroundRefined[y][x] = true;
          }
        }
      }
    }
    
    // 膨胀操作：如果背景像素周围有太多前景像素，保持为前景（保护边缘）
    const dilationRadius = 1;
    for (int y = 0; y < originalImage.height; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        if (isBackgroundRefined[y][x]) {
          // 背景像素：检查周围前景像素数量
          int foregroundNeighbors = 0;
          int totalNeighbors = 0;
          for (int dy = -dilationRadius; dy <= dilationRadius; dy++) {
            for (int dx = -dilationRadius; dx <= dilationRadius; dx++) {
              final nx = x + dx;
              final ny = y + dy;
              if (nx >= 0 && nx < originalImage.width && 
                  ny >= 0 && ny < originalImage.height) {
                totalNeighbors++;
                if (!isBackgroundRefined[ny][nx]) {
                  foregroundNeighbors++;
                }
              }
            }
          }
          // 如果周围超过50%是前景，可能是重要边缘，保持为前景
          if (totalNeighbors > 0 && foregroundNeighbors / totalNeighbors > 0.5) {
            isBackgroundRefined[y][x] = false;
          }
        }
      }
    }

    // 第三步：边缘平滑处理（多遍处理，逐步平滑）
    const edgeSmoothRadius = 4; // 增大平滑半径
    
    // 第一遍：识别边缘并应用基础平滑
    final edgeMap = List.generate(
      originalImage.height,
      (_) => List<bool>.filled(originalImage.width, false),
    );
    
    for (int y = 0; y < originalImage.height; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        // 检查是否是边缘像素
        bool isEdge = false;
        if (isBackgroundRefined[y][x]) {
          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              if (dx == 0 && dy == 0) continue;
              final nx = x + dx;
              final ny = y + dy;
              if (nx >= 0 && nx < originalImage.width && 
                  ny >= 0 && ny < originalImage.height) {
                if (!isBackgroundRefined[ny][nx]) {
                  isEdge = true;
                  break;
                }
              }
            }
            if (isEdge) break;
          }
        } else {
          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              if (dx == 0 && dy == 0) continue;
              final nx = x + dx;
              final ny = y + dy;
              if (nx >= 0 && nx < originalImage.width && 
                  ny >= 0 && ny < originalImage.height) {
                if (isBackgroundRefined[ny][nx]) {
                  isEdge = true;
                  break;
                }
              }
            }
            if (isEdge) break;
          }
        }
        edgeMap[y][x] = isEdge;
      }
    }
    
    // 第二遍：对边缘像素进行多遍平滑处理
    for (int pass = 0; pass < 2; pass++) {
      for (int y = 0; y < originalImage.height; y++) {
        for (int x = 0; x < originalImage.width; x++) {
          if (!edgeMap[y][x]) {
            if (isBackgroundRefined[y][x]) {
              originalImage.setPixel(x, y, newColor);
            }
            continue;
          }

          // 边缘像素：计算混合颜色（使用加权平均，距离越近权重越大）
          int foregroundR = 0, foregroundG = 0, foregroundB = 0;
          double foregroundWeight = 0;

          // 在边缘平滑半径内采样前景像素，使用高斯权重
          for (int dy = -edgeSmoothRadius; dy <= edgeSmoothRadius; dy++) {
            for (int dx = -edgeSmoothRadius; dx <= edgeSmoothRadius; dx++) {
              final nx = x + dx;
              final ny = y + dy;
              if (nx >= 0 && nx < originalImage.width && 
                  ny >= 0 && ny < originalImage.height) {
                final distance = (dx * dx + dy * dy).toDouble();
                final weight = distance == 0 ? 1.0 : 1.0 / (1.0 + distance * 0.3); // 高斯权重，更平滑
                
                if (!isBackgroundRefined[ny][nx]) {
                  final pixel = originalImage.getPixel(nx, ny);
                  foregroundR += (pixel.r.toInt() * weight).round();
                  foregroundG += (pixel.g.toInt() * weight).round();
                  foregroundB += (pixel.b.toInt() * weight).round();
                  foregroundWeight += weight;
                }
              }
            }
          }

          if (isBackgroundRefined[y][x]) {
            // 背景边缘：混合前景颜色
            if (foregroundWeight > 0) {
              final avgForegroundR = (foregroundR / foregroundWeight).round();
              final avgForegroundG = (foregroundG / foregroundWeight).round();
              final avgForegroundB = (foregroundB / foregroundWeight).round();
              
              // 根据前景权重动态调整混合比例
              final blendFactor = foregroundWeight > 5.0 ? 0.9 : 0.85; // 更多前景时更激进替换
              
              final r = (targetR * blendFactor + avgForegroundR * (1 - blendFactor)).round().clamp(0, 255);
              final g = (targetG * blendFactor + avgForegroundG * (1 - blendFactor)).round().clamp(0, 255);
              final b = (targetB * blendFactor + avgForegroundB * (1 - blendFactor)).round().clamp(0, 255);
              originalImage.setPixel(x, y, img.ColorRgb8(r, g, b));
            } else {
              originalImage.setPixel(x, y, newColor);
            }
          } else {
            // 前景边缘：保持原始颜色，轻微混合背景色以平滑过渡
            if (foregroundWeight > 0) {
              final originalPixel = originalImage.getPixel(x, y);
              final blendFactor = 0.98; // 98%原始颜色，2%背景色（更少混合，保护前景）
              final r = (originalPixel.r * blendFactor + targetR * (1 - blendFactor)).round().clamp(0, 255);
              final g = (originalPixel.g * blendFactor + targetG * (1 - blendFactor)).round().clamp(0, 255);
              final b = (originalPixel.b * blendFactor + targetB * (1 - blendFactor)).round().clamp(0, 255);
              originalImage.setPixel(x, y, img.ColorRgb8(r, g, b));
            }
          }
        }
      }
    }
    
    // 第四步：对非边缘的背景像素直接替换
    for (int y = 0; y < originalImage.height; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        if (!edgeMap[y][x] && isBackgroundRefined[y][x]) {
          originalImage.setPixel(x, y, newColor);
        }
      }
    }

    return Uint8List.fromList(img.encodeJpg(originalImage, quality: 95));
  }

  /// 基于人脸检测的自动背景替换（不需要AI服务器）
  static Future<Uint8List> replaceBackgroundWithFaceDetection(
    Uint8List imageBytes,
    int targetColor, {
    double tolerance = 0.3,
    bool protectFace = true,
  }) async {
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return imageBytes;

    // 检测人脸
    final faces = await FaceDetectionService.detectFaces(imageBytes);
    
    // 创建人脸保护遮罩（使用渐变保护，而不是硬边界）
    final faceProtection = List.generate(
      originalImage.height,
      (_) => List<double>.filled(originalImage.width, 0.0),
    );

    if (protectFace && faces.isNotEmpty) {
      // 获取最大的人脸（通常是主要人物）
      final mainFace = faces.reduce((a, b) => 
        (b.boundingBox.width * b.boundingBox.height) > 
        (a.boundingBox.width * a.boundingBox.height) ? b : a
      );

      // 扩展人脸区域（保护更多区域，包括头发和肩膀）
      final faceCenterX = mainFace.boundingBox.center.dx;
      final faceCenterY = mainFace.boundingBox.center.dy;
      final faceWidth = mainFace.boundingBox.width * 1.6; // 扩展60%（增强保护）
      final faceHeight = mainFace.boundingBox.height * 2.0; // 扩展100%（增强保护）
      final maxRadius = (faceWidth > faceHeight ? faceWidth : faceHeight) / 2;

      // 使用渐变保护：距离人脸中心越近，保护强度越高
      for (int y = 0; y < originalImage.height; y++) {
        for (int x = 0; x < originalImage.width; x++) {
          final dx = x - faceCenterX;
          final dy = y - faceCenterY;
          final distance = (dx * dx + dy * dy).toDouble();
          final normalizedDist = distance / (maxRadius * maxRadius);
          
          if (normalizedDist < 1.0) {
            // 使用平滑的衰减函数（高斯函数）
            var protection = (1.0 - normalizedDist).clamp(0.0, 1.0);
            protection = protection * protection * protection; // 三次方以大幅增强中心保护
            
            // 检测肤色，如果是肤色则进一步增强保护
            final pixel = originalImage.getPixel(x, y);
            if (isSkinColor(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt())) {
              protection = (protection * 0.3 + 0.7).clamp(0.0, 1.0); // 肤色区域至少70%保护
            }
            
            faceProtection[y][x] = protection;
          }
        }
      }
    }

    // 采样背景颜色（从图片边缘区域，排除人脸区域）
    final edgeSamples = <List<int>>[];
    final edgeWidth = (originalImage.width * 0.12).round().clamp(15, 60);
    final edgeHeight = (originalImage.height * 0.12).round().clamp(15, 60);

    // 从四个边缘区域采样
    for (int y = 0; y < edgeHeight; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        if (faceProtection[y][x] < 0.3) { // 只在非保护区域采样
          final pixel = originalImage.getPixel(x, y);
          edgeSamples.add([pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]);
        }
      }
    }
    for (int y = originalImage.height - edgeHeight; y < originalImage.height; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        if (faceProtection[y][x] < 0.3) {
          final pixel = originalImage.getPixel(x, y);
          edgeSamples.add([pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]);
        }
      }
    }
    for (int y = edgeHeight; y < originalImage.height - edgeHeight; y++) {
      for (int x = 0; x < edgeWidth; x++) {
        if (faceProtection[y][x] < 0.3) {
          final pixel = originalImage.getPixel(x, y);
          edgeSamples.add([pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]);
        }
      }
      for (int x = originalImage.width - edgeWidth; x < originalImage.width; x++) {
        if (faceProtection[y][x] < 0.3) {
          final pixel = originalImage.getPixel(x, y);
          edgeSamples.add([pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]);
        }
      }
    }

    // 计算背景颜色的HSV值
    double avgH = 0, avgS = 0, avgV = 0;
    for (final sample in edgeSamples) {
      final hsv = rgbToHsv(sample[0], sample[1], sample[2]);
      avgH += hsv[0];
      avgS += hsv[1];
      avgV += hsv[2];
    }
    if (edgeSamples.isNotEmpty) {
      avgH /= edgeSamples.length;
      avgS /= edgeSamples.length;
      avgV /= edgeSamples.length;
    }

    // 目标颜色
    final targetR = (targetColor >> 16) & 0xFF;
    final targetG = (targetColor >> 8) & 0xFF;
    final targetB = targetColor & 0xFF;
    final newColor = img.ColorRgb8(targetR, targetG, targetB);

    // 使用HSV颜色空间计算相似度
    final hTolerance = tolerance * 50.0; // 色相容差
    final svTolerance = tolerance * 0.4; // 饱和度和明度容差

    // 第一步：标记哪些像素是背景
    final isBackground = List.generate(
      originalImage.height,
      (_) => List<bool>.filled(originalImage.width, false),
    );

    for (int y = 0; y < originalImage.height; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        final pixel = originalImage.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // 根据人脸保护强度动态调整容差
        final protectStrength = faceProtection[y][x];
        
        // 检测肤色（优先检查，无论保护强度如何）
        final isSkin = isSkinColor(r, g, b);
        
        // 如果保护强度很高（>0.6），直接跳过，不标记为背景
        if (protectStrength > 0.6) {
          continue;
        }
        
        // 如果是肤色，且保护强度>0.1，直接跳过（降低阈值，更严格保护）
        if (isSkin && protectStrength > 0.1) {
          continue;
        }
        
        // 如果是肤色，即使不在保护区域内，也要更严格的检查
        if (isSkin) {
          // 肤色区域需要非常严格的匹配才认为是背景
          final dr = (r - edgeSamples[0][0]).toDouble();
          final dg = (g - edgeSamples[0][1]).toDouble();
          final db = (b - edgeSamples[0][2]).toDouble();
          final rgbDistance = dr * dr + dg * dg + db * db;
          // 非常严格的RGB容差（只有非常接近背景色才认为是背景）
          final veryStrictRgbTolerance = (tolerance * 255.0) * (tolerance * 255.0) * 0.3;
          
          if (rgbDistance > veryStrictRgbTolerance) {
            continue; // 不是背景，跳过
          }
        }
        
        final effectiveHTolerance = hTolerance * (1.0 - protectStrength * 0.95);
        final effectiveSVTolerance = svTolerance * (1.0 - protectStrength * 0.95);

        // 使用HSV颜色空间计算相似度
        final pixelHsv = rgbToHsv(r, g, b);
        final h = pixelHsv[0];
        final s = pixelHsv[1];
        final v = pixelHsv[2];

        // 计算色相差异（考虑色相是循环的）
        double hDiff = (h - avgH).abs();
        if (hDiff > 180) hDiff = 360 - hDiff;
        
        final sDiff = (s - avgS).abs();
        final vDiff = (v - avgV).abs();

        // 如果HSV值都在容差范围内，则认为是背景
        if (hDiff <= effectiveHTolerance && sDiff <= effectiveSVTolerance && vDiff <= effectiveSVTolerance) {
          // 在保护区域内，需要更严格的RGB检查
          if (protectStrength > 0.15 && edgeSamples.isNotEmpty) {
            final dr = (r - edgeSamples[0][0]).toDouble();
            final dg = (g - edgeSamples[0][1]).toDouble();
            final db = (b - edgeSamples[0][2]).toDouble();
            final rgbDistance = dr * dr + dg * dg + db * db;
            // 更严格的RGB容差
            final strictRgbTolerance = (tolerance * 255.0) * (tolerance * 255.0) * (0.1 + protectStrength * 0.2);
            
            if (rgbDistance <= strictRgbTolerance) {
              // 即使RGB匹配，如果是肤色，也要再次检查
              if (isSkin && protectStrength > 0.1) {
                continue; // 肤色区域，不标记为背景
              }
              isBackground[y][x] = true;
            }
          } else {
            // 非保护区域，也需要额外的RGB检查以确保准确性
            if (edgeSamples.isNotEmpty) {
              final dr = (r - edgeSamples[0][0]).toDouble();
              final dg = (g - edgeSamples[0][1]).toDouble();
              final db = (b - edgeSamples[0][2]).toDouble();
              final rgbDistance = dr * dr + dg * dg + db * db;
              final rgbTolerance = (tolerance * 255.0) * (tolerance * 255.0) * 1.5;
              
              if (rgbDistance <= rgbTolerance) {
                // 即使RGB匹配，如果是肤色，也要再次检查
                if (isSkin) {
                  continue; // 肤色区域，不标记为背景
                }
                isBackground[y][x] = true;
              }
            } else {
              // 如果没有采样数据，但检测到肤色，不标记为背景
              if (isSkin) {
                continue;
              }
              isBackground[y][x] = true;
            }
          }
        }
      }
    }

    // 第二步：形态学操作清理边缘
    final isBackgroundRefined = List.generate(
      originalImage.height,
      (_) => List<bool>.filled(originalImage.width, false),
    );
    
    for (int y = 0; y < originalImage.height; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        isBackgroundRefined[y][x] = isBackground[y][x];
      }
    }
    
    // 腐蚀操作：清理前景边缘残留（但保护人脸和肤色区域）
    const erosionRadius = 2;
    for (int y = 0; y < originalImage.height; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        // 如果保护强度高或检测到肤色，不进行腐蚀
        if (faceProtection[y][x] > 0.3) continue;
        
        final pixel = originalImage.getPixel(x, y);
        // 降低肤色保护阈值，更严格保护肤色
        if (isSkinColor(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()) && faceProtection[y][x] > 0.05) {
          continue;
        }
        
        if (!isBackground[y][x]) {
          int backgroundNeighbors = 0;
          int totalNeighbors = 0;
          for (int dy = -erosionRadius; dy <= erosionRadius; dy++) {
            for (int dx = -erosionRadius; dx <= erosionRadius; dx++) {
              final nx = x + dx;
              final ny = y + dy;
              if (nx >= 0 && nx < originalImage.width && 
                  ny >= 0 && ny < originalImage.height) {
                totalNeighbors++;
                if (isBackground[ny][nx]) {
                  backgroundNeighbors++;
                }
              }
            }
          }
          // 提高阈值，更激进地清理边缘残留
          if (totalNeighbors > 0 && backgroundNeighbors / totalNeighbors > 0.7) {
            // 再次检查是否为肤色，如果是则不腐蚀
            if (!isSkinColor(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()) || faceProtection[y][x] <= 0.05) {
              isBackgroundRefined[y][x] = true;
            }
          }
        }
      }
    }
    
    // 膨胀操作：保护前景边缘
    const dilationRadius = 1;
    for (int y = 0; y < originalImage.height; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        if (isBackgroundRefined[y][x] && faceProtection[y][x] > 0.3) {
          int foregroundNeighbors = 0;
          int totalNeighbors = 0;
          for (int dy = -dilationRadius; dy <= dilationRadius; dy++) {
            for (int dx = -dilationRadius; dx <= dilationRadius; dx++) {
              final nx = x + dx;
              final ny = y + dy;
              if (nx >= 0 && nx < originalImage.width && 
                  ny >= 0 && ny < originalImage.height) {
                totalNeighbors++;
                if (!isBackgroundRefined[ny][nx]) {
                  foregroundNeighbors++;
                }
              }
            }
          }
          if (totalNeighbors > 0 && foregroundNeighbors / totalNeighbors > 0.4) {
            isBackgroundRefined[y][x] = false;
          }
        }
      }
    }

    // 第三步：边缘羽化处理
    const featherRadius = 3;
    for (int y = 0; y < originalImage.height; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        // 检查是否是边缘像素
        bool isEdge = false;
        if (isBackgroundRefined[y][x]) {
          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              if (dx == 0 && dy == 0) continue;
              final nx = x + dx;
              final ny = y + dy;
              if (nx >= 0 && nx < originalImage.width && 
                  ny >= 0 && ny < originalImage.height) {
                if (!isBackgroundRefined[ny][nx]) {
                  isEdge = true;
                  break;
                }
              }
            }
            if (isEdge) break;
          }
        } else {
          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              if (dx == 0 && dy == 0) continue;
              final nx = x + dx;
              final ny = y + dy;
              if (nx >= 0 && nx < originalImage.width && 
                  ny >= 0 && ny < originalImage.height) {
                if (isBackgroundRefined[ny][nx]) {
                  isEdge = true;
                  break;
                }
              }
            }
            if (isEdge) break;
          }
        }

        if (isEdge) {
          // 边缘像素：计算混合颜色
          int foregroundR = 0, foregroundG = 0, foregroundB = 0;
          double foregroundWeight = 0;

          for (int dy = -featherRadius; dy <= featherRadius; dy++) {
            for (int dx = -featherRadius; dx <= featherRadius; dx++) {
              final nx = x + dx;
              final ny = y + dy;
              if (nx >= 0 && nx < originalImage.width && 
                  ny >= 0 && ny < originalImage.height) {
                final distance = (dx * dx + dy * dy).toDouble();
                final weight = distance == 0 ? 1.0 : 1.0 / (1.0 + distance * 0.5);
                
                if (!isBackgroundRefined[ny][nx]) {
                  final pixel = originalImage.getPixel(nx, ny);
                  foregroundR += (pixel.r.toInt() * weight).round();
                  foregroundG += (pixel.g.toInt() * weight).round();
                  foregroundB += (pixel.b.toInt() * weight).round();
                  foregroundWeight += weight;
                }
              }
            }
          }

          // 检查当前像素是否为肤色
          final currentPixel = originalImage.getPixel(x, y);
          final isCurrentSkin = isSkinColor(currentPixel.r.toInt(), currentPixel.g.toInt(), currentPixel.b.toInt());
          final currentProtectStrength = faceProtection[y][x];
          
          // 如果是肤色且保护强度较高，保持原始颜色
          if (isCurrentSkin && currentProtectStrength > 0.1) {
            // 保持原始颜色，不进行任何替换
            continue;
          }
          
          if (isBackgroundRefined[y][x]) {
            // 背景边缘：混合前景颜色
            if (foregroundWeight > 0) {
              final avgForegroundR = (foregroundR / foregroundWeight).round();
              final avgForegroundG = (foregroundG / foregroundWeight).round();
              final avgForegroundB = (foregroundB / foregroundWeight).round();
              
              // 如果当前像素是肤色，减少背景色混合比例
              final blendFactor = isCurrentSkin ? 0.85 : 0.92; // 肤色区域更少混合背景色
              final r = (targetR * blendFactor + avgForegroundR * (1 - blendFactor)).round().clamp(0, 255);
              final g = (targetG * blendFactor + avgForegroundG * (1 - blendFactor)).round().clamp(0, 255);
              final b = (targetB * blendFactor + avgForegroundB * (1 - blendFactor)).round().clamp(0, 255);
              originalImage.setPixel(x, y, img.ColorRgb8(r, g, b));
            } else {
              // 如果没有前景像素，但当前是肤色，保持原始颜色
              if (isCurrentSkin && currentProtectStrength > 0.05) {
                continue;
              }
              originalImage.setPixel(x, y, newColor);
            }
          } else {
            // 前景边缘：保持原始颜色，轻微混合背景色
            final originalPixel = originalImage.getPixel(x, y);
            // 如果是肤色，完全不混合背景色
            final blendFactor = isCurrentSkin ? 1.0 : 0.99; // 肤色区域100%保持原始颜色
            final r = (originalPixel.r * blendFactor + targetR * (1 - blendFactor)).round().clamp(0, 255);
            final g = (originalPixel.g * blendFactor + targetG * (1 - blendFactor)).round().clamp(0, 255);
            final b = (originalPixel.b * blendFactor + targetB * (1 - blendFactor)).round().clamp(0, 255);
            originalImage.setPixel(x, y, img.ColorRgb8(r, g, b));
          }
        } else {
          // 非边缘像素：直接替换（但保护肤色区域）
          if (isBackgroundRefined[y][x]) {
            // 再次检查是否为肤色，如果是则不替换
            final pixel = originalImage.getPixel(x, y);
            if (isSkinColor(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()) && faceProtection[y][x] > 0.05) {
              continue; // 保持原始颜色
            }
            originalImage.setPixel(x, y, newColor);
          }
        }
      }
    }

    return Uint8List.fromList(img.encodeJpg(originalImage, quality: 95));
  }

  /// 调整亮度
  static Future<Uint8List> adjustBrightness(
    Uint8List imageBytes,
    double brightness, // -1.0 到 1.0
  ) async {
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return imageBytes;

    final adjusted = img.adjustColor(
      originalImage,
      brightness: brightness,
    );

    return Uint8List.fromList(img.encodeJpg(adjusted, quality: 95));
  }

  /// 调整对比度
  static Future<Uint8List> adjustContrast(
    Uint8List imageBytes,
    double contrast, // -1.0 到 1.0
  ) async {
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return imageBytes;

    final adjusted = img.adjustColor(
      originalImage,
      contrast: contrast,
    );

    return Uint8List.fromList(img.encodeJpg(adjusted, quality: 95));
  }

  /// 调整饱和度
  static Future<Uint8List> adjustSaturation(
    Uint8List imageBytes,
    double saturation, // -1.0 到 1.0
  ) async {
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return imageBytes;

    final adjusted = img.adjustColor(
      originalImage,
      saturation: saturation,
    );

    return Uint8List.fromList(img.encodeJpg(adjusted, quality: 95));
  }

  /// 锐化
  static Future<Uint8List> sharpen(
    Uint8List imageBytes,
    double amount, // 0.0 到 1.0
  ) async {
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return imageBytes;

    // 使用简单的锐化算法：增强对比度来模拟锐化效果
    final adjusted = img.adjustColor(
      originalImage,
      contrast: amount * 0.5, // 通过增强对比度实现锐化效果
    );

    return Uint8List.fromList(img.encodeJpg(adjusted, quality: 95));
  }

  /// 降噪（简单的高斯模糊反处理）
  static Future<Uint8List> denoise(
    Uint8List imageBytes,
    double amount, // 0.0 到 1.0
  ) async {
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return imageBytes;

    // 轻微的高斯模糊来降噪
    final denoised = img.gaussianBlur(originalImage, radius: (amount * 2).round().clamp(1, 10));

    return Uint8List.fromList(img.encodeJpg(denoised, quality: 95));
  }

  /// 保存图片到临时目录
  static Future<String> saveToTemp(Uint8List imageBytes, String filename) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(path.join(tempDir.path, filename));
    await file.writeAsBytes(imageBytes);
    return file.path;
  }

  /// 保存图片到应用目录
  static Future<String> saveToAppDir(Uint8List imageBytes, String filename) async {
    final appDir = await getApplicationDocumentsDirectory();
    final file = File(path.join(appDir.path, filename));
    await file.writeAsBytes(imageBytes);
    return file.path;
  }

  /// 获取图片尺寸
  static Future<Size> getImageSize(Uint8List imageBytes) async {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      return const Size(0, 0);
    }
    return Size(decoded.width.toDouble(), decoded.height.toDouble());
  }
}

