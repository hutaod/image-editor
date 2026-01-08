import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';

/// OpenCV 图像处理服务
/// 使用平台通道调用原生 OpenCV Inpaint 功能
class OpenCVService {
  static const MethodChannel _channel = MethodChannel('opencv_inpaint');

  /// 使用 OpenCV Inpaint 算法去除水印
  ///
  /// [imagePath] 图片文件路径
  /// [rects] 水印区域列表（相对于图片的坐标）
  /// 返回处理后的图片字节数据
  static Future<Uint8List?> removeWatermarks(
    String imagePath,
    List<Map<String, double>> rects,
  ) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await _channel.invokeMethod<Uint8List>('inpaint', {
          'imagePath': imagePath,
          'rects': rects,
        });
        return result;
      } else {
        throw UnsupportedError('OpenCV 仅支持 Android 和 iOS 平台');
      }
    } on PlatformException catch (e) {
      throw Exception('OpenCV 处理失败: ${e.message}');
    }
  }

  /// 检查 OpenCV 是否可用
  static Future<bool> isAvailable() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await _channel.invokeMethod<bool>('isAvailable');
        return result ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
