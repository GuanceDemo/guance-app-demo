//
//  ModelData.swift
//  FTSDKDemo
//
//  Created by hulilei on 2023/7/20.
//

import Foundation
class ModelData: ObservableObject{
    static let shared = ModelData(userInfo: UserInfo(avatar: "", email: "None", username: "None"))

    @Published var userInfo:UserInfo
    init(userInfo: UserInfo) {
        self.userInfo = userInfo
        Task {
            await getUserInfo()
        }
    }
    func getUserInfo() async{
        do{
            let data = try await NetworkEngine.shared.getUserInfo()
            if let info = data {
               userInfo = parse(info)
               FTLogInfo("\(userInfo)")
            }
        }catch{
            FTLogError("\(error)")
        }
    }
    
}
