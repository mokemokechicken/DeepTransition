//
//  ProfileViewController.swift
//  DeepTransitionSample
//
//  Created by 森下 健 on 2014/12/20.
//  Copyright (c) 2014年 Yumemi. All rights reserved.
//

import UIKit

class ProfileViewController: MyTransitionViewController {
    let controllerName = "profile"
    @IBOutlet weak var label: UILabel!

    @IBAction func onBtnHelp(sender: AnyObject) {
        transition.to("help")
    }

    @IBAction func onBtnChangeParams(sender: AnyObject) {
        transition.changeParams(["time": NSDate().description ])
    }
    
    func onChangeParams(params: [String : String]) {
        if let time = params["time"] {
            label.text = "profile: (\(time))"
        }
    }
}
