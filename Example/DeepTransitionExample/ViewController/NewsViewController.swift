//
//  NewsViewController.swift
//  DeepTransitionSample
//
//  Created by 森下 健 on 2014/12/13.
//  Copyright (c) 2014年 Yumemi. All rights reserved.
//

import UIKit

class NewsViewController: MyTransitionViewController {
    @IBOutlet weak var label: UILabel!
    @IBAction func onBtnCoupon2(sender: AnyObject) {
        transition.to("^/top!/list_coupon/show_coupon(id=88)")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        label.text = transitionAgent?.params?["id"]
    }
}
