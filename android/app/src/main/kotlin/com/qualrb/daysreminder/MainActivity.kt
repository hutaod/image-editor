package com.qualrb.daysreminder

import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "opencv_inpaint"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> {
                    val isAvailable = OpenCVInpaintHandler.initialize()
                    result.success(isAvailable)
                }
                "inpaint" -> {
                    try {
                        val imagePath = call.argument<String>("imagePath")
                        val rects = call.argument<List<Map<String, Double>>>("rects")
                        
                        if (imagePath == null || rects == null) {
                            result.error("INVALID_ARGUMENT", "imagePath 或 rects 不能为空", null)
                            return@setMethodCallHandler
                        }

                        val file = java.io.File(imagePath)
                        if (!file.exists()) {
                            result.error("FILE_NOT_FOUND", "图片文件不存在: $imagePath", null)
                            return@setMethodCallHandler
                        }

                        // 确保 OpenCV 已初始化
                        if (!OpenCVInpaintHandler.initialize()) {
                            result.error("OPENCV_INIT_FAILED", "OpenCV 初始化失败", null)
                            return@setMethodCallHandler
                        }

                        val resultBytes = OpenCVInpaintHandler.inpaint(imagePath, rects)
                        result.success(resultBytes)
                    } catch (e: Exception) {
                        result.error("INPAINT_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
