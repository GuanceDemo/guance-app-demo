//
//  ColorExtension.swift
//  GuanceDemo
//
//  Created by hulilei on 2023/7/28.
//

import Foundation
import UIKit
extension UIColor {
     class var icon: UIColor {
        get {
            UIColor.init { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return .white
                }else{
                    return .lightGray
                }
            }
        }
    }
    
    class var tipLable: UIColor {
       get {
           UIColor.init { traitCollection in
               if traitCollection.userInterfaceStyle == .dark {
                   return .white
               }else{
                   return .black
               }
           }
       }
   }
    class var navigationBackgroundColor:UIColor {
        get {
            UIColor.init { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return .black
                }else{
                    return .white
                }
            }
        }
    }

}
