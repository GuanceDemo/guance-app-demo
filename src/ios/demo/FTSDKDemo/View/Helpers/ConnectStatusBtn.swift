//
//  ConnectStatusBtn.swift
//  FTSDKDemo
//
//  Created by hulilei on 2023/7/24.
//

import UIKit
enum ConnectStatus {
    case normal,success,error
}

class ConnectStatusBtn: UIButton {
    var connect: ConnectStatus = .normal {
        willSet {
            switch newValue {
            case .normal:
                self.tintColor = .icon
            case .success:
                self.tintColor = .green
            case .error:
                self.tintColor = .red
            }
        }
    }
}
