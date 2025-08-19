//
//  TFTableView.swift
//  FTSDKDemo
//
//  Created by hulilei on 2024/8/30.
//

import UIKit

class TFTableView: UITableView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let touchView = super.hitTest(point, with: event)
        if let view = touchView {
            if !(view.isKind(of: UITextView.self) || view.isKind(of: UITextField.self)){
                self.endEditing(true)
            }
        }
        return touchView
    }
}
