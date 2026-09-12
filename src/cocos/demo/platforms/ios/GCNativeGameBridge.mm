#import <UIKit/UIKit.h>

@interface GCNativeGameBridge : NSObject
+ (void)show:(NSString *)payload;
+ (NSString *)consumeAction:(NSString *)unused;
+ (void)complete:(NSNumber *)request action:(NSString *)action;
@end

@interface GCNativeGameController : UIViewController
@property(nonatomic, strong) NSDictionary *payload;
@property(nonatomic, strong) UIStackView *stack;
@property(nonatomic) BOOL completed;
@end

@implementation GCNativeGameController
- (UIColor *)ink { return [UIColor colorWithRed:0.92 green:0.95 blue:1 alpha:1]; }
- (UIColor *)muted { return [UIColor colorWithRed:0.56 green:0.64 blue:0.74 alpha:1]; }
- (UIColor *)mint { return [UIColor colorWithRed:0.36 green:0.95 blue:0.77 alpha:1]; }
- (void)label:(NSString *)value size:(CGFloat)size color:(UIColor *)color {
    UILabel *label = [UILabel new]; label.text = value; label.textColor = color; label.numberOfLines = 0;
    label.font = size >= 30 ? [UIFont boldSystemFontOfSize:size] : [UIFont systemFontOfSize:size];
    [self.stack addArrangedSubview:label];
}
- (void)button:(NSString *)title action:(NSString *)action primary:(BOOL)primary {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal]; button.accessibilityIdentifier = action;
    button.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [button setTitleColor:primary ? self.view.backgroundColor : self.ink forState:UIControlStateNormal];
    button.backgroundColor = primary ? self.mint : [UIColor colorWithRed:0.10 green:0.16 blue:0.24 alpha:1];
    button.layer.cornerRadius = 14;
    [button.heightAnchor constraintEqualToConstant:54].active = YES;
    [button addTarget:self action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.stack addArrangedSubview:button];
}
- (void)tapped:(UIButton *)sender {
    if (self.completed) return; self.completed = YES;
    NSString *action = sender.accessibilityIdentifier;
    [self dismissViewControllerAnimated:NO completion:^{ [GCNativeGameBridge complete:self.payload[@"requestId"] action:action]; }];
}
- (void)viewDidLoad {
    [super viewDidLoad]; self.view.backgroundColor = [UIColor colorWithRed:0.035 green:0.067 blue:0.13 alpha:1];
    UIScrollView *scroll = [UIScrollView new]; scroll.translatesAutoresizingMaskIntoConstraints = NO; [self.view addSubview:scroll];
    self.stack = [UIStackView new]; self.stack.axis = UILayoutConstraintAxisVertical; self.stack.spacing = 15;
    self.stack.translatesAutoresizingMaskIntoConstraints = NO; [scroll addSubview:self.stack];
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor], [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:26],
        [self.stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-26],
        [self.stack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor constant:26],
        [self.stack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor constant:-26],
        [self.stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-52]]];
    BOOL results = [self.payload[@"page"] isEqual:@"results"];
    [self label:@"GUANCE  /  ARCADE" size:13 color:self.mint];
    [self label:results ? @"ROUND COMPLETE" : @"iOS NATIVE  /  GAME LOBBY" size:11 color:self.muted];
    [self label:results ? @"Nice flying." : @"Crystal Dash" size:38 color:self.ink];
    [self label:results ? @"Your Cocos round, back in a native screen." : @"A little focus. A lot of sparkle." size:16 color:self.muted];
    if (results) {
        [self label:[self.payload[@"score"] stringValue] size:64 color:self.mint];
        [self label:@"POINTS EARNED" size:12 color:self.muted];
        [self label:[NSString stringWithFormat:@"%@ gems collected · %@s played\n%@ · Best %@", self.payload[@"gems"], self.payload[@"duration"],
            [self.payload[@"reason"] isEqual:@"health"] ? @"All shields used" : @"Time completed", self.payload[@"best"]] size:16 color:self.muted];
        [self button:@"Play again" action:@"play" primary:YES];
        [self button:@"Back to lobby" action:@"lobby" primary:NO];
        [self button:@"Open SDK lab" action:@"lab" primary:NO];
    } else {
        UIView *art = [UIView new]; art.backgroundColor = [UIColor colorWithRed:0.075 green:0.13 blue:0.22 alpha:1];
        art.layer.cornerRadius = 22; [art.heightAnchor constraintEqualToConstant:165].active = YES;
        UILabel *ship = [UILabel new]; ship.text = @"✦     ▲     ✦"; ship.font = [UIFont systemFontOfSize:56]; ship.textColor = self.mint;
        ship.textAlignment = NSTextAlignmentCenter; ship.translatesAutoresizingMaskIntoConstraints = NO; [art addSubview:ship];
        [NSLayoutConstraint activateConstraints:@[[ship.centerXAnchor constraintEqualToAnchor:art.centerXAnchor], [ship.centerYAnchor constraintEqualToAnchor:art.centerYAnchor]]];
        [self.stack addArrangedSubview:art];
        [self label:@"45 SECONDS  ·  3 SHIELDS" size:12 color:self.mint];
        [self label:@"Drag to fly. Collect green gems and dodge red meteors. Build a streak for bonus points." size:16 color:self.muted];
        [self label:[NSString stringWithFormat:@"PERSONAL BEST   %@", self.payload[@"best"]] size:13 color:self.mint];
        [self button:@"Play Crystal Dash" action:@"play" primary:YES];
        [self button:@"SDK experiments" action:@"lab" primary:NO];
        [self button:@"Connection settings" action:@"settings" primary:NO];
    }
    [self label:self.payload[@"sdkStatus"] ?: @"SDK not configured" size:12 color:self.muted];
    [self label:@"NATIVE UI → COCOS GAME → NATIVE RESULTS" size:10 color:self.muted];
}
- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return UIInterfaceOrientationMaskPortrait; }
@end

static NSString *GCGameAction = @"";
@implementation GCNativeGameBridge
+ (void)complete:(NSNumber *)request action:(NSString *)action {
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"requestId": request ?: @0, @"action": action} options:0 error:nil];
    @synchronized(self) { GCGameAction = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]; }
}
+ (NSString *)consumeAction:(NSString *)unused { @synchronized(self) { NSString *action = GCGameAction; GCGameAction = @""; return action; } }
+ (void)show:(NSString *)payload {
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:[payload dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    @synchronized(self) { GCGameAction = @""; }
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = UIApplication.sharedApplication.delegate.window;
        UIViewController *host = window.rootViewController;
        if (!host || host.presentedViewController || ![data isKindOfClass:NSDictionary.class]) {
            [self complete:data[@"requestId"] action:@"unavailable"]; return;
        }
        GCNativeGameController *controller = [GCNativeGameController new]; controller.payload = data;
        controller.modalPresentationStyle = UIModalPresentationFullScreen;
        [host presentViewController:controller animated:NO completion:nil];
    });
}
@end
