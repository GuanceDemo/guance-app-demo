#import "GCSceneDelegate.h"
#import <QuartzCore/CAMetalLayer.h>
#include "platform/ios/IOSPlatform.h"
#include "platform/interfaces/modules/IScreen.h"

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

// A full-screen native page can rotate while the Cocos controller is covered.
// Reconcile the final scene size even if its viewWillTransition callback is skipped.
- (void)syncCocosGeometry {
    auto platform = cc::BasePlatform::getPlatform();
    if (!platform || !self.window.rootViewController) return;
    auto screen = platform->getInterface<cc::IScreen>();
    CGSize size = self.window.bounds.size;
    CGFloat scale = screen->getDevicePixelRatio();
    int width = (int)round(size.width * scale), height = (int)round(size.height * scale);
    if (width <= 0 || height <= 0) return;
    CALayer *layer = self.window.rootViewController.view.layer;
    if ([layer isKindOfClass:CAMetalLayer.class]) ((CAMetalLayer *)layer).drawableSize = CGSizeMake(width, height);
    cc::WindowEvent event;
    event.windowId = 1; event.type = cc::WindowEvent::Type::RESIZED;
    event.width = width; event.height = height;
    cc::events::WindowEvent::broadcast(event);
    cc::events::Orientation::broadcast((int)screen->getDeviceOrientation());
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
