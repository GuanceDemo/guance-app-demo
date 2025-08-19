//
//  UserManager.swift
//  FTSDKDemo
//
//  Created by hulilei on 2023/7/18.
//

import Foundation
import FTMobileSDK


class UserManager {
    private static let sharedManager:UserManager = {
        let shared = UserManager.init(isLogin: UserDefaults.login,isDataKit: UserDefaults.isDataKit)
        if let data = UserDefaults.userInfo {
            shared.userInfo = parse(data)
        }
        return shared
    }()
    
    var isLogin:Bool {
        willSet {
            UserDefaults.login = newValue
            if let observer = loginObserver {
                DispatchQueue.main.async {
                    observer(self.isLogin)
                }
            }
        }
    }
    
    var userInfo:UserInfo? {
        willSet {
            if let info = newValue {
                FTMobileAgent.sharedInstance().bindUser(withUserID: "user_1", userName: info.username, userEmail: info.email)
            }else{
                FTMobileAgent.sharedInstance().unbindUser()
                UserDefaults.userInfo = nil
            }
        }
    }
    
    var loginObserver:((Bool)->Void)?
    
    init(isLogin: Bool, isDataKit:Bool, loginObserver: ( (Bool) -> Void)? = nil) {
        self.isLogin = isLogin
        self.loginObserver = loginObserver
    }
    
    class func shared() -> UserManager {
        return sharedManager
    }
    
    func login(userName:String,password:String) async throws -> Bool{
        do {
            let success = try await NetworkEngine.shared.login(userName, password)
            if success {
               let result = try await loadUserInfo()
                if result {
                    self.isLogin = true
                }
            }
        }catch{
            throw error
        }
        return false
    }
    func loadUserInfo() async throws -> Bool{
        let data = try await NetworkEngine.shared.getUserInfo()
        if let data = data {
            UserDefaults.userInfo = data
            self.userInfo = parse(data)
            FTLogInfo("usserinfo:\(String(describing: userInfo))")
            return true
        }
        return false
    }
    func logout(){
        isLogin = false
        userInfo = nil
    }
}
