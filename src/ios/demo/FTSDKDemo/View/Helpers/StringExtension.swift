//
//  StringExtension.swift
//  FTSDKDemo
//
//  Created by hulilei on 2023/7/21.
//

import Foundation
import UIKit
enum PasteConfigurationError:Error {
    case formatError,parseError,paramError,noData
}
extension PasteConfigurationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .formatError:
            return "Paste string format error"
        case .parseError:
            return "Paste string can't parse"
        case .paramError:
            return "Paste string param error"
        case .noData:
            return "There is no replicable data"
        }
    }
}
let configPrefix = "gc-demo://"
struct Configuration:Codable,Hashable{
    var datakitAddress: String?
    var datawayAddress: String?
    var datawayClientToken: String?
    var demoApiAddress: String?
    var demoIOSAppId: String?
    
    func check()->Bool{
        guard let _ = demoIOSAppId,let _ = demoApiAddress else {
            return false
        }
        if let _ = datakitAddress {
            return true
        }
        
        if let _ = datawayAddress,let _ = datawayClientToken {
            return true
        }
        return false
    }
    
    func isDataKit() -> Bool {
        if let _ = datakitAddress {
            return true
        }
        return false
    }
    func isDataWay() -> Bool {
        if let _ = datawayAddress,let _ = datawayClientToken {
            return true
        }
        return false
    }
}
protocol PasteConfiguration {
    func parsePaste() throws -> Configuration
    
    func base64Decoding() throws ->String
}
extension String:PasteConfiguration {
    func parsePaste() throws -> Configuration {
        if self.hasPrefix(configPrefix) {
            let str = String(self.dropFirst(configPrefix.count))
            let decodeStr = try str.base64Decoding()
            if let jsonData = decodeStr.data(using: .utf8) {
                let decoder = JSONDecoder()
                do {
                    let config = try decoder.decode(Configuration.self, from: jsonData)
                    if !config.check() {
                        throw PasteConfigurationError.paramError
                    }
                    return config
                }catch{
                    throw PasteConfigurationError.parseError
                }
            }
        }
        throw PasteConfigurationError.formatError
    }
    
    func base64Decoding()throws ->String{
        let decodeData = NSData(base64Encoded: self,options: NSData.Base64DecodingOptions.init(rawValue: 0))
        if let data = decodeData {
            let decodeStr = NSString(data: data as Data, encoding: NSUTF8StringEncoding)! as String
            return decodeStr
        }
        throw PasteConfigurationError.parseError
    }
}
