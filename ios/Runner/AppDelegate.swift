import Flutter
import UIKit

// OpenCV Inpaint 处理类 - 使用 Objective-C++ 桥接
class OpenCVInpaintHandler {
    static func inpaint(imagePath: String, rects: [[String: Double]]) -> Data? {
        // 转换 rects 为 [[String: NSNumber]]
        let nsRects: [[String: NSNumber]] = rects.map { rect -> [String: NSNumber] in
            var nsRect: [String: NSNumber] = [:]
            if let x = rect["x"] { nsRect["x"] = NSNumber(value: x) }
            if let y = rect["y"] { nsRect["y"] = NSNumber(value: y) }
            if let width = rect["width"] { nsRect["width"] = NSNumber(value: width) }
            if let height = rect["height"] { nsRect["height"] = NSNumber(value: height) }
            return nsRect
        }
        
        // 调用 Objective-C++ 方法 - Swift 会自动桥接 [[String: NSNumber]] 到 NSArray
        if let resultData = OpenCVInpaintHelper.inpaint(imagePath, rects: nsRects) {
            return resultData as Data
        }
        return nil
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // 注册 OpenCV Inpaint 方法通道
    let controller = window?.rootViewController as! FlutterViewController
    let openCVChannel = FlutterMethodChannel(
      name: "opencv_inpaint",
      binaryMessenger: controller.binaryMessenger
    )
    
    openCVChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "isAvailable":
        // 检查 OpenCV 是否可用
        // OpenCV2 已通过 CocoaPods 安装，如果能编译通过则说明可用
        result(true)
      case "inpaint":
        guard let args = call.arguments as? [String: Any],
              let imagePath = args["imagePath"] as? String,
              let rects = args["rects"] as? [[String: Double]] else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "参数错误", details: nil))
          return
        }
        
        if let resultData = OpenCVInpaintHandler.inpaint(imagePath: imagePath, rects: rects) {
          result(FlutterStandardTypedData(bytes: resultData))
        } else {
          result(FlutterError(code: "INPAINT_ERROR", message: "处理失败", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    // 清除应用启动时的badge
    application.applicationIconBadgeNumber = 0
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    // 应用进入前台时清除badge
    application.applicationIconBadgeNumber = 0
  }
}
