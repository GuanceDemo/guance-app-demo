#import "GCSceneDelegate.h"

// The bundled engines query this deprecated application API and abort on Unknown.
// Translate it to this demo's single window scene without modifying Creator's libs.
@interface GCCocosApplication : UIApplication
@end

@implementation GCCocosApplication
- (UIInterfaceOrientation)statusBarOrientation {
    UIWindowScene *scene = self.delegate.window.windowScene;
    UIInterfaceOrientation orientation;
    if (@available(iOS 16.0, *)) orientation = scene.effectiveGeometry.interfaceOrientation;
    else orientation = scene.interfaceOrientation;
    if (orientation != UIInterfaceOrientationUnknown) return orientation;
    // Before the first scene geometry arrives, use the declared launch orientation.
    NSArray<NSString *> *supported = NSBundle.mainBundle.infoDictionary[@"UISupportedInterfaceOrientations"];
    NSString *initial = supported.firstObject;
    if ([initial isEqualToString:@"UIInterfaceOrientationLandscapeLeft"]) return UIInterfaceOrientationLandscapeLeft;
    if ([initial isEqualToString:@"UIInterfaceOrientationLandscapeRight"]) return UIInterfaceOrientationLandscapeRight;
    if ([initial isEqualToString:@"UIInterfaceOrientationPortraitUpsideDown"]) return UIInterfaceOrientationPortraitUpsideDown;
    return UIInterfaceOrientationPortrait;
}
@end

@implementation GCSceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
    if (![scene isKindOfClass:UIWindowScene.class]) return;
    id<GCSceneHost> host = (id<GCSceneHost>)UIApplication.sharedApplication.delegate;
    [host gcConnectWindowScene:(UIWindowScene *)scene];
    self.window = host.window;
}

// UIKit stops delivering these application callbacks after adopting scenes.
// Forward to Creator's existing handlers so rendering and SDK lifecycle stay in sync.
- (void)sceneWillResignActive:(UIScene *)scene {
    id<UIApplicationDelegate> host = UIApplication.sharedApplication.delegate;
    if ([host respondsToSelector:@selector(applicationWillResignActive:)])
        [host applicationWillResignActive:UIApplication.sharedApplication];
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    id<UIApplicationDelegate> host = UIApplication.sharedApplication.delegate;
    if ([host respondsToSelector:@selector(applicationDidBecomeActive:)])
        [host applicationDidBecomeActive:UIApplication.sharedApplication];
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
    id<UIApplicationDelegate> host = UIApplication.sharedApplication.delegate;
    if ([host respondsToSelector:@selector(applicationDidEnterBackground:)])
        [host applicationDidEnterBackground:UIApplication.sharedApplication];
}

- (void)sceneWillEnterForeground:(UIScene *)scene {
    id<UIApplicationDelegate> host = UIApplication.sharedApplication.delegate;
    if ([host respondsToSelector:@selector(applicationWillEnterForeground:)])
        [host applicationWillEnterForeground:UIApplication.sharedApplication];
}

- (void)sceneDidDisconnect:(UIScene *)scene {
    self.window = nil;
}

@end
