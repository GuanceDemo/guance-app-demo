//
//  SRTipLabel.swift
//  FTSDKDemo
//
//  Created by hulilei on 2024/9/11.
//

import UIKit

class SRTipLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.font = .systemFont(ofSize: 13)
        self.textColor = .systemGray
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
