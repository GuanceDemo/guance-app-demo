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
import FTMobileSDK
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
        let table = TFTableView.init(frame: CGRect(x: 0, y: 0, width: width, height: height),style: .insetGrouped)
        table.delegate = self
        table.dataSource = self
        if #available(iOS 15.0, *) {
            table.sectionHeaderTopPadding = 0
        }
        table.register(InputTableViewCell.self, forCellReuseIdentifier: "InputTableViewCell")
        table.separatorStyle = .singleLine
        table.backgroundColor = .secondarySystemBackground
        return table
    }()
    lazy var chooseSessionReplayView:UIView = {
        let backgroundView = UIView.init(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 60))
        let view = UIView.init(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width-40, height: 50))
        backgroundView.addSubview(view)
        view.backgroundColor = .white
        let label = UILabel.init(frame: CGRect(x: 10, y: 5, width: 250, height: 40))
        label.text = "Session Replay Privacy"
        label.font = .systemFont(ofSize: 15)
        view.addSubview(label)
        let switchBtn = UISwitch()
        switchBtn.isOn = self.enableSessionReplay
        view.addSubview(switchBtn)
        switchBtn.snp.makeConstraints { make in
            make.right.equalTo(view).offset(-20)
            make.centerY.equalTo(view)
        }
        view.layer.cornerRadius = 10
        switchBtn.rx.isOn.subscribe { [weak self] element in
            guard let self = self else {
                return
            }
            self.enableSessionReplay = switchBtn.isOn
        }.disposed(by: disposeBag)
        return backgroundView
    }()

    lazy var chooseDeploymentTypeView:UIView = {
        let contentView = UIView.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 60))
        let label = UILabel.init(frame: CGRect(x: 10, y: 5, width: 200, height: 20))
        label.font = .systemFont(ofSize: 12)
        label.text = NSLocalizedString("choose_deployment_type", comment: "Choose deployment type")
        contentView.addSubview(label)
        let segmentControl = UISegmentedControl(items: [NSLocalizedString("local_deployment_datakit", comment: "Local deployment"),NSLocalizedString("use_public_dataway", comment: "Use public dataway")])
        segmentControl.selectedSegmentIndex = self.isDataKit ? 0 : 1
        contentView.addSubview(segmentControl)
        segmentControl.snp.makeConstraints { (make)->Void in
            make.top.equalTo(label.snp_bottomMargin).offset(10)
            make.left.equalTo(contentView)
            make.right.equalTo(contentView)
            make.height.equalTo(30)
        }
        segmentControl.rx.selectedSegmentIndex.subscribe { [weak self] selectIndex in
            guard let self = self else{
                return
            }
            let isDataKit = selectIndex == 0 ? true : false
            if isDataKit != self.isDataKit {
                self.isDataKit = isDataKit
            }
        }.disposed(by: disposeBag)
        return contentView
    }()
    let disposeBag = DisposeBag()
    var dataSource:Array<Array<Any>> = [[],[]]
    var dataKitArray = Array<CellInfo>()
    var dataWayArray = Array<CellInfo>()
    var srPrivacy = UserDefaults.sessionReplayPrivacy
    var isDataKit:Bool = UserDefaults.isDataKit {
        didSet {
            if dataSource.count > 0{
                dataSource.remove(at: 0)
            }
            if isDataKit == true {
                dataSource.insert(dataKitArray, at: 0)
            }else{
                dataSource.insert(dataWayArray, at: 0)
            }
            self.tableView.reloadData()
        }
    }
    var enableSessionReplay:Bool = UserDefaults.enableSessionReplay {
        didSet {
            if enableSessionReplay != oldValue {
                self.resetPrivacyData()
            }
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
        resetPrivacyData()
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
    func resetPrivacyData(){
        if dataSource.count > 1{
            dataSource.remove(at: 1)
        }
        if enableSessionReplay {
            dataSource.insert(["Allow","MaskUserInput","Mask"], at: 1)
        }else{
            dataSource.insert([], at: 1)
        }
        self.tableView.reloadData()
    }
    func showAlert(){
        let alert = UIAlertController(title: NSLocalizedString("attention", comment: "Attention"), message: NSLocalizedString("sdk_config_restart_message", comment: "SDK configuration restart message"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: "Cancel"), style: .cancel))
                alert.addAction(UIAlertAction(title: NSLocalizedString("confirm", comment: "Confirm"), style: .default,handler: { action in
             UserDefaults.sessionReplayPrivacy = self.srPrivacy
                        UserDefaults.enableSessionReplay = self.enableSessionReplay
            UserDefaults.isDataKit = self.isDataKit
            let itemArray:Array<CellInfo> = self.dataSource[0] as! Array<CellInfo>
            for item in itemArray {
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
                if let demoIOSAppId = config.demoIOSAppId{
                    dataKitArray[0].detail = demoIOSAppId
                    dataWayArray[0].detail = demoIOSAppId
                }
                if let datakitAddress = config.datakitAddress{
                    dataKitArray[1].detail = datakitAddress
                }
                if let demoApiAddress = config.demoApiAddress{
                    dataKitArray[2].detail = demoApiAddress
                    dataWayArray[3].detail = demoApiAddress
                }
                if let datawayAddress = config.datawayAddress{
                    dataWayArray[1].detail = datawayAddress
                }
                if let clientToken = config.datawayClientToken {
                    dataWayArray[2].detail = clientToken
                }
                self.isDataKit = config.isDataKit()
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
        let itemArray:Array<CellInfo> = dataSource[0] as! Array<CellInfo>
        for item in itemArray {
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

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(indexPath.section == 0){
            if indexPath.row != dataSource[0].count {
                let cell = InputTableViewCell(style: .default, reuseIdentifier: "mineTableViewCell")
                let itemArray:Array<CellInfo> = dataSource[0] as! Array<CellInfo>
                let cellInfo = itemArray[indexPath.row]

                cell.setInfo(info: cellInfo)

                cell.inputTextFieldChanged = { [weak self] string in
                    guard let self = self else { return }
                    let itemArray:Array<CellInfo> = self.dataSource[0] as! Array<CellInfo>
                    itemArray[indexPath.row].detail = string
                }
                return cell
            }else{
                let cell = UITableViewCell(style: .default, reuseIdentifier: "defaultCell")
                cell.textLabel?.text = NSLocalizedString("url_check", comment: "URL check")
                cell.textLabel?.textColor = .theme
                cell.textLabel?.textAlignment = .center
                return cell
            }
        }else{
            let cell = UITableViewCell(style: .default, reuseIdentifier: "privacyCell")
            let array:Array<String> =  self.dataSource[1] as! Array<String>
            cell.textLabel?.text = array[indexPath.row]
            if indexPath.row == self.srPrivacy {
                cell.accessoryType = .checkmark
            }
            return cell
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return dataSource[section].count + 1
        }
        return dataSource[section].count
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 ,indexPath.row == dataSource[0].count{
            self.confirmClick()
        }else if indexPath.section == 1 {
            let oldIndexPath = IndexPath(row: self.srPrivacy, section: 1)
            let newCell = tableView.cellForRow(at: indexPath)
            if let cell = newCell {
                if (cell.accessoryType == .none) {
                    cell.accessoryType = .checkmark
                    self.srPrivacy = indexPath.row
                    let oldCell = tableView.cellForRow(at: oldIndexPath)
                    if let oldCell = oldCell {
                        oldCell.accessoryType = .none
                    }
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if(section == 0){
            return self.chooseDeploymentTypeView
        }else{
            return self.chooseSessionReplayView
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 65
        }
        return 60
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if indexPath.row != dataSource[0].count {
                return 70
            }
        }
        return 44
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
