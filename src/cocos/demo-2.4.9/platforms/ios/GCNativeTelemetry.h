#import <Foundation/Foundation.h>

@interface GCNativeTelemetry : NSObject
+ (void)boot;
+ (NSString *)invoke:(NSString *)method payload:(NSString *)payload;
+ (void)startNativeView:(NSString *)page;
+ (void)stopNativeView;
+ (void)action:(NSString *)destination;
@end
