//
//  ConnectStatusBtn.swift
//  GuanceDemo
//
//  Created by hulilei on 2023/7/24.
//

import UIKit
enum connectStatus {
    case normal,success,error
}

class ConnectStatusBtn: UIButton {
    var connect: connectStatus = .normal {
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
