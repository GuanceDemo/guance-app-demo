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
let  DEFAULT_USER_ACCOUNT = "guance"
let  DEFAULT_USER_PASSWORD = "admin"

let  GroupIdentifier = "group.com.guance.widget.demo"
let  KEY_USER_INFO = "key_user_info"
let  KEY_LOGIN = "key_login"
let  KEY_IS_DATAKIT = "key_is_datakit"
let  KEY_BASE_URL = "key_baseurl"
let  KEY_USER_ACCOUNT = "key_user_account"
let  KEY_USER_PASSWORD = "key_user_password"

let  KEY_RUM_APP_ID = "key_rum_app_id"
let  KEY_DATAKIT_URL = "key_dataKit_url"
let  KEY_DATAWAY_URL = "key_dataWay_url"
let  KEY_CLIENT_TOKEN = "key_clientToken_url"

let  REFRESH_BTN_TITLE =  "[点击此处或下拉进行刷新]"
///UserDefaults 属性包装器
@propertyWrapper
public struct UserDefaultsWrapper<Value> {
    
    let key: String
    let defaultValue: Value
     ///存储在哪个 UserDefaults，默认为与APP共享数据的
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
     ///存储在哪个 UserDefaults，默认为与APP共享数据的
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
    ///用户信息
    @UserDefaultsOptionalWrapper(key: KEY_USER_INFO)  static var userInfo: Data?
    @UserDefaultsWrapper(key: KEY_LOGIN,defaultValue: false,storage: .shared)  static var login: Bool
    @UserDefaultsWrapper(key: KEY_IS_DATAKIT,defaultValue: true,storage: .shared)  static var isDataKit: Bool

    
    // 记录上次用户输入的用户名
    @UserDefaultsWrapper(key: KEY_USER_ACCOUNT,defaultValue: DEFAULT_USER_ACCOUNT,storage: .shared)
    static var userAccount: String
    // 记录上次用户输入的密码
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
    // 网络请求地址
    @UserDefaultsWrapper(key: KEY_BASE_URL,defaultValue:DEFAULT_BASE_URL,storage: .shared)  static var baseUrl: String
    
    ///与app共享数据的UserDefaults
    @objc
    static var shared: UserDefaults? {
        if let value = Bundle.main.object(forInfoDictionaryKey: "GroupIdentifier") as? String {
            return  UserDefaults(suiteName: value)
        } else {
            return UserDefaults(suiteName: GroupIdentifier)
        }
    }
}
