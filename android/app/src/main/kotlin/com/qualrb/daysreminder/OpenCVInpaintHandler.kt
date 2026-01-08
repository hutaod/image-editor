package com.qualrb.daysreminder

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import org.opencv.android.OpenCVLoader
import org.opencv.android.Utils
import org.opencv.core.Mat
import org.opencv.core.Scalar
import org.opencv.imgproc.Imgproc
import java.io.ByteArrayOutputStream

object OpenCVInpaintHandler {
    private var isOpenCVInitialized = false

    fun initialize(context: Context? = null): Boolean {
        if (!isOpenCVInitialized) {
            // 尝试初始化 OpenCV
            isOpenCVInitialized = try {
                OpenCVLoader.initLocal()
            } catch (e: Exception) {
                false
            }
        }
        return isOpenCVInitialized
    }

    fun inpaint(imagePath: String, rects: List<Map<String, Double>>): ByteArray? {
        if (!initialize()) {
            throw RuntimeException("OpenCV 初始化失败")
        }

        // 读取图片
        val bitmap = BitmapFactory.decodeFile(imagePath)
        if (bitmap == null) {
            throw RuntimeException("无法读取图片: $imagePath")
        }

        // 转换为 OpenCV Mat
        val srcMat = Mat()
        Utils.bitmapToMat(bitmap, srcMat)

        // 创建 mask（水印区域标记为白色，其他区域为黑色）
        val maskMat = Mat(srcMat.size(), org.opencv.core.CvType.CV_8UC1, Scalar(0.0))
        
        // 在 mask 上标记水印区域
        for (rect in rects) {
            val x = rect["x"]?.toInt() ?: 0
            val y = rect["y"]?.toInt() ?: 0
            val width = rect["width"]?.toInt() ?: 0
            val height = rect["height"]?.toInt() ?: 0

            // 确保坐标在图片范围内
            val left = x.coerceIn(0, srcMat.cols())
            val top = y.coerceIn(0, srcMat.rows())
            val right = (x + width).coerceIn(0, srcMat.cols())
            val bottom = (y + height).coerceIn(0, srcMat.rows())

            if (right > left && bottom > top) {
                val roi = org.opencv.core.Rect(left, top, right - left, bottom - top)
                val maskRoi = maskMat.submat(roi)
                maskRoi.setTo(Scalar(255.0))
                maskRoi.release()
            }
        }

        // 使用 OpenCV Inpaint 算法修复
        val dstMat = Mat()
        // 使用 INPAINT_NS (Navier-Stokes) 算法，效果更好，减少模糊
        // inpaintRadius 从 3.0 减小到 2.0，减少模糊范围
        Imgproc.inpaint(srcMat, maskMat, dstMat, 2.0, Imgproc.INPAINT_NS)

        // 转换回 Bitmap
        val resultBitmap = Bitmap.createBitmap(dstMat.cols(), dstMat.rows(), Bitmap.Config.ARGB_8888)
        Utils.matToBitmap(dstMat, resultBitmap)

        // 转换为字节数组
        val outputStream = ByteArrayOutputStream()
        resultBitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)

        // 释放资源
        srcMat.release()
        maskMat.release()
        dstMat.release()
        bitmap.recycle()
        resultBitmap.recycle()

        return outputStream.toByteArray()
    }
}

