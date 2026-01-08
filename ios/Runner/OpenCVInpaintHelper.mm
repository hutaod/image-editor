#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/imgproc/imgproc.hpp>
#import <UIKit/UIKit.h>
#import "OpenCVInpaintHelper.h"

@implementation OpenCVInpaintHelper

+ (NSData* _Nullable)inpaint:(NSString*)imagePath rects:(NSArray<NSDictionary<NSString*, NSNumber*>*>*)rects {
    @try {
        // 读取图片
        UIImage* image = [UIImage imageWithContentsOfFile:imagePath];
        if (!image) {
            NSLog(@"OpenCVInpaintHelper: 无法读取图片: %@", imagePath);
            return nil;
        }
        
        // 转换为 OpenCV Mat
        cv::Mat srcMat;
        UIImageToMat(image, srcMat);
        
        // 验证 Mat 是否有效
        if (srcMat.empty() || srcMat.rows <= 0 || srcMat.cols <= 0) {
            NSLog(@"OpenCVInpaintHelper: Mat 对象无效 (rows=%d, cols=%d)", srcMat.rows, srcMat.cols);
            return nil;
        }
        
        // 确保是 3 通道或 4 通道图片（BGR 或 BGRA）
        cv::Mat srcMatBGR;
        if (srcMat.channels() == 1) {
            // 灰度图转换为 BGR
            cv::cvtColor(srcMat, srcMatBGR, cv::COLOR_GRAY2BGR);
        } else if (srcMat.channels() == 3) {
            srcMatBGR = srcMat.clone();
        } else if (srcMat.channels() == 4) {
            // BGRA 转换为 BGR
            cv::cvtColor(srcMat, srcMatBGR, cv::COLOR_BGRA2BGR);
        } else {
            NSLog(@"OpenCVInpaintHelper: 不支持的图片通道数: %d", srcMat.channels());
            return nil;
        }
        
        // 创建 mask（水印区域标记为白色，其他区域为黑色）
        cv::Mat maskMat = cv::Mat::zeros(srcMatBGR.rows, srcMatBGR.cols, CV_8UC1);
        
        // 在 mask 上标记水印区域
        BOOL hasValidRect = NO;
        for (NSDictionary* rect in rects) {
            NSNumber* xNum = rect[@"x"];
            NSNumber* yNum = rect[@"y"];
            NSNumber* widthNum = rect[@"width"];
            NSNumber* heightNum = rect[@"height"];
            
            if (!xNum || !yNum || !widthNum || !heightNum) {
                continue;
            }
            
            double x = [xNum doubleValue];
            double y = [yNum doubleValue];
            double width = [widthNum doubleValue];
            double height = [heightNum doubleValue];
            
            // 验证数值有效性
            if (isnan(x) || isnan(y) || isnan(width) || isnan(height) ||
                isinf(x) || isinf(y) || isinf(width) || isinf(height)) {
                NSLog(@"OpenCVInpaintHelper: 无效的坐标值 (x=%.2f, y=%.2f, w=%.2f, h=%.2f)", x, y, width, height);
                continue;
            }
            
            int left = (int)floor(x);
            int top = (int)floor(y);
            int right = (int)ceil(x + width);
            int bottom = (int)ceil(y + height);
            
            // 确保坐标在范围内
            left = MAX(0, MIN(left, srcMatBGR.cols - 1));
            top = MAX(0, MIN(top, srcMatBGR.rows - 1));
            right = MAX(1, MIN(right, srcMatBGR.cols));
            bottom = MAX(1, MIN(bottom, srcMatBGR.rows));
            
            if (right > left && bottom > top) {
                int rectWidth = right - left;
                int rectHeight = bottom - top;
                
                // 再次验证矩形尺寸
                if (rectWidth > 0 && rectHeight > 0 && 
                    left >= 0 && top >= 0 && 
                    right <= srcMatBGR.cols && bottom <= srcMatBGR.rows) {
                    cv::Rect roi(left, top, rectWidth, rectHeight);
                    cv::Mat maskRoi = maskMat(roi);
                    maskRoi.setTo(cv::Scalar(255));
                    hasValidRect = YES;
                }
            }
        }
        
        // 如果没有有效的矩形，返回 nil
        if (!hasValidRect) {
            NSLog(@"OpenCVInpaintHelper: 没有有效的水印区域");
            return nil;
        }
        
        // 验证 mask 和 srcMat 尺寸一致
        if (maskMat.rows != srcMatBGR.rows || maskMat.cols != srcMatBGR.cols) {
            NSLog(@"OpenCVInpaintHelper: mask 和图片尺寸不匹配 (mask: %dx%d, image: %dx%d)", 
                  maskMat.cols, maskMat.rows, srcMatBGR.cols, srcMatBGR.rows);
            return nil;
        }
        
        // 使用 OpenCV Inpaint 算法修复
        cv::Mat dstMat;
        // 使用 INPAINT_NS (Navier-Stokes) 算法，效果更好，减少模糊
        // inpaintRadius 从 3.0 减小到 2.0，减少模糊范围
        cv::inpaint(srcMatBGR, maskMat, dstMat, 2.0, cv::INPAINT_NS);
        
        // 验证结果
        if (dstMat.empty() || dstMat.rows <= 0 || dstMat.cols <= 0) {
            NSLog(@"OpenCVInpaintHelper: inpaint 结果无效");
            return nil;
        }
        
        // 转换回 UIImage
        UIImage* resultImage = MatToUIImage(dstMat);
        if (!resultImage) {
            NSLog(@"OpenCVInpaintHelper: 无法将 Mat 转换为 UIImage");
            return nil;
        }
        
        // 转换为 PNG 数据
        NSData* resultData = UIImagePNGRepresentation(resultImage);
        if (!resultData || resultData.length == 0) {
            NSLog(@"OpenCVInpaintHelper: 无法生成 PNG 数据");
            return nil;
        }
        
        return resultData;
    } @catch (NSException* exception) {
        NSLog(@"OpenCVInpaintHelper: 异常: %@", exception.reason);
        return nil;
    }
}

@end

