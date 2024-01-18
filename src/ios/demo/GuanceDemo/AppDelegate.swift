//
//  AppDelegate.swift
//  GuanceDemo
//
//  Created by hulilei on 2023/7/17.
//

import UIKit
import FTMobileSDK
#if PRE
let Track_id = "0000000001"
let STATIC_TAG = "preprod"
#elseif  DEVELOP
let Track_id = "0000000002"
let STATIC_TAG = "common"
#else
let Track_id = "0000000003"
let STATIC_TAG = "prod"
#endif
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
//      示例：多环境配置参数使用
        let info = Bundle.main.infoDictionary!
        let env:String  = info["SDK_ENV"] as! String
//      let appid:String = info["SDK_APP_ID"] as! String
//        print("SDK_APP_ID:\(appid)")
//        print("SDK_ENV:\(env)")
        let dynamicTag:String? = UserDefaults.standard.value(forKey: "DYNAMIC_TAG") as? String
        let config = FTMobileConfig.init(datakitUrl: UserDefaults.datakitURL)
        config.enableSDKDebugLog = true
        config.groupIdentifiers = [GroupIdentifier]
        config.globalContext = ["gc_custom_key":STATIC_TAG]
        config.env = env
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
        if let dynamic = dynamicTag {
            rum.globalContext = ["gc_dynamic_key":dynamic]
        }
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

