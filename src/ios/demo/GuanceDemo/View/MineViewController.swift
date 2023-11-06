//
//  MineViewController.swift
//  GuanceDemo
//
//  Created by hulilei on 2023/7/17.
//

import UIKit
import SDWebImage
import SnapKit
class MineViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    var dataSource = Array<(String,String)>()
    let refresh = UIRefreshControl()
    lazy var tableView:UITableView = {
        let width = self.view.bounds.width
        let height = self.view.bounds.height
        let table = UITableView.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
        table.delegate = self
        table.dataSource = self
        table.tableHeaderView = getTableHeaderView()
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
        // Do any additional setup after loading the view.
        createUI()
    }
    
    func createUI(){
        view.addSubview(tableView)
        //添加刷新
        refreshControl.addTarget(self, action: #selector(refreshData),
                                 for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "下拉刷新数据")
        tableView.addSubview(refreshControl)
        let infoDictionary = Bundle.main.infoDictionary
        let majorVersion:String = infoDictionary?["CFBundleShortVersionString"] as! String//主程序版本号
        let minorVersion:String = infoDictionary? ["CFBundleVersion"] as! String//版本号（内部标示）
        let appVersion = "\(majorVersion)(\(minorVersion))"
        dataSource=[("编辑 Demo 配置",""),("版本号",appVersion)]
    }
   @objc func refreshData() {
       Task(priority: .medium) {
           do {
               let success = try await UserManager.shared().loadUserInfo()
               if success {
                   self.tableView.reloadData()
               }
               self.refreshControl.endRefreshing()
           } catch {
               self.refreshControl.endRefreshing()
           }
       }
    }
    
    func getTableHeaderView()->UIView{
        let view = UIView.init(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 160))
        view.backgroundColor = .lightGray
        let backgroundImg = UIImageView(image: UIImage(named: "ft_setting_avatar_bg"))
        backgroundImg.frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 160)
        backgroundImg.contentMode = .scaleAspectFill
        view.addSubview(backgroundImg)
        let avatar = UIImageView.init()
        view.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.centerY.equalTo(view)
            make.left.equalTo(view).offset(15)
            make.size.equalTo(CGSize(width: 60, height: 60))
        }
        avatar.layer.cornerRadius = 30
        avatar.layer.masksToBounds = true
        
        let nameLab = UILabel.init()
        nameLab.font = UIFont.systemFont(ofSize: 14)
        nameLab.textColor = .black
        view.addSubview(nameLab)
        nameLab.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp_rightMargin).offset(15)
            make.top.equalTo(avatar.snp_topMargin)
            make.size.equalTo(CGSize(width: 200, height: 20))
        }
        let emailLab = UILabel.init()
        emailLab.font = UIFont.systemFont(ofSize: 12)
        emailLab.textColor = .gray
        view.addSubview(emailLab)
        emailLab.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp_rightMargin).offset(15)
            make.bottom.equalTo(avatar.snp_bottomMargin)
            make.size.equalTo(CGSize(width: 200, height: 20))
        }
        if let userInfo = UserManager.shared().userInfo {
            avatar.sd_setImage(with: URL(string: userInfo.avatar))
            nameLab.text = userInfo.username
            emailLab.text = userInfo.email
        }
        return view
    }
    func getTableFooterView()->UIView{
       let view = UIView.init(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 57))
        let logout = UIButton.init(frame: CGRect(x: 0, y: 12, width: self.view.bounds.size.width, height: 45))
        logout.setTitle("退出登录", for: .normal)
        logout.setTitleColor(.orange, for: .normal)
        logout.addTarget(self, action: #selector(userLogout), for: .touchUpInside)
        view.addSubview(logout)
        return view
    }
    
    @objc func userLogout(){
        UserManager.shared().logout()
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView.init()
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 5
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 57
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
