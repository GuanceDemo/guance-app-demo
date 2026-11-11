#import "GCSceneDelegate.h"
#include "platform/CCApplication.h"
#include "platform/CCDevice.h"
#include "scripting/js-bindings/event/EventDispatcher.h"

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

static BOOL GCControlsRotationEnabled = NO;
@implementation GCSceneDelegate

+ (UIInterfaceOrientationMask)controlsOrientationMask {
    return GCControlsRotationEnabled ? (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscape) : UIInterfaceOrientationMaskPortrait;
}

+ (void)setControlsRotation:(NSString *)enabled {
    dispatch_async(dispatch_get_main_queue(), ^{
        GCControlsRotationEnabled = [enabled isEqualToString:@"true"];
        UIWindow *window = UIApplication.sharedApplication.delegate.window;
        if (@available(iOS 16.0, *)) {
            [window.rootViewController setNeedsUpdateOfSupportedInterfaceOrientations];
            UIWindowSceneGeometryPreferencesIOS *preferences = [[UIWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations:self.controlsOrientationMask];
            [window.windowScene requestGeometryUpdateWithPreferences:preferences errorHandler:^(NSError *error) { NSLog(@"Cocos orientation update: %@", error.localizedDescription); }];
        } else [UIViewController attemptRotationToDeviceOrientation];
    });
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientationsForWindowScene:(UIWindowScene *)scene {
    return GCSceneDelegate.controlsOrientationMask;
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
    if (![scene isKindOfClass:UIWindowScene.class]) return;
    id<GCSceneHost> host = (id<GCSceneHost>)UIApplication.sharedApplication.delegate;
    [host gcConnectWindowScene:(UIWindowScene *)scene];
    self.window = host.window;
}

// Creator 2 listens for the deprecated status-bar orientation notification.
// Scene geometry changes must reach its native view and JS resize callback too.
- (void)syncCocosGeometry {
    auto app = cocos2d::Application::getInstance();
    if (!app || !app->getView() || !self.window) return;
    CGSize size = self.window.bounds.size;
    CGFloat scale = self.window.screen.scale;
    int width = (int)round(size.width * scale), height = (int)round(size.height * scale);
    if (width <= 0 || height <= 0) return;
    const auto &previous = app->getViewSize();
    if (previous.x == width && previous.y == height) return;
    cocos2d::EventDispatcher::dispatchOrientationChangeEvent((int)cocos2d::Device::getDeviceRotation());
    app->updateViewSize(width, height);
}

- (void)windowScene:(UIWindowScene *)scene didUpdateEffectiveGeometry:(UIWindowSceneGeometry *)previousGeometry {
    [self syncCocosGeometry];
}

- (void)windowScene:(UIWindowScene *)scene didUpdateCoordinateSpace:(id<UICoordinateSpace>)previousSpace interfaceOrientation:(UIInterfaceOrientation)previousOrientation traitCollection:(UITraitCollection *)previousTraits {
    [self syncCocosGeometry];
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
