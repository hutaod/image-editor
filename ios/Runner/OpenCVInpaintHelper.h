#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Objective-C 接口，供 Swift 调用
@interface OpenCVInpaintHelper : NSObject

+ (NSData* _Nullable)inpaint:(NSString*)imagePath rects:(NSArray<NSDictionary<NSString*, NSNumber*>*>*)rects;

@end

NS_ASSUME_NONNULL_END

