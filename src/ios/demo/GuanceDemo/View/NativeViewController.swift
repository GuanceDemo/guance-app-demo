//
//  NativeViewController.swift
//  GuanceDemo
//
//  Created by hulilei on 2023/7/21.
//

import UIKit

class NativeViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    var dataSource = Array<String>()
    lazy var tableView:UITableView = {
        let width = self.view.bounds.width
        let height = self.view.bounds.height
        let top = self.navigationController?.navigationBar.frame.maxY ?? 0
        let table = UITableView.init(frame: CGRect(x: 0, y: top, width: width, height: height-top))
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "NativeTableViewCell")
        table.rowHeight = 45
        return table
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "native"
        // Do any additional setup after loading the view.
        createUI()
    }
    func createUI(){
        view.addSubview(tableView)
        dataSource = ["LongTask","Crash"]
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "NativeTableViewCell")
        cell.textLabel?.text = dataSource[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row{
        case 0:
            self.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(LongTaskViewController(), animated: true)
        case 1:
            self.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(CrashViewController(), animated: true)
        default:
            print("default")
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
