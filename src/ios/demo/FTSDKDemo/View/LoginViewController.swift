//
//  LoginViewController.swift
//  FTSDKDemo
//
//  Created by hulilei on 2023/7/17.
//

import UIKit
import SnapKit
import MBProgressHUD
import Toast_Swift
class LoginViewController: UIViewController,UITextFieldDelegate {
    lazy var iconImageView:UIImageView = {
        let iconImageView = UIImageView.init(image: UIImage.init(named: "login_logo"))
        return iconImageView
    }()
    lazy var nametf:DesignableUITextField = {
        let nametf = DesignableUITextField.init()
        nametf.placeholder = NSLocalizedString("please_enter_username", comment: "Please enter username")
        nametf.text = UserDefaults.userAccount
        nametf.leftImage = UIImage.init(systemName: "person")
        nametf.textAlignment = .left
        nametf.keyboardType = .default
        nametf.returnKeyType = .done
        nametf.font = UIFont.systemFont(ofSize: 16)
        nametf.clearButtonMode = .always
        nametf.delegate = self
        
        return nametf
    }()
    lazy var passwordtf:DesignableUITextField = {
        let passwordtf = DesignableUITextField.init()
        passwordtf.placeholder = NSLocalizedString("please_enter_password", comment: "Please enter password")
        passwordtf.leftImage =  UIImage(systemName: "lock")
        passwordtf.isPassword = true
        passwordtf.text = UserDefaults.userPassword
        passwordtf.isSecureTextEntry = true
        passwordtf.textAlignment = .left
        passwordtf.keyboardType = .default
        passwordtf.font = UIFont.systemFont(ofSize: 16)
        passwordtf.clearButtonMode = .always
        passwordtf.delegate = self
        return passwordtf
    }()
    lazy var loginBtn:UIButton = {
        let btn = UIButton.init(type: .system)
        btn.layer.cornerRadius = 8
        btn.layer.masksToBounds = true
        btn.addTarget(self, action: #selector(login), for: .touchUpInside)
        btn.setTitle(NSLocalizedString("login", comment: "Login"), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.isEnabled = true
        btn.setBackgroundImage(UIImage.init(color: .theme), for: .normal)
        btn.setBackgroundImage(UIImage.init(color: .lightGray), for: .disabled)
        btn.setTitleColor(.white, for: .disabled)
        btn.setTitleColor(.white, for: .normal)
        return btn
    }()
    
    lazy var changeBaseUrlBtn:UIButton = {
        let btn = UIButton.init(type: .system)
        btn.addTarget(self, action: #selector(changeBaseUrl), for: .touchUpInside)
        btn.setTitle(NSLocalizedString("edit_demo_configuration", comment: "Edit Demo configuration"), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.tintColor = .theme
        return btn
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        createUI()
        // Do any additional setup after loading the view.
    }
    func createUI() {
        self.navigationController!.navigationBar.tintColor = .theme
        self.view.addSubview(iconImageView)
        self.view.addSubview(nametf)
        self.view.addSubview(passwordtf)
        self.view.addSubview(loginBtn)
        self.view.addSubview(changeBaseUrlBtn)
        
        iconImageView.snp.makeConstraints { (make)->Void in
            make.size.equalTo(CGSize(width: 158, height: 42))
            make.top.equalTo(self.view).offset(140)
            make.centerX.equalTo(self.view)
        }
        nametf.snp.makeConstraints { (make)->Void in
            make.top.equalTo(iconImageView.snp_bottomMargin).offset(42)
            make.centerX.equalTo(self.view)
            make.size.equalTo(CGSize(width: 303, height: 54))
        }
        passwordtf.snp.makeConstraints { (make)->Void in
            make.top.equalTo(nametf.snp_bottomMargin).offset(12)
            make.centerX.equalTo(self.view)
            make.size.equalTo(CGSize(width: 303, height: 54))
        }
        
        loginBtn.snp.makeConstraints { (make)->Void in
            make.top.equalTo(passwordtf.snp_bottomMargin).offset(32)
            make.centerX.equalTo(self.view)
            make.size.equalTo(CGSize(width: 303, height: 44))
        }
        changeBaseUrlBtn.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 303, height: 44))
            make.top.equalTo(loginBtn.snp_bottomMargin).offset(20)
            make.centerX.equalTo(self.view)
        }
        
    }
    @objc func login()  {
        nametf.resignFirstResponder()
        passwordtf.resignFirstResponder()
        Task(priority: .medium) {
            do{
                let userAccount = nametf.text!
                let userPassword = passwordtf.text!
                let _ = MBProgressHUD.showAdded(to: self.view, animated: true)
                let success = try await UserManager.shared().login(userName: userAccount, password:userPassword)
                UserDefaults.userAccount = userAccount
                UserDefaults.userPassword = userPassword
                print("success:\(success)")
            } catch {
                self.view.makeToast(error.localizedDescription,position: .center)
            }
            let _ = MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
    
    @objc func changeBaseUrl()  {
        self.navigationController?.pushViewController(ConfigurationVC(), animated: true)
    }
    func textFieldDidChangeSelection(_ textField: UITextField) {
        loginBtn.isEnabled = nametf.text?.count ?? 0 > 0 && passwordtf.text?.count ?? 0 > 0
    }
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        loginBtn.isEnabled = false
        return true
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        nametf.resignFirstResponder()
        passwordtf.resignFirstResponder()
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
