//
//  AppDelegate.swift
//  DeepTransitionExample
//
//  Created by 森下 健 on 2014/12/25.
//  Copyright (c) 2014年 Yumemi. All rights reserved.
//

import UIKit
import DeepTransition

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        TransitionServiceLocater.transitionCenter.debugMode = true
        RootTransitionAgent.create().forever().start("^/top")
        return true
    }

    func applicationWillResignActive(application: UIApplication) {}
    func applicationDidEnterBackground(application: UIApplication) {}
    func applicationWillEnterForeground(application: UIApplication) {}
    func applicationDidBecomeActive(application: UIApplication) {}
    func applicationWillTerminate(application: UIApplication) {}
}

