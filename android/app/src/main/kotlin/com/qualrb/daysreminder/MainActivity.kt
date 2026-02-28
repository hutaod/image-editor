package com.qualrb.daysreminder

import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "opencv_inpaint"
    // OpenCV 暂时不可用，相关功能已禁用
    // import com.qualrb.daysreminder.OpenCVInpaintHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> {
                    // OpenCV 暂时不可用，返回 false
                    result.success(false)
                }
                "inpaint" -> {
                    // OpenCV 暂时不可用，返回错误
                    result.error("OPENCV_NOT_AVAILABLE", "OpenCV 功能暂时不可用", null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
