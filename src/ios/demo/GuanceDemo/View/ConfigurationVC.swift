//
//  ConfigurationVC.swift
//  GuanceDemo
//
//  Created by hulilei on 2023/7/21.
//

import UIKit
import SnapKit
import Toast_Swift
import MBProgressHUD
class ConfigurationVC: UIViewController,UITextFieldDelegate {
    lazy var appidtf:DesignableUITextField = {
        let appidtf = DesignableUITextField.init()
        appidtf.text = UserDefaults.rumAppid
        appidtf.leftViewMode = .always
        appidtf.keyboardType = .default
        appidtf.clearButtonMode = .always
        appidtf.delegate = self
        return appidtf
    }()
    lazy var datakittf:DesignableUITextField = {
        let datakittf = DesignableUITextField.init()
        datakittf.text = UserDefaults.datakitURL
        datakittf.leftViewMode = .always
        datakittf.keyboardType = .default
        datakittf.clearButtonMode = .always
        datakittf.delegate = self
        return datakittf
    }()
    
    lazy var baseURL:DesignableUITextField = {
        let baseURL = DesignableUITextField.init()
        baseURL.text = UserDefaults.baseUrl
        baseURL.leftViewMode = .always
        baseURL.keyboardType = .default
        baseURL.clearButtonMode = .always
        baseURL.delegate = self
        return baseURL
    }()
    
    lazy var confirmBtn:UIButton = {
        let btn = UIButton.init(type: .system)
        btn.layer.cornerRadius = 8
        btn.layer.masksToBounds = true
        btn.addTarget(self, action: #selector(confirmClick), for: .touchUpInside)
        btn.setTitle("保存配置", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.isEnabled = true
        btn.setBackgroundImage(UIImage.init(color: .orange), for: .normal)
        btn.setBackgroundImage(UIImage.init(color: .lightGray), for: .disabled)
        btn.setTitleColor(.white, for: .disabled)
        btn.setTitleColor(.white, for: .normal)
        return btn
    }()
    lazy var dataKitBtn:ConnectStatusBtn = {
        let btn = ConnectStatusBtn.init()
        btn.connect = .normal
        btn.setImage(UIImage(systemName: "network"), for: .normal)
        btn.addTarget(self, action: #selector(connectClick(_:)), for: .touchUpInside)
        return btn
    }()
    lazy var baseApiBtn:ConnectStatusBtn = {
        let btn = ConnectStatusBtn.init()
        btn.connect = .normal
        btn.setImage(UIImage(systemName: "network"), for: .normal)
        btn.addTarget(self, action: #selector(connectClick(_:)), for: .touchUpInside)
        return btn
    }()
    var tfArray:Array<UITextField> = Array()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "配置"
        
        // Do any additional setup after loading the view.
        let item = UIBarButtonItem.init(image: UIImage(systemName: "doc.on.clipboard"), style: .plain, target: self, action: #selector(copyConfigs))
        self.navigationItem.rightBarButtonItem = item
        view.backgroundColor = .navigationBackgroundColor
        createUI()
    }
    func createUI(){
        view.addSubview(appidtf)
        view.addSubview(datakittf)
        view.addSubview(baseURL)
        view.addSubview(confirmBtn)
        view.addSubview(dataKitBtn)
        view.addSubview(baseApiBtn)
        let rumTipLab =  UILabel.init()
        rumTipLab.text = "RUM App ID"
        rumTipLab.textColor = .tipLable
        rumTipLab.font = .boldSystemFont(ofSize: 13)
        let addressTipLab =  UILabel.init()
        addressTipLab.text = "Datakit Address"
        addressTipLab.textColor = .tipLable
        addressTipLab.font = .boldSystemFont(ofSize: 13)

        let apiTipLab =  UILabel.init()
        apiTipLab.text = "Demo API Address"
        apiTipLab.textColor = .tipLable
        apiTipLab.font = .boldSystemFont(ofSize: 13)

        view.addSubview(rumTipLab)
        view.addSubview(addressTipLab)
        view.addSubview(apiTipLab)

        tfArray = [appidtf,datakittf,baseURL]
        let width = self.view.bounds.size.width - 60 - 20
        let top = self.navigationController?.navigationBar.frame.maxY ?? 0
        rumTipLab.snp.makeConstraints { make in
            make.top.equalTo(self.view).offset(top+30)
            make.centerX.equalTo(self.view).offset(-10)
            make.size.equalTo(CGSize(width: width, height: 20))
        }
        appidtf.snp.makeConstraints { make in
            make.top.equalTo(rumTipLab).offset(15)
            make.centerX.equalTo(self.view).offset(-10)
            make.size.equalTo(CGSize(width: width, height: 40))
        }
        addressTipLab.snp.makeConstraints { make in
            make.top.equalTo(appidtf.snp_bottomMargin).offset(20)
            make.centerX.equalTo(self.view).offset(-10)
            make.size.equalTo(CGSize(width: width, height: 20))
        }
        datakittf.snp.makeConstraints { make in
            make.top.equalTo(addressTipLab).offset(15)
            make.centerX.equalTo(self.view).offset(-10)
            make.size.equalTo(CGSize(width: width, height: 40))
        }
        dataKitBtn.snp.makeConstraints { make in
            make.left.equalTo(datakittf.snp_rightMargin).offset(15)
            make.centerY.equalTo(datakittf)
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
        apiTipLab.snp.makeConstraints { make in
            make.top.equalTo(datakittf.snp_bottomMargin).offset(20)
            make.centerX.equalTo(self.view).offset(-10)
            make.size.equalTo(CGSize(width: width, height: 20))
        }
        baseURL.snp.makeConstraints { make in
            make.top.equalTo(apiTipLab).offset(15)
            make.centerX.equalTo(self.view).offset(-10)
            make.size.equalTo(CGSize(width: width, height: 40))
        }
        baseApiBtn.snp.makeConstraints { make in
            make.left.equalTo(baseURL.snp_rightMargin).offset(15)
            make.centerY.equalTo(baseURL)
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
        confirmBtn.snp.makeConstraints { make in
            make.top.equalTo(baseURL.snp_bottomMargin).offset(50)
            make.centerX.equalTo(self.view)
            make.size.equalTo(CGSize(width: width, height: 44))
        }
    }
    
    @objc func confirmClick(){
        resignTF()
        connect(true,url: datakittf.text!) { success in
            if success {
                self.connect(false,url:self.baseURL.text!) { result in
                    if result {
                        self.showAlert()
                    }
                }
            }
        }
    }
    func showAlert(){
        let alert = UIAlertController(title: "注意⚠️", message: "SDK 配置的新参数，需要重启应用才能生效❗️", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确认", style: .default,handler: { action in
            UserDefaults.baseUrl = self.baseURL.text!
            UserDefaults.rumAppid = self.appidtf.text!
            UserDefaults.datakitURL = self.datakittf.text!
            FTLogInfo("datakitAddress:\(self.datakittf.text!)\ndemoApiAddress:\(self.baseURL.text!)\ndemoIOSAppId:\(self.appidtf.text!)")
        }))
        self.navigationController?.present(alert, animated: true)
    }
    @objc func copyConfigs(){
        let paste = UIPasteboard.general
        if let string = paste.string{
            if let config = string.parsePaste(){
                appidtf.text = config.demoIOSAppId
                datakittf.text = config.datakitAddress
                baseURL.text = config.demoApiAddress
                dataKitBtn.connect = .normal
                baseApiBtn.connect = .normal
                self.view.makeToast("数据复制成功",position: .center)
            }else{
                self.view.makeToast("数据解析失败",position: .center)
            }
            
        }else{
            self.view.makeToast("没有可复制的数据",position: .center)
        }
    }
    @objc func connectClick(_ sender:UIButton){
        let str = sender == dataKitBtn ? datakittf.text : baseURL.text
        if let urlStr = str {
            connect(sender == dataKitBtn, url: urlStr)
        }else{
            self.view.makeToast("格式错误",position: .center)
        }
    }
    
    func connect(_ datakit:Bool, url:String,complete:((Bool)->Void)? = nil) {
        let btn = datakit ? dataKitBtn : baseApiBtn

        Task(priority: .medium) {
            do{
                let _ = MBProgressHUD.showAdded(to: self.view, animated: true)
                if datakit {
                    let _ = try await NetworkEngine().datakitConnect(url: datakittf.text!)
                }else{
                    let _ = try await NetworkEngine().baseUrlConnent(url: url)
                }
                btn.connect = .success
                complete?(true)
                FTLogInfo("\(url) connected successful.")
            } catch {
                self.view.makeToast(error.localizedDescription,position: .center)
                btn.connect = .error
                complete?(false)
                FTLogError("\(url) connected failure.")
            }
            let _ = MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
    func resignTF(){
        appidtf.resignFirstResponder()
        datakittf.resignFirstResponder()
        baseURL.resignFirstResponder()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        resignTF()
        
    }
    func textFieldDidChangeSelection(_ textField: UITextField) {
        confirmBtn.isEnabled = datakittf.text?.count ?? 0 > 0 && appidtf.text?.count ?? 0 > 0 && baseURL.text?.count ?? 0 > 0
        if textField == datakittf {
            dataKitBtn.connect = .normal
        }else if textField == baseURL {
            baseApiBtn.connect = .normal
        }
    }
   
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        confirmBtn.isEnabled = false
        if textField == datakittf {
            dataKitBtn.connect = .normal
        }else if textField == baseURL {
            baseApiBtn.connect = .normal
        }
        return true
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
