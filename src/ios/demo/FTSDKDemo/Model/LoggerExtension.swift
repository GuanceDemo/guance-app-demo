//
//  LoggerExtension.swift
//  FTSDKDemo
//
//  Created by hulilei on 2023/7/20.
//

import Foundation
import FTMobileSDK
/// Extension example for custom log API usage based on FTMobileSDK.
/// Add file name, method name, and line number to custom logs.
/// - Parameters:
///   - content: Log content
///   - property: Custom properties (optional)
///   - file: File name
///   - function: Method name
///   - line: Line number
public func FTLogInfo(_ content: @autoclosure () -> String = "",
                              property:[String:String]? = nil,
                              file: String = #file,
                              function: StaticString = #function,
                              line: UInt = #line){
    var contentStr = String(describing: content())
    contentStr = "\(file.split(separator: "/").last!) [\(function)] [\(line)] \(contentStr)"
    FTLogger.shared().info(contentStr, property: property)
}


public func FTLogWarning(_ content: @autoclosure () -> String = "",
                                 property:[String:String]? = nil,
                                 file: String = #file,
                                 function: StaticString = #function,
                                 line: UInt = #line){
    var contentStr = String(describing: content())
    contentStr = "\(file.split(separator: "/").last!) [\(function)] [\(line)] \(contentStr)"
    FTLogger.shared().warning(contentStr, property: property)
}


public func FTLogError(_ content: @autoclosure () -> String = "",
                               property:[String:String]? = nil,
                               file: String = #file,
                               function: StaticString = #function,
                               line: UInt = #line){
    var contentStr = String(describing: content())
    contentStr = "\(file.split(separator: "/").last!) [\(function)] [\(line)] \(contentStr)"
    FTLogger.shared().error(contentStr, property: property)
}

public func FTLogCritical(_ content: @autoclosure () -> String = "",
                                  property:[String:String]? = nil,
                                  file: String = #file,
                                  function: StaticString = #function,
                                  line: UInt = #line){
    var contentStr = String(describing: content())
    contentStr = "\(file.split(separator: "/").last!) [\(function)] [\(line)] \(contentStr)"
    FTLogger.shared().critical(contentStr, property: property)
}


public func FTLogOk(_ content: @autoclosure () -> String = "",
                            property:[String:String]? = nil,
                            file: String = #file,
                            function: StaticString = #function,
                            line: UInt = #line){
    var contentStr = String(describing: content())
    contentStr = "\(file.split(separator: "/").last!) [\(function)] [\(line)] \(contentStr)"
    FTLogger.shared().ok(contentStr, property: property)
}
