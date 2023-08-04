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
        listVC.tabBarItem.title = listVC.title
        listVC.tabBarItem.image = UIImage(systemName: "flag")
        let navi = UINavigationController.init(rootViewController: listVC)
        navi.navigationBar.tintColor = .orange
        listVC.view.backgroundColor = .navigationBackgroundColor

        self.addChild(navi)
        
        let mineVC = MineViewController.init()
        mineVC.title = "我的"
        mineVC.tabBarItem.title = mineVC.title
        mineVC.tabBarItem.image = UIImage(systemName: "person.crop.circle.fill")
        let naviMine = UINavigationController.init(rootViewController: mineVC)
        naviMine.navigationBar.tintColor = .orange
        mineVC.view.backgroundColor = .navigationBackgroundColor
        self.addChild(naviMine)

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
