#import <UIKit/UIKit.h>
#import "GCNativeTelemetry.h"

@interface GCNativeGameBridge : NSObject
+ (void)show:(NSString *)payload;
+ (NSString *)consumeAction:(NSString *)unused;
+ (void)complete:(NSNumber *)request action:(NSString *)action;
+ (void)complete:(NSNumber *)request action:(NSString *)action config:(NSDictionary *)config importText:(NSString *)importText;
@end

@interface GCNativeGameController : UIViewController
@property(nonatomic, strong) NSDictionary *payload;
@property(nonatomic, strong) UIStackView *stack;
@property(nonatomic) BOOL completed;
@property(nonatomic, strong) NSMutableDictionary *draft;
@property(nonatomic, strong) NSMutableDictionary<NSString *, UIControl *> *inputs;
@property(nonatomic, strong) NSMutableDictionary<NSString *, UIView *> *rows;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSArray *> *choices;
@property(nonatomic, strong) UITextView *importInput;
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
    if (self.completed) return;
    [self.view endEditing:YES];
    NSString *action = sender.accessibilityIdentifier;
    NSDictionary *config = [action hasPrefix:@"settings-"] ? [self collectSettings] : nil;
    NSString *importText = config ? self.importInput.text : nil;
    [GCNativeTelemetry action:action];
    self.completed = YES;
    [self dismissViewControllerAnimated:NO completion:^{
        [GCNativeGameBridge complete:self.payload[@"requestId"] action:action config:config importText:importText];
    }];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [GCNativeTelemetry startNativeView:self.payload[@"page"]];
}
- (void)viewWillDisappear:(BOOL)animated {
    [GCNativeTelemetry stopNativeView];
    [super viewWillDisappear:animated];
}
- (void)viewDidLoad {
    [super viewDidLoad]; self.view.backgroundColor = [UIColor colorWithRed:0.035 green:0.067 blue:0.13 alpha:1];
    UIScrollView *scroll = [UIScrollView new]; scroll.translatesAutoresizingMaskIntoConstraints = NO; [self.view addSubview:scroll];
    scroll.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    NSLayoutYAxisAnchor *bottom = self.view.safeAreaLayoutGuide.bottomAnchor;
    if (@available(iOS 15.0, *)) bottom = self.view.keyboardLayoutGuide.topAnchor;
    self.stack = [UIStackView new]; self.stack.axis = UILayoutConstraintAxisVertical; self.stack.spacing = 15;
    self.stack.translatesAutoresizingMaskIntoConstraints = NO; [scroll addSubview:self.stack];
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:bottom],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor], [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:26],
        [self.stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-26],
        [self.stack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor constant:26],
        [self.stack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor constant:-26],
        [self.stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-52]]];
    if ([self.payload[@"page"] isEqual:@"settings"]) { [self settings]; return; }
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
- (void)settings {
    self.draft = [self.payload[@"config"] mutableCopy];
    self.inputs = [NSMutableDictionary new]; self.rows = [NSMutableDictionary new]; self.choices = [NSMutableDictionary new];
    [self label:@"iOS NATIVE  /  SDK SETTINGS" size:12 color:self.mint];
    [self label:@"SDK settings" size:34 color:self.ink];
    [self label:@"iOS App ID is used on this device. Save changes, then close and reopen the app if the SDK is already running." size:14 color:self.muted];
    if ([self.payload[@"settingsMessage"] length]) [self label:self.payload[@"settingsMessage"] size:15 color:self.mint];
    [self label:@"Import gc-demo:// or JSON" size:14 color:self.muted];
    self.importInput = [UITextView new]; self.importInput.font = [UIFont systemFontOfSize:15];
    self.importInput.textColor = self.ink; self.importInput.backgroundColor = [UIColor colorWithWhite:1 alpha:0.06];
    self.importInput.autocorrectionType = UITextAutocorrectionTypeNo; self.importInput.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.importInput.accessibilityLabel = @"Paste shared settings";
    [self.importInput.heightAnchor constraintEqualToConstant:110].active = YES;
    [self.stack addArrangedSubview:self.importInput];
    [self button:@"Import settings" action:@"settings-import" primary:NO];
    for (NSDictionary *field in self.payload[@"fields"]) {
        NSString *key = field[@"key"], *kind = field[@"kind"];
        UIStackView *row = [UIStackView new]; row.axis = UILayoutConstraintAxisVertical; row.spacing = 8;
        UILabel *label = [UILabel new]; label.text = field[@"label"]; label.textColor = self.muted;
        label.font = [UIFont systemFontOfSize:14]; label.numberOfLines = 0; [row addArrangedSubview:label];
        UIControl *input;
        if ([kind isEqual:@"toggle"]) {
            UISwitch *toggle = [UISwitch new]; toggle.on = [self.draft[key] boolValue]; toggle.onTintColor = self.mint;
            row.alignment = UIStackViewAlignmentLeading;
            [toggle addTarget:self action:@selector(updateDependencies) forControlEvents:UIControlEventValueChanged]; input = toggle;
        } else if ([kind isEqual:@"choice"]) {
            NSArray *options = field[@"options"]; self.choices[key] = options;
            NSMutableArray *labels = [NSMutableArray new]; NSInteger selected = 0;
            for (NSDictionary *option in options) {
                if ([option[@"value"] isEqual:self.draft[key]]) selected = labels.count;
                [labels addObject:option[@"label"]];
            }
            UISegmentedControl *choice = [[UISegmentedControl alloc] initWithItems:labels];
            choice.selectedSegmentIndex = selected;
            if (@available(iOS 13.0, *)) choice.selectedSegmentTintColor = self.mint;
            [choice setTitleTextAttributes:@{NSForegroundColorAttributeName: self.ink, NSFontAttributeName: [UIFont systemFontOfSize:11]} forState:UIControlStateNormal];
            [choice setTitleTextAttributes:@{NSForegroundColorAttributeName: self.view.backgroundColor} forState:UIControlStateSelected];
            [choice.heightAnchor constraintGreaterThanOrEqualToConstant:44].active = YES;
            [choice addTarget:self action:@selector(updateDependencies) forControlEvents:UIControlEventValueChanged]; input = choice;
        } else {
            UITextField *text = [UITextField new]; text.text = self.draft[key]; text.textColor = self.ink;
            text.backgroundColor = [UIColor colorWithWhite:1 alpha:0.06]; text.layer.cornerRadius = 8;
            text.font = [UIFont systemFontOfSize:16]; text.autocorrectionType = UITextAutocorrectionTypeNo;
            text.autocapitalizationType = UITextAutocapitalizationTypeNone; text.secureTextEntry = [kind isEqual:@"secret"];
            text.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 44)]; text.leftViewMode = UITextFieldViewModeAlways;
            [text.heightAnchor constraintEqualToConstant:48].active = YES; input = text;
        }
        input.accessibilityLabel = field[@"label"]; input.accessibilityIdentifier = key;
        [row addArrangedSubview:input]; [self.stack addArrangedSubview:row]; self.inputs[key] = input; self.rows[key] = row;
    }
    [self updateDependencies];
    [self label:@"1–5 FPS controls Replay capture, not game rendering. Quality presets control resolution, compression and traffic budget. Adaptive capture may reduce the actual frame rate." size:14 color:self.muted];
    [self button:@"Check connection" action:@"settings-check" primary:NO];
    [self button:@"Save settings" action:@"settings-save" primary:YES];
    [self button:@"Cancel / Back to lobby" action:@"lobby" primary:NO];
}
- (NSDictionary *)collectSettings {
    NSMutableDictionary *result = [self.draft mutableCopy];
    for (NSString *key in self.inputs) {
        UIControl *input = self.inputs[key];
        if ([input isKindOfClass:UISwitch.class]) result[key] = @(((UISwitch *)input).on);
        else if ([input isKindOfClass:UISegmentedControl.class]) result[key] = self.choices[key][((UISegmentedControl *)input).selectedSegmentIndex][@"value"];
        else result[key] = [((UITextField *)input).text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    }
    return result;
}
- (void)updateDependencies {
    BOOL sdk = ((UISwitch *)self.inputs[@"enableSdk"]).on;
    BOOL replay = sdk && ((UISwitch *)self.inputs[@"enableSessionReplay"]).on;
    for (NSString *key in self.inputs) {
        BOOL enabled = [key isEqual:@"enableSdk"] || [key isEqual:@"demoApiAddress"] || sdk;
        if ([key isEqual:@"replayFps"] || [key isEqual:@"replayQuality"]) enabled = replay;
        self.inputs[key].enabled = enabled; self.rows[key].alpha = enabled ? 1 : 0.45;
    }
    BOOL datakit = ((UISegmentedControl *)self.inputs[@"accessType"]).selectedSegmentIndex == 0;
    self.rows[@"datakitAddress"].hidden = !datakit;
    self.rows[@"datawayAddress"].hidden = datakit; self.rows[@"datawayClientToken"].hidden = datakit;
}
- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return UIInterfaceOrientationMaskPortrait; }
@end

static NSString *GCGameAction = @"";
@implementation GCNativeGameBridge
+ (void)complete:(NSNumber *)request action:(NSString *)action {
    [self complete:request action:action config:nil importText:nil];
}
+ (void)complete:(NSNumber *)request action:(NSString *)action config:(NSDictionary *)config importText:(NSString *)importText {
    NSMutableDictionary *event = [@{@"requestId": request ?: @0, @"action": action} mutableCopy];
    if (config) event[@"config"] = config;
    if (importText) event[@"importText"] = importText;
    NSData *data = [NSJSONSerialization dataWithJSONObject:event options:0 error:nil];
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
