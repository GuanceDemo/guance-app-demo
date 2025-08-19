//
//  ConfigurationVC.swift
//  FTSDKDemo
//
//  Created by hulilei on 2023/7/21.
//

import UIKit
import SnapKit
import Toast_Swift
import MBProgressHUD
import RxSwift
import RxCocoa

enum CellInfoType{
    case rum,dataKit,dataWay,clientToken,demoAPI
}
class CellInfo:NSObject{
    let title:String
    let hint:String
    let type:CellInfoType
    var detail:String? {
        willSet{
            connectStatus = .normal
        }
    }
    var refresh:(()->Void)?

    var connectStatus:ConnectStatus = .normal {
        didSet {
            if connectStatus != oldValue{
                if let refresh = refresh{
                    refresh()
                }
            }
        }
    }
    init(title: String, hint: String, type: CellInfoType, detail: String? = nil) {
        self.title = title
        self.hint = hint
        self.type = type
        self.detail = detail
    }
}
class ConfigurationVC: UIViewController,UITableViewDelegate,UITableViewDataSource {
 
    lazy var tableView:TFTableView = {
        let width = self.view.bounds.width
        let height = self.view.bounds.height
        let table = TFTableView.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
        table.delegate = self
        table.dataSource = self
        if #available(iOS 15.0, *) {
            table.sectionHeaderTopPadding = 0
        }
        table.register(InputTableViewCell.self, forCellReuseIdentifier: "InputTableViewCell")
        table.tableHeaderView = chooseDeploymentTypeView()
        table.tableFooterView = footerView()
        table.rowHeight = 80
        table.separatorStyle = .none
        return table
    }()
    let disposeBag = DisposeBag()
    var dataSource = Array<CellInfo>()
    var dataKitArray = Array<CellInfo>()
    var dataWayArray = Array<CellInfo>()
    var isDataKit:Bool = UserDefaults.isDataKit {
        didSet {
            if isDataKit == true {
                dataSource = dataKitArray
            }else{
                dataSource = dataWayArray
            }
            self.tableView.reloadData()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("configuration", comment: "Configuration title")
        let copyItem = UIBarButtonItem.init(image: UIImage(systemName: "doc.on.clipboard"), style: .plain, target: self, action: #selector(copyConfigs))
        let saveItem = UIBarButtonItem.init(barButtonSystemItem: .save, target: self, action: #selector(saveConfigs))
        self.navigationItem.rightBarButtonItems = [saveItem,copyItem]
        view.backgroundColor = .navigationBackgroundColor
        self.createData()
    }
  
        
    func createData(){
        let rumItem = CellInfo(title: "RUM App ID", hint: "Please enter RUM App ID",type:.rum ,detail: UserDefaults.rumAppId)
        let demoApiItem = CellInfo(title: "Demo API Address", hint: "Please enter Demo API Address",type:.demoAPI ,detail: UserDefaults.baseUrl)
        let dataKitItem = CellInfo(title: "DataKit Address", hint: "Please enter DataKit Address",type:.dataKit, detail: UserDefaults.datakitURL)
        let dataWayItem = CellInfo(title: "DataWay Address", hint: "Please enter DataWay Address",type:.dataWay, detail: UserDefaults.dataWayURL)
        let clientTokenItem = CellInfo(title: "ClientToken", hint: "Please enter ClientToken",type:.clientToken, detail: UserDefaults.clientToken)
        dataKitArray = [rumItem,dataKitItem,demoApiItem]
        dataWayArray = [rumItem,dataWayItem,clientTokenItem,demoApiItem]
        isDataKit = UserDefaults.isDataKit
        self.view.addSubview(tableView)
    }

    func showAlert(){
        let alert = UIAlertController(title: NSLocalizedString("attention", comment: "Attention"), message: NSLocalizedString("sdk_config_restart_message", comment: "SDK configuration restart message"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: "Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("confirm", comment: "Confirm"), style: .default,handler: { action in
            UserDefaults.isDataKit = self.isDataKit
            for item in self.dataSource {
                switch item.type {
                case .rum:
                    UserDefaults.rumAppId = item.detail!
                case .dataKit:
                    UserDefaults.datakitURL = item.detail!
                case .dataWay:
                    UserDefaults.dataWayURL = item.detail!
                case .demoAPI:
                    UserDefaults.baseUrl = item.detail!
                case .clientToken:
                    UserDefaults.clientToken = item.detail!
                }
                FTLogInfo("\(item.type):\(item.detail!)")
            }
        })
        )
        self.navigationController?.present(alert, animated: true)
    }
    @objc func copyConfigs(){
        var toast:String = "";
        defer {
            self.view.makeToast(toast,position: .center)
        }
        let paste = UIPasteboard.general
        if let string = paste.string{
            do {
                let config = try string.parsePaste()
                if config.isDataKit() {
                    dataKitArray[0].detail = config.demoIOSAppId
                    dataKitArray[1].detail = config.datakitAddress
                    dataKitArray[2].detail = config.datawayAddress
                    self.isDataKit = true
                }else{
                    dataKitArray[0].detail = config.demoIOSAppId
                    dataKitArray[1].detail = config.datawayAddress
                    dataKitArray[2].detail = config.clientToken
                    dataKitArray[3].detail = config.datawayAddress
                    self.isDataKit = false
                }
                toast = "Data replication succeeds"
            }
            catch{
                toast = error.localizedDescription
            }
        }else{
            toast = PasteConfigurationError.noData.localizedDescription
        }
    }
    @objc func saveConfigs(){
        self.view.endEditing(true)
        for item in dataSource {
            if item.detail == nil || item.detail!.isEmpty {
                self.view.makeToast("Save failure:"+item.hint,position: .center)
                return
            }
        }
        showAlert()
    }
    @objc func confirmClick(){
        self.view.endEditing(true)
        Task {
            var connect:Array<(CellInfo,CellInfo?)> = Array.init()
            if self.isDataKit {
                connect = [(self.dataKitArray[1],nil),(self.dataKitArray[2],nil)]
            }else{
                connect = [(self.dataWayArray[1],self.dataWayArray[2]),(self.dataWayArray[3],nil)]
            }
            for (item,tokenItem) in connect {
                do{
                    _ = await self.connect(item: item,tokenItem: tokenItem)
                }
            }
        }
    }
    func connect(item:CellInfo,tokenItem:CellInfo?) async -> Bool {
        defer{
            let _ = MBProgressHUD.hide(for: self.view, animated: true)
        }
        let progressHud =  MBProgressHUD.init(view: self.view)
        self.view.addSubview(progressHud)
        progressHud.label.text = item.title+" connecting ..."
        progressHud.show(animated: true)
        do{
            switch item.type {
            case .dataKit:
                if item.connectStatus != .success {
                    let _ = try await NetworkEngine.shared.dataKitConnect(url: item.detail!)
                }
            case .dataWay:
                if item.connectStatus != .success || tokenItem?.connectStatus != .success {
                    let _ = try await NetworkEngine.shared.dataWayConnect(url: item.detail!, token: tokenItem!.detail!)
                }
            case .demoAPI:
                if item.connectStatus != .success {
                    let _ = try await NetworkEngine.shared.baseUrlConnect(url: item.detail!)
                }
            default:
                return true
            }
            item.connectStatus = .success
            tokenItem?.connectStatus = .success
            FTLogInfo("\(item.detail!) connected successful.")
            return true
        } catch {
            var errorMessage = item.title+" connected failure."
            if error is RequestError {
                errorMessage = errorMessage + error.localizedDescription
                let rError = error as! RequestError
                if rError.isTokenNotFound() {
                    item.connectStatus = .success
                    tokenItem?.connectStatus = .error
                }else{
                    item.connectStatus = .error
                }
            }else{
                item.connectStatus = .error
            }
            self.view.makeToast(errorMessage,position: .center)
            FTLogError("\(item.detail!) ")
            return false
        }
    }
 
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    func chooseDeploymentTypeView()->UIView{
        let view = UIView.init(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 50))
        let dataKitBtn = SelectButton.init(frame: CGRect(x: 10, y: 10, width: self.view.frame.width/2 - 20, height: 30))
        dataKitBtn.setTitle(NSLocalizedString("local_deployment_datakit", comment: "Local deployment Datakit method"), for: .normal)
        dataKitBtn.isSelected = self.isDataKit
        let dataWayBtn = SelectButton.init(frame: CGRect(x: self.view.frame.width/2 + 10, y: 10, width: self.view.frame.width/2 - 20, height: 30))
        dataWayBtn.setTitle(NSLocalizedString("use_public_dataway", comment: "Use public network DataWay"), for: .normal)
        dataWayBtn.isSelected = !self.isDataKit
        view.addSubview(dataKitBtn)
        view.addSubview(dataWayBtn)
        dataKitBtn.rx.tap
                   .subscribe(onNext: { [weak self]() in
                       dataKitBtn.isSelected = true
                       dataWayBtn.isSelected = false
                       self?.isDataKit = true
                   })
                   .disposed(by: disposeBag)

        dataWayBtn.rx.tap
            .subscribe(onNext: { [weak self]() in
                dataWayBtn.isSelected = true
                dataKitBtn.isSelected = false
                self?.isDataKit = false
            })
            .disposed(by: disposeBag)
        return view
    }
    func footerView()->UIView{
         let view = UIView.init(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 57))
         let logout = UIButton.init(frame: CGRect(x: 0, y: 12, width: self.view.bounds.size.width, height: 45))
         logout.setTitle(NSLocalizedString("address_check", comment: "Address check"), for: .normal)
         logout.setTitleColor(.orange, for: .normal)
         logout.addTarget(self, action: #selector(confirmClick), for: .touchUpInside)
         view.addSubview(logout)
         return view
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = InputTableViewCell(style: .default, reuseIdentifier: "mineTableViewCell")
        let cellInfo = self.dataSource[indexPath.row]
        
        cell.setInfo(info: cellInfo)
        
        cell.inputTextFieldChanged = { [weak self] string in
            self?.dataSource[indexPath.row].detail = string
        }
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
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
