//
//  AppDelegate.swift
//  GuanceDemo
//
//  Created by hulilei on 2023/7/17.
//

import UIKit
import FTMobileSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let config = FTMobileConfig.init(metricsUrl: UserDefaults.datakitURL)
        config.enableSDKDebugLog = true
        config.groupIdentifiers = [GroupIdentifier]
        FTMobileAgent.start(withConfigOptions: config)
        let rum = FTRumConfig(appid:UserDefaults.rumAppid )
        rum.enableTrackAppANR = true
        rum.enableTraceUserView = true
        rum.enableTraceUserAction = true
        rum.enableTraceUserResource = true
        rum.enableTrackAppCrash = true
        rum.enableTrackAppFreeze = true
        rum.deviceMetricsMonitorType = .all
        rum.errorMonitorType = .all
        FTMobileAgent.sharedInstance().startRum(withConfigOptions: rum)
        
        let trace = FTTraceConfig()
        trace.enableAutoTrace = true
        trace.enableLinkRumData = true
        FTMobileAgent.sharedInstance().startTrace(withConfigOptions: trace)
        
        let logger = FTLoggerConfig()
        logger.enableCustomLog = true
        logger.enableLinkRumData = true
        logger.printCustomLogToConsole = true
        FTMobileAgent.sharedInstance().startLogger(withConfigOptions: logger)
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
}

