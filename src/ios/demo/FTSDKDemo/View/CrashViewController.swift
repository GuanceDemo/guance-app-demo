//
//  CrashViewController.swift
//  FTSDKDemo
//
//  Created by hulilei on 2024/1/12.
//

import UIKit
struct CrashData {
    let  title:String
    let  crashBlock:() -> Void
    
    func crash(){
        crashBlock()
    }
}
class CrashViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    var dataSource = Array<CrashData>()
    lazy var tableView:UITableView = {
        let width = self.view.bounds.width
        let height = self.view.bounds.height
        let top = self.navigationController?.navigationBar.frame.maxY ?? 0
        let table = UITableView.init(frame: CGRect(x: 0, y: top, width: width, height: height-top))
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "CrashTableViewCell")
        table.rowHeight = 45
        return table
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        createUI()
        // Do any additional setup after loading the view.
    }
    func createUI(){
        view.addSubview(tableView)
        let crasher = Crasher()
        dataSource = [CrashData(title:"throwUncaughtNSException",
                                crashBlock: {
            crasher.throwUncaughtNSException()
        }),
                      CrashData(title:"dereferenceBadPointer",
                                crashBlock: {
            crasher.dereferenceBadPointer()
        }),
                      CrashData(title:"dereferenceNullPointer",
                                crashBlock: {
            crasher.dereferenceNullPointer()
        }),
                      CrashData(title:"useCorruptObject",
                                crashBlock: {
            crasher.useCorruptObject()
        }),
                      CrashData(title:"spinRunloop",
                                crashBlock: {
            crasher.spinRunloop()
        }),
                      CrashData(title:"causeStackOverflow",
                                crashBlock: {
            crasher.causeStackOverflow()
        }),
                      CrashData(title:"doAbort",
                                crashBlock: {
            crasher.doAbort()
        }),  
                      CrashData(title: "accessDeallocatedObject", crashBlock: {
            crasher.accessDeallocatedObject()
        }),
                      CrashData(title: "accessDeallocatedPtrProxy", crashBlock: {
            crasher.accessDeallocatedPtrProxy()
        }),
                      CrashData(title:"zombieNSException",
                                crashBlock:{
            crasher.zombieNSException()
        }),
                      CrashData(title:"corruptMemory",
                                crashBlock:{
            crasher.zombieNSException()
        }),
                      CrashData(title:"pthreadAPICrash",
                                crashBlock: {
            crasher.pthreadAPICrash()
        }),
                      CrashData(title:"throwUncaughtCPPException",
                                crashBlock: {
            crasher.throwUncaughtCPPException()
        }),
                      CrashData(title: "swift_unwrappingOptional",
                                crashBlock: {
            let dict:[String:Any] = ["key1":"value1","key2":"value2"]
            let key = dict["key"] as! String
            print("key:\(key)")
        }),
                      CrashData(title:"anrError",
                                crashBlock: {
            crasher.anrError()
        }),
        ]
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "CrashTableViewCell")
        cell.textLabel?.text = dataSource[indexPath.row].title
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let crash =  dataSource[indexPath.row]
        crash.crash()
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
