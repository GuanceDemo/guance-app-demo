//
//  NetworkEngine.swift
//  GuanceDemo
//
//  Created by hulilei on 2023/7/17.
//

import Foundation
enum RequestError:Error {
    case tokenError,netError,urlError
}
extension RequestError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .tokenError:
            return "Invalid credentials"
        case .netError:
            return "网络请求失败"
        case .urlError:
            return "URL format error"
        }
    }
}
struct NetworkEngine{
    let session:URLSession = URLSession(configuration: .default)
    var baseUrl:String = UserDefaults.baseUrl 
    
    let login:String = "/api/login"
    let user:String = "/api/user"
    let connect:String = "/connect"
    let datakitPing:String = "/v1/ping"
    
    var webview:String{
        get {
            self.baseUrl+"?requestUrl="+self.baseUrl+"/api/user"
        }
    }
    
    func login(_ userName:String,_ password:String) async throws -> Bool{
        let urlStr = baseUrl+login
        let parameters = ["username":userName,
                          "password":password
        ]
        print("urlStr:\(urlStr)")
        do {
            let data = try await postMethod(url: urlStr,parameters: parameters)
            let dict = dataToDictionary(data: data)
            print("data:\(String(describing: dict))")
            return true
        }catch{
            throw error
        }
    }
    
    func getUserInfo() async throws -> Data? {
        let urlStr = baseUrl+user
        do {
            let data = try await getMethod(url: urlStr)
           
            return data
        }catch{
            throw error
        }
    }
    
    func baseUrlConnent(url:String) async throws -> Bool {
        let urlStr = url+connect
        do {
            let _ = try await getMethod(url: urlStr)
            return true
        }catch{
            throw error
        }
    }
    func datakitConnect(url:String)async throws -> Bool {
        let urlStr = url+datakitPing
        do {
            let _ = try await getMethod(url: urlStr)
            return true
        }catch{
            throw error
        }
    }
    func postMethod(url:String,parameters:[String:Any]=[:]) async throws -> Data? {
        guard let newUrl = URL(string: url) else {
            throw RequestError.urlError
        }
        var request = URLRequest.init(url: newUrl)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        }catch{
            throw RequestError.netError
        }
        return try await withCheckedThrowingContinuation { continuation in
            let task = self.session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else
                if let response = response as? HTTPURLResponse{
                    if response.statusCode == 200 {
                        continuation.resume(returning: data)
                    }else if response.statusCode == 401 || response.statusCode ==  403 {
                        /// 状态码为 401 或 403 时，认定账号密码错误
                        continuation.resume(throwing: RequestError.tokenError)
                    }else{
                        /// 其余情况判定网络原因
                        continuation.resume(throwing: RequestError.netError)
                    }
                }else{
                    /// 其余情况判定网络原因
                    continuation.resume(throwing: RequestError.netError)
               }
            }
            task.resume()
            
        }
    }
    
    func getMethod(url:String,parameters:[String:Any]=[:]) async throws -> Data? {
        guard let newUrl = URL(string: url) else {
            throw RequestError.urlError
        }
        var request = URLRequest.init(url: newUrl)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "GET"
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = self.session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let response = response as? HTTPURLResponse{
                    if response.statusCode == 200 {
                        continuation.resume(returning: data)
                    }else if response.statusCode == 401 || response.statusCode ==  403 {
                        /// 状态码为 401 或 403 时，认定账号密码错误
                        continuation.resume(throwing: RequestError.tokenError)
                    }else{
                        /// 其余情况判定网络原因
                        continuation.resume(throwing: RequestError.netError)
                    }
                }else{
                    /// 其余情况判定网络原因
                    continuation.resume(throwing: RequestError.netError)
                }
            }
            task.resume()
            
        }
    }
    
    
}

public func parse<T: Decodable>(_ data: Data) -> T {
    do{
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }catch{
        fatalError("Couldn't parse data as \(T.self):\n\(error)")
    }
}
func dataToDictionary(data:Data?) ->Dictionary<String, Any>?{
    guard let newData = data else {
        return nil
    }
    do{
        let json = try JSONSerialization.jsonObject(with: newData, options: .mutableContainers)
        let dic = json as! Dictionary<String, Any>
        return dic
        
    }catch _ {
        return nil
    }
}
