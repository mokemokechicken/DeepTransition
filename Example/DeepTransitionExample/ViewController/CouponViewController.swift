//
//  CouponViewController.swift
//  DeepTransitionSample
//
//  Created by 森下 健 on 2014/12/13.
//  Copyright (c) 2014年 Yumemi. All rights reserved.
//

import UIKit

class CouponViewController: MyTransitionViewController {
    @IBOutlet weak var labelID: UILabel!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let params = transitionAgent?.params {
            labelID.text = params["id"]
        }
    }
    
    @IBAction func onBtnNews2(sender: AnyObject) {
        transition.to("^/top/list_news/show_news(id=55)")
    }

    @IBAction func onBtnUp(sender: AnyObject) {
        transition.up()
    }
}
