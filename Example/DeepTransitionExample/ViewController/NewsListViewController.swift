//
//  NewsListViewController.swift
//  DeepTransitionSample
//
//  Created by 森下 健 on 2014/12/13.
//  Copyright (c) 2014年 Yumemi. All rights reserved.
//

import UIKit

class NewsListViewController: MyTransitionViewController {
    @IBAction func onBtnNews1(sender: AnyObject) {
        transition.to("show_news(id=44)")
    }

    @IBAction func onBtnNews2(sender: AnyObject) {
        transition.to("!show_news(id=44)")
    }

}
