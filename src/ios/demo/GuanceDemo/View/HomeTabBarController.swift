//
//  HomeTabBarController.swift
//  GuanceDemo
//
//  Created by hulilei on 2023/7/18.
//

import UIKit

class HomeTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.tintColor = .orange
        setUpAllChildViewController()
        // Do any additional setup after loading the view.
    }
    func setUpAllChildViewController(){
        let listVC = ListViewController.init()
        listVC.title = "首页"
        let navi = UINavigationController.init(rootViewController: listVC)
        navi.navigationBar.tintColor = .orange
        self.addChild(navi)
        self.tabBar.items?.first?.title = listVC.title
        self.tabBar.items?.first?.image = UIImage(systemName: "flag")

        let mineVC = MineViewController.init()
        mineVC.title = "我的"
        let naviMine = UINavigationController.init(rootViewController: mineVC)
        naviMine.navigationBar.tintColor = .orange
        self.addChild(naviMine)
        self.tabBar.items?.last?.title = "我的"
        self.tabBar.items?.last?.image = UIImage(systemName: "person.crop.circle.fill")

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
