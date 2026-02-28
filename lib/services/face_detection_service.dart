import 'dart:typed_data';
import 'dart:typed_data' show Uint8List;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:image/image.dart' as img;

/// 人脸检测服务（本地运行，不需要AI服务器）
class FaceDetectionService {
  static final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false, // 禁用轮廓以提高性能
      enableLandmarks: false, // 禁用关键点以提高性能
      enableClassification: false,
      enableTracking: false,
      minFaceSize: 0.15, // 提高最小人脸尺寸以减少检测时间
    ),
  );

  /// 检测图片中的人脸
  static Future<List<Face>> detectFaces(Uint8List imageBytes) async {
    try {
      // 先解码图片获取尺寸
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) return [];

      final inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: Size(decodedImage.width.toDouble(), decodedImage.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.yuv420,
          bytesPerRow: 0,
        ),
      );

      final faces = await _faceDetector.processImage(inputImage);
      return faces;
    } catch (e) {
      print('人脸检测失败: $e');
      return [];
    }
  }

  /// 从相机帧检测人脸（用于实时检测）
  static Future<List<Face>> detectFacesFromCamera(
    CameraImage cameraImage,
    InputImageRotation rotation,
  ) async {
    try {
      // 将 CameraImage 转换为 InputImage
      final inputImage = InputImage.fromBytes(
        bytes: cameraImage.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(
            cameraImage.width.toDouble(),
            cameraImage.height.toDouble(),
          ),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: cameraImage.planes[0].bytesPerRow,
        ),
      );

      final faces = await _faceDetector.processImage(inputImage);
      return faces;
    } catch (e) {
      print('实时人脸检测失败: $e');
      return [];
    }
  }

  /// 获取人脸边界框（用于绘制）
  static Rect? getFaceBoundingBox(Face face, Size imageSize) {
    return face.boundingBox;
  }

  /// 释放资源
  static Future<void> dispose() async {
    await _faceDetector.close();
  }
}
