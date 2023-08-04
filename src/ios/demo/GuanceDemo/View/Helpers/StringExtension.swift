//
//  StringExtension.swift
//  GuanceDemo
//
//  Created by hulilei on 2023/7/21.
//

import Foundation
import UIKit

let configPrefix = "gc-demo://"
struct Configration:Codable,Hashable{
    var datakitAddress: String
    var demoApiAddress: String
    var demoIOSAppId: String
}
protocol PasteConfigration {
    func parsePaste()->Configration?
    
    func base64Decoding()->String
}
extension String:PasteConfigration {
    func parsePaste() -> Configration? {
        if self.hasPrefix(configPrefix) {
            let str = String(self.dropFirst(configPrefix.count))
            let decodeStr = str.base64Decoding()
            if let jsonData = decodeStr.data(using: .utf8) {
                let decoder = JSONDecoder()
                do {
                    let config = try decoder.decode(Configration.self, from: jsonData)
                    return config
                }catch{
                    FTLogError("paste string can't parse")
                }
            }
        }
        return nil
    }
    
    func base64Decoding()->String{
        let decodeData = NSData(base64Encoded: self,options: NSData.Base64DecodingOptions.init(rawValue: 0))
        let decodeStr = NSString(data: decodeData! as Data, encoding: NSUTF8StringEncoding)! as String
        return decodeStr
    }
}
