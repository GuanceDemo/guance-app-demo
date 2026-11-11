#import <UIKit/UIKit.h>

// Both Creator editions keep the engine and its window on the application delegate.
@protocol GCSceneHost <UIApplicationDelegate>
- (void)gcConnectWindowScene:(UIWindowScene *)scene;
@end

@interface GCSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, strong) UIWindow *window;
+ (UIInterfaceOrientationMask)controlsOrientationMask;
+ (void)setControlsRotation:(NSString *)enabled;
@end
