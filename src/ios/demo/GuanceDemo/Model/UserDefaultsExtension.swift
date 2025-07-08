//
//  UserDefaultsExtension.swift
//  GuanceDemo
//
//  Created by hulilei on 2023/7/20.
//

import Foundation

let  DEFAULT_RUM_APP_ID = "gc_app_ios_demo"
let  DEFAULT_DATAWAY_URL = "http://127.0.0.1:9529"
let  DEFAULT_DATAKIT_URL = "http://127.0.0.1:9529"
let  DEFAULT_CLIENT_ID = "[Dataway Client Token]"
let  DEFAULT_BASE_URL = "http://127.0.0.1:8000"
let  DEFAULT_SR_TEXT_PRIVACY = 2

let  DEFAULT_USER_ACCOUNT = "guance"
let  DEFAULT_USER_PASSWORD = "admin"

let  GroupIdentifier = "group.com.guance.widget.demo"
let  KEY_USER_INFO = "key_user_info"
let  KEY_LOGIN = "key_login"
let  KEY_IS_DATAKIT = "key_is_datakit"
let  KEY_BASE_URL = "key_baseurl"
let  KEY_SR_TEXT_PRIVACY = "key_sr_text_privacy"
let  KEY_SR_ENABLE = "key_sr_enable"
let  KEY_USER_ACCOUNT = "key_user_account"
let  KEY_USER_PASSWORD = "key_user_password"

let  KEY_RUM_APP_ID = "key_rum_app_id"
let  KEY_DATAKIT_URL = "key_dataKit_url"
let  KEY_DATAWAY_URL = "key_dataWay_url"
let  KEY_CLIENT_TOKEN = "key_clientToken_url"

let  REFRESH_BTN_TITLE =  NSLocalizedString("refresh_btn_title", comment: "Refresh button title")
///UserDefaults property wrapper
@propertyWrapper
public struct UserDefaultsWrapper<Value> {
    
    let key: String
    let defaultValue: Value
     ///Which UserDefaults to store in, default is shared with the app
    var storage: UserDefaults? = .standard

    public var wrappedValue: Value {
        get {
            let value = storage?.value(forKey: key) as? Value
            return value ?? defaultValue
        }
        set {
            storage?.setValue(newValue, forKey: key)
            storage?.synchronize()
        }
    }
}
@propertyWrapper
public struct UserDefaultsOptionalWrapper<Value> {
    
    let key: String
    let defaultValue: Value?
     ///Which UserDefaults to store in, default is shared with the app
    var storage: UserDefaults? = .standard
    init(key: String, defaultValue: Value? = nil, storage: UserDefaults? = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = storage
    }
    public var wrappedValue: Value? {
        get {
            let value = storage?.value(forKey: key) as? Value
            return value ?? defaultValue
        }
        set {
            storage?.setValue(newValue, forKey: key)
            storage?.synchronize()
        }
    }
}

public extension UserDefaults {
    ///User information
    @UserDefaultsOptionalWrapper(key: KEY_USER_INFO)  static var userInfo: Data?
    @UserDefaultsWrapper(key: KEY_LOGIN,defaultValue: false,storage: .shared)  static var login: Bool
    @UserDefaultsWrapper(key: KEY_IS_DATAKIT,defaultValue: true,storage: .shared)  static var isDataKit: Bool
    // Record whether SR (Session Replay) feature is enabled, default is off
    @UserDefaultsWrapper(key: KEY_SR_ENABLE,defaultValue: false,storage: .shared)  static var enableSessionReplay: Bool
    // SR text privacy permission, default is off
    @UserDefaultsWrapper(key: KEY_SR_TEXT_PRIVACY,defaultValue:DEFAULT_SR_TEXT_PRIVACY,storage: .shared)  static var sessionReplayPrivacy: Int

    
    // Record the last entered username
    @UserDefaultsWrapper(key: KEY_USER_ACCOUNT,defaultValue: DEFAULT_USER_ACCOUNT,storage: .shared)
    static var userAccount: String
    // Record the last entered password
    @UserDefaultsWrapper(key: KEY_USER_PASSWORD,defaultValue: DEFAULT_USER_PASSWORD,storage: .shared)
    static var userPassword: String
    // sdk rum appid
    @UserDefaultsWrapper(key: KEY_RUM_APP_ID,defaultValue: DEFAULT_RUM_APP_ID,storage: .shared)  static var rumAppId: String
    // sdk DATAKIT
    @UserDefaultsWrapper(key: KEY_DATAKIT_URL,defaultValue: DEFAULT_DATAKIT_URL,storage: .shared)  static var datakitURL: String
    // sdk DataWay
    @UserDefaultsWrapper(key: KEY_DATAWAY_URL,defaultValue: DEFAULT_DATAWAY_URL,storage: .shared)  static var dataWayURL: String
    // sdk ClientToken
    @UserDefaultsWrapper(key: KEY_CLIENT_TOKEN,defaultValue: DEFAULT_CLIENT_ID,storage: .shared)  static var clientToken: String
    // Network request address
    @UserDefaultsWrapper(key: KEY_BASE_URL,defaultValue:DEFAULT_BASE_URL,storage: .shared)  static var baseUrl: String
    
    ///UserDefaults shared with the app
    @objc
    static var shared: UserDefaults? {
        if let value = Bundle.main.object(forInfoDictionaryKey: "GroupIdentifier") as? String {
            return  UserDefaults(suiteName: value)
        } else {
            return UserDefaults(suiteName: GroupIdentifier)
        }
    }
}
