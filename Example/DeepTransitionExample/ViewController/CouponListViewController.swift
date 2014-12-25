//
//  CouponListViewController.swift
//  DeepTransitionSample
//
//  Created by 森下 健 on 2014/12/13.
//  Copyright (c) 2014年 Yumemi. All rights reserved.
//

import UIKit

class CouponListViewController: MyTransitionViewController {
    @IBAction func onBtnCoupon2(sender: AnyObject) {
        transition.to("show_coupon(id=99)")
    }

    @IBAction func onBtnNews2(sender: AnyObject) {
        transition.to("show_news(id=99)")
    }

    @IBAction func onBtnUp(sender: AnyObject) {
        transition.up()
    }
}
