//
//  FriendListViewController.swift
//  DeepTransitionSample
//
//  Created by 森下 健 on 2014/12/20.
//  Copyright (c) 2014年 Yumemi. All rights reserved.
//

import UIKit

class FriendListViewController: MyTransitionViewController, UINavigationControllerDelegate {
    let controllerName = "friend"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.delegate = self
    }
    
    func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
        viewController.viewDidShow()
    }

    @IBAction func onBtnFriend(sender: AnyObject) {
        transition.to("show_friend")
    }

    
    @IBAction func onBtnHelp(sender: AnyObject) {
        transition.to("!help")
    }
}
