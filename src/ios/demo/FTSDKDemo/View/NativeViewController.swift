//
//  NativeViewController.swift
//  FTSDKDemo
//
//  Created by hulilei on 2023/7/21.
//

import UIKit
import FTMobileSDK

class NativeViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    var dataSource = Array<String>()
    lazy var activity:UIActivityIndicatorView = {
        let activity = UIActivityIndicatorView.init(style: .large)
        activity.color = .gray
        activity.center = self.view.center
        self.view.addSubview(activity)
        return activity
    }()

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
        dataSource = ["LongTask","Crash","Session Replay",NSLocalizedString("tag_dynamic_setting", comment: "Tag dynamic setting"),"Create Otel Span"]
    }

    func dynamicTag(){
        FTMobileAgent.appendGlobalContext(["global_key": "global_value"])
        FTMobileAgent.appendRUMGlobalContext(["rum_key": "rum_value"])
        FTMobileAgent.appendLogGlobalContext(["log_key": "log_value"])
    }

    func createOtelSpan(){
        Task(priority: .medium) {
            do {
                defer{
                    activity.stopAnimating()
                }
                if !activity.isAnimating {
                    activity.startAnimating()
                }
                let (response,_) = try await NetworkEngine.shared.userInfoWithOtel()
                if let traceID = response?.allHeaderFields["trace_id"] as? String, let spanID = response?.allHeaderFields["span_id"] as? String {

                    if  let biggerTraceID = UInt64(traceID)?.convert64To128Bit(),let biggerSpanID = UInt64(spanID)?.convertHex(){
                       _ = createSpanWithOtel(traceId: biggerTraceID,parentSpanId: biggerSpanID ,actionName: "add.action.after_request")
                    }
                }
            } catch {
                self.view.makeToast(error.localizedDescription,position: .center)
            }
        }
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
        case 2:
            self.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(SessionReplayViewController(), animated: true)
        case 3:
            dynamicTag()
        case 4:
            createOtelSpan()
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

extension UInt64{

    func convert64To128Bit()->String{
        let hex = String(self, radix: 16).uppercased() // Manually convert to hexadecimal
        let paddedHex = hex.padding(toLength: 16, withPad: "0", startingAt: 0) // Pad to 16 digits
        return "0000000000000000" + paddedHex
    }

    func convertHex()->String{
        let hexString = String(self, radix: 16).uppercased() // Manually convert to hexadecimal
        return hexString.padding(toLength: 16, withPad: "0", startingAt: 0)
    }
}

