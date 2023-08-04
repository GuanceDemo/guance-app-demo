//
//  LoggerExtension.swift
//  GuanceDemo
//
//  Created by hulilei on 2023/7/20.
//

import Foundation
import FTMobileSDK
/// 基于 FTMobileSDK 自定义日志 API 的使用扩展示例。
/// 在自定义日志中添加文件名、方法名称、行号。
/// - Parameters:
///   - content: 日志内容
///   - property: 自定义属性(可选)
///   - file: 文件名
///   - function: 方法名
///   - line: 行号
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
