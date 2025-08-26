//
//  SelectButton.swift
//  FTSDKDemo
//
//  Created by hulilei on 2024/9/4.
//

import UIKit

class SelectButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInitialUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func setupInitialUI(){
        titleLabel?.font = .systemFont(ofSize: 13)
        setTitleColor(.darkGray, for: .normal)
        setImage(UIImage(systemName: "circle"), for: .normal)
        setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        tintColor = .theme

        let spacing: CGFloat = 10.0
        imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20 + spacing)
    }
}
