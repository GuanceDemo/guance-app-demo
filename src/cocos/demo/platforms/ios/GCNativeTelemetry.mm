#import "GCNativeTelemetry.h"
#import "FTMobileAgent.h"
#import "FTSDKConfig.h"
#import "FTRumConfig.h"
#import "FTLoggerConfig.h"
#import "FTMobileConfig.h"
#import "FTExternalDataManager.h"
#import "FTSessionReplayConfig.h"
#import "FTRumSessionReplay.h"

static NSString *const GCSettingsKey = @"gc_demo_hybrid_settings";
static BOOL GCStarted = NO, GCStopped = NO, GCNativeView = NO;

@implementation GCNativeTelemetry
+ (NSDictionary *)parse:(NSString *)payload {
    id value = [NSJSONSerialization JSONObjectWithData:[payload dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    if (![value isKindOfClass:NSDictionary.class]) [NSException raise:@"GCSettings" format:@"Invalid settings"];
    return value;
}
+ (BOOL)flag:(NSDictionary *)config key:(NSString *)key fallback:(BOOL)fallback {
    return config[key] ? [config[key] boolValue] : fallback;
}
+ (void)boot {
    NSString *saved = [NSUserDefaults.standardUserDefaults stringForKey:GCSettingsKey];
    if (saved.length) @try { [self initializeHost:[self parse:saved]]; }
    @catch (NSException *exception) { /* Keep settings available. Never log credentials. */ }
}
+ (NSString *)invoke:(NSString *)method payload:(NSString *)payload {
    if (!NSThread.isMainThread) {
        __block NSString *result;
        dispatch_sync(dispatch_get_main_queue(), ^{ result = [self invoke:method payload:payload]; });
        return result;
    }
    @try {
        NSMutableDictionary *response = [@{@"ok": @YES} mutableCopy];
        if ([method isEqual:@"read"]) response[@"value"] = [NSUserDefaults.standardUserDefaults stringForKey:GCSettingsKey] ?: @"";
        else if ([method isEqual:@"save"]) {
            [self parse:payload];
            [NSUserDefaults.standardUserDefaults setObject:payload forKey:GCSettingsKey];
        } else if ([method isEqual:@"initialize"]) {
            [self initializeHost:[self parse:payload]];
            if (!GCStarted) [NSException raise:@"GCSettings" format:@"Native SDK is disabled"];
            if (![NSUserDefaults.standardUserDefaults stringForKey:GCSettingsKey].length)
                [NSUserDefaults.standardUserDefaults setObject:payload forKey:GCSettingsKey];
        } else if ([method isEqual:@"disable"]) {
            if (GCStarted) { [self stopNativeView]; [FTMobileAgent shutDown]; GCStarted = NO; GCStopped = YES; }
            response[@"value"] = @(GCStopped);
        } else [NSException raise:@"GCSettings" format:@"Unknown host operation"];
        return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:response options:0 error:nil] encoding:NSUTF8StringEncoding];
    } @catch (NSException *exception) {
        return @"{\"ok\":false,\"error\":\"Native SDK setup failed. Check settings and restart the app.\"}";
    }
}
+ (void)initializeHost:(NSDictionary *)settings {
    if (GCStarted || ![self flag:settings key:@"enableSdk" fallback:YES]) return;
    if (GCStopped) [NSException raise:@"GCSettings" format:@"Restart before reinitializing the SDK"];
    NSString *appID = settings[@"demoIOSAppId"];
    if (!appID.length) [NSException raise:@"GCSettings" format:@"iOS App ID is required"];
    FTSDKConfig *config;
    if ([settings[@"accessType"] isEqual:@"datakit"]) {
        if (![settings[@"datakitAddress"] length]) [NSException raise:@"GCSettings" format:@"DataKit URL is required"];
        config = [[FTSDKConfig alloc] initWithDatakitUrl:settings[@"datakitAddress"]];
    } else {
        if (![settings[@"datawayAddress"] length] || ![settings[@"datawayClientToken"] length])
            [NSException raise:@"GCSettings" format:@"DataWay settings are required"];
        config = [[FTSDKConfig alloc] initWithDatawayUrl:settings[@"datawayAddress"] clientToken:settings[@"datawayClientToken"]];
    }
    config.enableSDKDebugLog = [self flag:settings key:@"debug" fallback:NO];
    config.service = @"guance_cocos_demo"; config.env = @"common";
    config.globalContext = @{@"demo_platform": @"ios", @"demo_framework": @"cocos", @"demo_version": @"1.0.0", @"creator_version": @"3.8.8"};
    @try {
        [FTMobileAgent startWithConfigOptions:config];
        FTRumConfig *rum = [[FTRumConfig alloc] initWithAppid:appID];
        rum.sampleRate = 100;
        // Native screens and Cocos pages both use manual Views / Actions.
        rum.enableTraceUserView = NO; rum.enableTraceUserAction = NO;
        // Creator 3.8.8 XHR uses NSURLSession. Cocos owns its Resource and Trace collection.
        rum.enableTraceUserResource = NO; rum.enableTraceURLConnectionResource = NO;
        rum.enableTrackAppCrash = [self flag:settings key:@"enableNativeCrash" fallback:YES];
        rum.enableTrackAppANR = [self flag:settings key:@"enableNativeAnr" fallback:YES];
        [rum setEnableTrackAppFreeze:[self flag:settings key:@"enableNativeUiBlock" fallback:YES] freezeDurationMs:250];
        [[FTMobileAgent sharedInstance] startRumWithConfigOptions:rum];
        FTLoggerConfig *logger = [[FTLoggerConfig alloc] init]; logger.sampleRate = 100;
        logger.enableCustomLog = YES; logger.enableLinkRumData = YES; logger.printCustomLogToConsole = NO;
        [[FTMobileAgent sharedInstance] startLoggerWithConfigOptions:logger];
        FTTraceConfig *trace = [[FTTraceConfig alloc] init]; trace.sampleRate = 100;
        trace.networkTraceType = FTNetworkTraceTypeDDtrace; trace.enableLinkRumData = YES;
        trace.enableAutoTrace = NO; trace.enableAutoTraceURLConnection = NO;
        [[FTMobileAgent sharedInstance] startTraceWithConfigOptions:trace];
        if ([self flag:settings key:@"enableSessionReplay" fallback:YES]) {
            FTSessionReplayConfig *replay = [FTSessionReplayConfig new]; replay.sampleRate = 100;
            // Native recorder mode is the default; never enable external-only mode here.
            replay.textAndInputPrivacy = FTTextAndInputPrivacyLevelMaskAllInputs;
            [[FTRumSessionReplay sharedInstance] startWithSessionReplayConfig:replay];
        }
        GCStarted = YES;
    } @catch (NSException *exception) {
        [FTMobileAgent shutDown]; GCStopped = YES;
        @throw exception;
    }
}
+ (void)startNativeView:(NSString *)page {
    if (!GCStarted) return;
    [self stopNativeView];
    NSString *name = [page isEqual:@"settings"] ? @"NativeSdkSettings" : [page isEqual:@"results"] ? @"NativeRoundResults" : @"NativeGameLobby";
    [[FTExternalDataManager sharedManager] startViewWithName:name property:@{@"demo_scenario": @"hybrid_native"}];
    GCNativeView = YES;
}
+ (void)stopNativeView {
    if (GCStarted && GCNativeView) [[FTExternalDataManager sharedManager] stopView];
    GCNativeView = NO;
}
+ (void)action:(NSString *)destination {
    if (GCStarted && GCNativeView) [[FTExternalDataManager sharedManager] addAction:@"native_navigation" actionType:@"click" property:@{@"destination": destination}];
}
@end
