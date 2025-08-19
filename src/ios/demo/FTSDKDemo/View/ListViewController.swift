//
//  ListViewController.swift
//  FTSDKDemo
//
//  Created by hulilei on 2023/7/18.
//

import UIKit

class ListViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    var dataSource = Array<(String,String,String)>()
    lazy var tableView:UITableView = {
        let width = self.view.bounds.width
        let height = self.view.bounds.height
        let table = UITableView.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "listTableViewCell")
        table.separatorStyle = .singleLine
        table.rowHeight = 60
        return table
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        createUI()
        self.view.backgroundColor = .navigationBackgroundColor
        // Do any additional setup after loading the view.
    }
    func createUI(){
        view.addSubview(tableView)
        dataSource = [("Native View",NSLocalizedString("ios_native_interface", comment: "iOS native interface"),"ic_ios"),("Webview",NSLocalizedString("ios_webview_interface", comment: ""),"ic_web")]
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "listTableViewCell")
        cell.textLabel?.text = dataSource[indexPath.row].0
        cell.textLabel?.font = .systemFont(ofSize: 18)
        cell.detailTextLabel?.text = dataSource[indexPath.row].1
        cell.detailTextLabel?.font = .systemFont(ofSize: 14)
        cell.imageView?.image = UIImage(named: dataSource[indexPath.row].2)
        cell.imageView?.contentMode = .scaleAspectFit
        let itemSize = CGSize(width: 40, height: 40)
        UIGraphicsBeginImageContextWithOptions(itemSize, false, UIScreen.main.scale)
        let imageRect = CGRect(x: 0, y: 0, width: itemSize.width, height: itemSize.height)
        cell.imageView?.image?.draw(in: imageRect)
        cell.imageView?.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row{
        case 1:
            self.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(WebViewController(), animated: true)
            self.hidesBottomBarWhenPushed = false
        case 0:
            self.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(NativeViewController(), animated: true)
            self.hidesBottomBarWhenPushed = false
        default:
            print("default")
        }
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.tableView.reloadData()
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
