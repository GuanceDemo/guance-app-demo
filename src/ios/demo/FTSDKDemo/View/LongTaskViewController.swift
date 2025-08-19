//
//  LongTaskViewController.swift
//  FTSDKDemo
//
//  Created by hulilei on 2023/7/20.
//

import UIKit

class LongTaskViewController: UIViewController ,UITableViewDataSource,UITableViewDelegate{
    var dataSource = Array<String>()

    lazy var tableView:UITableView = {
        let width = self.view.bounds.width
        let height = self.view.bounds.height
        let table = UITableView.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "longtaskTableViewCell")
        table.rowHeight = 45
        return table
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .navigationBackgroundColor
        title = "longtask"
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.addSubview(tableView)
    }
   
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "longtaskTableViewCell")
        if indexPath.row % 10 == 0 {
            usleep(1 * 1000 * 1000); // 1 second
            cell.textLabel?.text = NSLocalizedString("lag_text", comment: "Lag text")
        }else{
            cell.textLabel?.text = String(indexPath.row)
        }
        return cell
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
