//
//  FriendViewController.swift
//  DeepTransitionSample
//
//  Created by 森下 健 on 2014/12/20.
//  Copyright (c) 2014年 Yumemi. All rights reserved.
//

import UIKit

class FriendViewController: MyTransitionViewController {

    @IBAction func onBtnFrientList(sender: AnyObject) {
        transition.to("..")
    }

    @IBAction func onBtnHelp(sender: AnyObject) {
        transition.to("^/top/home#profile/help")
    }
}
