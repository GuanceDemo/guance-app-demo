//
//  MineViewController.swift
//  FTSDKDemo
//
//  Created by hulilei on 2023/7/17.
//

import UIKit
import SDWebImage
import SnapKit
class MineViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    var dataSource = Array<(String,String)>()
    let refresh = UIRefreshControl()
    lazy var activity:UIActivityIndicatorView = {
        let activity = UIActivityIndicatorView.init(style: .large)
        activity.color = .gray
        activity.center = self.view.center
        self.view.addSubview(activity)
        return activity
    }()
    lazy var userInfoView:UserInfoView = {
        let view = UserInfoView.init(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 160))
        view.refreshDataClick = { [weak self] in
            self?.refreshData()
        }
        return view
    }()
    lazy var tableView:UITableView = {
        let width = self.view.bounds.width
        let height = self.view.bounds.height
        let table = UITableView.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
        table.delegate = self
        table.dataSource = self
        table.tableHeaderView = self.userInfoView
        table.tableFooterView = getTableFooterView()
        if #available(iOS 15.0, *) {
            table.sectionHeaderTopPadding = 0
        }
        table.register(UITableViewCell.self, forCellReuseIdentifier: "mineTableViewCell")
        table.rowHeight = 45
        return table
    }()
    var refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .navigationBackgroundColor
        // Do any additional setup after loading the view.
        createUI()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !self.tableView.visibleCells.isEmpty {
            self.dataSource[0] = (NSLocalizedString("edit_demo_configuration", comment: "Edit Demo configuration"),getConfiguration())
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if activity.isAnimating {
            activity.stopAnimating()
        }
    }
    func createUI(){
        view.addSubview(tableView)
        //Add refresh
        refreshControl.addTarget(self, action: #selector(refreshData),
                                 for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: NSLocalizedString("pull_down_refresh_data", comment: "Pull down to refresh data"))
        tableView.addSubview(refreshControl)
        let infoDictionary = Bundle.main.infoDictionary
        let majorVersion:String = infoDictionary?["CFBundleShortVersionString"] as! String//Main program version number
        let minorVersion:String = infoDictionary? ["CFBundleVersion"] as! String//Version number (internal identifier)
        let appVersion = "\(majorVersion)(\(minorVersion))"
        dataSource=[(NSLocalizedString("edit_demo_configuration", comment: "Edit Demo configuration"),getConfiguration()),(NSLocalizedString("version_number", comment: "Version number"),appVersion)]
    }
    func getConfiguration()->String{
        let type = (UserDefaults.isDataKit == true) ? "Datakit" : "Dataway"
        return "Type:\(type)"
    }
   @objc func refreshData() {
       Task(priority: .medium) {
           do {
               defer{
                   self.refreshControl.endRefreshing()
                   activity.stopAnimating()
               }
               if !refreshControl.isRefreshing {
                   activity.startAnimating()
               }
               let success = try await UserManager.shared().loadUserInfo()
               if success {
                   self.tableView.reloadData()
                   self.userInfoView.updateUserInfo()
               }
           } catch {
               self.view.makeToast(error.localizedDescription,position: .center)
           }
       }
    }

    func getTableFooterView()->UIView{
       let view = UIView.init(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 57))
        let logout = UIButton.init(frame: CGRect(x: 0, y: 12, width: self.view.bounds.size.width, height: 45))
        logout.setTitle(NSLocalizedString("logout", comment: "Logout"), for: .normal)
        logout.setTitleColor(.theme, for: .normal)
        logout.addTarget(self, action: #selector(userLogout), for: .touchUpInside)
        view.addSubview(logout)
        return view
    }
    
    @objc func userLogout(){
        UserManager.shared().logout()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "mineTableViewCell")
        cell.textLabel?.text = dataSource[indexPath.row].0
        cell.detailTextLabel?.text = dataSource[indexPath.row].1
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            self.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(ConfigurationVC(), animated: true)
            self.hidesBottomBarWhenPushed = false
        default:
            print("click")
        }
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
