import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/id_photo_template.dart';
import '../services/face_detection_service.dart';
import 'id_photo_preview_page.dart';

/// 相机页面（带人脸检测和定位指导）
class IdPhotoCameraPage extends HookConsumerWidget {
  final IdPhotoTemplate template;

  const IdPhotoCameraPage({
    super.key,
    required this.template,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraController = useState<CameraController?>(null);
    final isInitialized = useState(false);
    final isFrontCamera = useState(true);
    final detectedFaces = useState<List<Face>>([]);
    final isDetecting = useState(false);
    final frameCount = useState(0);
    final lastDetectionTime = useState<DateTime?>(null);

    // 实时人脸检测（优化：降低检测频率）
    void startFaceDetection(CameraController controller) {
      controller.startImageStream((CameraImage image) async {
        // 性能优化：每5帧检测一次，或每200ms检测一次
        frameCount.value = frameCount.value + 1;
        final now = DateTime.now();
        final shouldDetect = frameCount.value % 5 == 0 || 
            (lastDetectionTime.value == null || 
             now.difference(lastDetectionTime.value!).inMilliseconds > 200);
        
        if (!shouldDetect || isDetecting.value) return;
        
        isDetecting.value = true;
        lastDetectionTime.value = now;
        
        try {
          final rotation = isFrontCamera.value 
              ? InputImageRotation.rotation270deg 
              : InputImageRotation.rotation90deg;
          
          // 使用超时避免长时间阻塞
          final faces = await FaceDetectionService.detectFacesFromCamera(
            image,
            rotation,
          ).timeout(
            const Duration(milliseconds: 100),
            onTimeout: () => <Face>[],
          );
          
          if (context.mounted) {
            detectedFaces.value = faces;
          }
        } catch (e) {
          // 忽略检测错误，避免影响相机使用
          print('人脸检测错误: $e');
        } finally {
          isDetecting.value = false;
        }
      });
    }

    Future<void> initializeCamera(bool front) async {
      try {
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('未找到可用相机')),
            );
          }
          return;
        }

        final camera = front
            ? cameras.firstWhere(
                (c) => c.lensDirection == CameraLensDirection.front,
                orElse: () => cameras.first,
              )
            : cameras.firstWhere(
                (c) => c.lensDirection == CameraLensDirection.back,
                orElse: () => cameras.first,
              );

        // 使用中等分辨率以提高性能（实时检测不需要太高分辨率）
        final controller = CameraController(
          camera,
          ResolutionPreset.medium, // 从 high 改为 medium 以提高性能
          enableAudio: false,
        );

        await controller.initialize();
        if (context.mounted) {
          cameraController.value = controller;
          isInitialized.value = true;
          
          // 暂时禁用实时人脸检测以避免卡死
          // TODO: 优化后再启用
          // startFaceDetection(controller);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('相机初始化失败: $e')),
          );
        }
      }
    }

    useEffect(() {
      initializeCamera(isFrontCamera.value);
      return () {
        cameraController.value?.stopImageStream();
        cameraController.value?.dispose();
      };
    }, []);

    Future<void> _takePicture() async {
      if (cameraController.value == null || !isInitialized.value) return;

      try {
        final image = await cameraController.value!.takePicture();
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => IdPhotoPreviewPage(
                imagePath: image.path,
                template: template,
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('拍照失败: $e')),
          );
        }
      }
    }

    Future<void> _switchCamera() async {
      isFrontCamera.value = !isFrontCamera.value;
      await cameraController.value?.dispose();
      await initializeCamera(isFrontCamera.value);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('相机'),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // TODO: 切换到视频模式
            },
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              // TODO: 设置
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 相机预览
          if (isInitialized.value && cameraController.value != null)
            CameraPreview(cameraController.value!)
          else
            const Center(child: CircularProgressIndicator()),

          // 提示信息
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '站在纯色背景前，拍摄效果最佳',
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // 显示固定指导框（暂时禁用实时检测以避免卡死）
            Center(
              child: Container(
                width: 200,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.5),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    // 眼睛水平线
                    Positioned(
                      top: 100,
                      left: 0,
                      right: 0,
                      child: CustomPaint(
                        size: Size(200, 1),
                        painter: DashedLinePainter(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 底部控制栏
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 切换摄像头按钮
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios, size: 32),
                        color: Colors.white,
                        onPressed: _switchCamera,
                      ),
                      const Text(
                        '切换',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                  // 拍照按钮
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.transparent,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // 占位（保持对称）
                  const SizedBox(width: 70),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 虚线绘制器
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange.withOpacity(0.5)
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
