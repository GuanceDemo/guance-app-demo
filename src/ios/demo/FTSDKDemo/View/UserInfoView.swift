//
//  UserInfoView.swift
//  FTSDKDemo
//
//  Created by hulilei on 2024/9/2.
//

import UIKit

class UserInfoView: UIView {
    let avatar:UIImageView = UIImageView.init()
    
    let nameLabel:UILabel = {
        let nameLab = UILabel.init()
        nameLab.font = UIFont.systemFont(ofSize: 16)
        nameLab.textColor = .black
        return nameLab
    }()
    
    let emailLabel:UILabel = {
        let emailLab = UILabel.init()
        emailLab.font = UIFont.systemFont(ofSize: 14)
        emailLab.textColor = .gray
        return emailLab
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    public var refreshDataClick:(()->Void)?

    private func commonInit() {
        self.backgroundColor = .lightGray
        let backgroundImg = UIImageView(image: UIImage(named: "ft_setting_avatar_bg"))
        backgroundImg.backgroundColor = .lightGray
        backgroundImg.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: 160)
        backgroundImg.contentMode = .scaleAspectFill
        self.addSubview(backgroundImg)
        self.addSubview(avatar)
        avatar.backgroundColor = .lightGray
        avatar.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.left.equalTo(self).offset(15)
            make.size.equalTo(CGSize(width: 100, height: 100))
        }
        avatar.layer.cornerRadius = 30
        avatar.layer.masksToBounds = true
        
        
        self.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp_rightMargin).offset(20)
            make.top.equalTo(avatar.snp_topMargin)
            make.size.equalTo(CGSize(width: 200, height: 25))
        }
        self.addSubview(emailLabel)
        emailLabel.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp_rightMargin).offset(20)
            make.top.equalTo(nameLabel.snp_bottomMargin).offset(10)
            make.size.equalTo(CGSize(width: 200, height: 25))
        }
        
        let refreshTipBtn = UIButton(type: .system)
        refreshTipBtn.addTarget(self, action: #selector(refreshData), for: .touchUpInside)
        refreshTipBtn.setTitle(REFRESH_BTN_TITLE, for: .normal)
        refreshTipBtn.setTitleColor(.theme, for: .normal)
        refreshTipBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        refreshTipBtn.contentHorizontalAlignment = .left
        self.addSubview(refreshTipBtn)
        
        refreshTipBtn.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp_rightMargin).offset(20)
            make.bottom.equalTo(avatar.snp_bottomMargin)
            make.size.equalTo(CGSize(width: 200, height: 25))
        }
        if let userInfo = UserManager.shared().userInfo {
            avatar.sd_setImage(with: URL(string: userInfo.avatar))
            nameLabel.text = userInfo.username
            emailLabel.text = userInfo.email
        }
    }
    
    public func updateUserInfo(){
        if let userInfo = UserManager.shared().userInfo {
            avatar.sd_setImage(with: URL(string: userInfo.avatar))
            nameLabel.text = userInfo.username
            emailLabel.text = userInfo.email
        }
    }
    @objc func refreshData() {
        if let refreshDataClick = refreshDataClick {
            refreshDataClick()
        }
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
