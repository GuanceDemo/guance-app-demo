//
//  NetworkEngine.swift
//  FTSDKDemo
//
//  Created by hulilei on 2023/7/17.
//

import Foundation
enum RequestError:Error {
    case tokenError
    case netError
    case urlError
    case errorCode(data:Data)
}
extension RequestError{
    func isTokenNotFound()->Bool{
        switch self {
        case .errorCode(data: _): 
            return self.errorDescription == "kodo.tokenNotFound"
        default:
            return false
        }
   
    }
}
extension RequestError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .tokenError:
            return "Invalid credentials"
        case .netError:
            return "Network request failed"
        case .urlError:
            return "URL format error"
        case .errorCode(data: let data):
            if let dict = dataToDictionary(data: data) {
                if let errorCode = dict["error_code"]{
                    return errorCode as? String
                }
            }
            return ""
        }
    }
}
struct NetworkEngine{
    static let shared = NetworkEngine()
    let session:URLSession = URLSession(configuration: .default)
    var baseUrl:String {
        get {
            UserDefaults.baseUrl
        }
    }
    
    let login:String = "/api/login"
    let user:String = "/api/user"
    let connect:String = "/connect"
    let datakitPing:String = "/v1/ping"
    
    var webView:String{
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
    
    func userInfoWithOtel() async throws -> (HTTPURLResponse?, Data?) {
        let urlStr = baseUrl+user
        do {
            var request = URLRequest.init(url: URL(string: urlStr)!)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.httpMethod = "GET"
            let data = try await otlHttpNetwork(request: request)
            return data
        }catch{
            throw error
        }
    }
    func baseUrlConnect(url:String) async throws -> Bool {
        let urlStr = url+connect
        do {
            let _ = try await getMethod(url: urlStr)
            return true
        }catch{
            throw error
        }
    }
    func dataKitConnect(url:String)async throws -> Bool {
        let urlStr = url+datakitPing
        do {
            let _ = try await getMethod(url: urlStr)
            return true
        }catch{
            throw error
        }
    }
    
    func dataWayConnect(url:String,token:String)async throws -> Bool {
        let urlStr = url+dataWayPing(token: token)
        do {
            guard let newUrl = URL(string: urlStr) else {
                throw RequestError.urlError
            }
            let content = "df_rum_ios_log message=\"connect test\" \(NSDate.ft_currentNanosecondTimeStamp())"

            var request = URLRequest.init(url: newUrl)
            request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = content.data(using: .utf8)
            let _ = try await network(request: request)
            return true
        }catch{
            throw error
        }
    }
    func dataWayPing(token:String)->String {
        return "/v1/write/logging?token=\(token)&to_headless=true"
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
            return try await network(request: request)
        }catch{
            throw RequestError.netError
        }
    }
    
    func network(request:URLRequest) async throws -> Data? {
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = self.session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else
                if let response = response as? HTTPURLResponse{
                    if response.statusCode == 200 {
                        continuation.resume(returning: data)
                    }else if response.statusCode == 401 || response.statusCode ==  403 {
                        /// When status code is 401 or 403, consider it as account/password error
                        if let data = data{
                            continuation.resume(throwing: RequestError.errorCode(data: data))
                        }else{
                            continuation.resume(throwing: RequestError.tokenError)
                        }
                    }else{
                        /// For other cases, consider it as network issue
                        continuation.resume(throwing: RequestError.netError)
                    }
                }else{
                    /// For other cases, consider it as network issue
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
        do {
            return try await network(request: request)
        }catch{
            throw RequestError.netError
        }
    }
       
    func otlHttpNetwork(request:URLRequest) async throws -> (HTTPURLResponse?,Data?) {
        return try await withCheckedThrowingContinuation { continuation in
            let task = self.session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else
                if let response = response as? HTTPURLResponse{
                    if response.statusCode == 200 {
                        continuation.resume(returning: (response,data))
                    }else if response.statusCode == 401 || response.statusCode ==  403 {
                        /// When status code is 401 or 403, consider it as account/password error
                        if let data = data{
                            continuation.resume(throwing: RequestError.errorCode(data: data))
                        }else{
                            continuation.resume(throwing: RequestError.tokenError)
                        }
                    }else{
                        /// For other cases, consider it as network issue
                        continuation.resume(throwing: RequestError.netError)
                    }
                }else{
                    /// For other cases, consider it as network issue
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
